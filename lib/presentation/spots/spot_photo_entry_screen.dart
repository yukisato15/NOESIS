import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/maps/spot_geocoding_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/spot_photo_service.dart';
import '../../data/local/database.dart';

import 'spot_detail_screen.dart';

/// 写真から緯度経度・撮影日時を取得してスポットを素早く登録する画面。
class SpotPhotoEntryScreen extends StatefulWidget {
  const SpotPhotoEntryScreen({super.key});

  @override
  State<SpotPhotoEntryScreen> createState() => _SpotPhotoEntryScreenState();
}

class _SpotPhotoEntryScreenState extends State<SpotPhotoEntryScreen> {
  final AppDatabase _db = AppDatabase();
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _memoController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String? _photoPath;
  DateTime? _capturedAt;
  String? _resolvedAddress;   // リバースジオコーディングで取得した住所
  String? _resolvedPlaceName; // Nominatim が返した施設名
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _db.close();
    _nameController.dispose();
    _memoController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ── 写真を選択して EXIF を読む ───────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    // EXIFは一時ファイルから先に読む（保存後は消えることがある）
    setState(() {
      _statusMessage = 'EXIF情報を読み込み中...';
      _isProcessing = true;
    });

    final exif = await _extractExif(picked.path);

    // アプリ内ドキュメントに圧縮コピー（一時ファイルは iOS が削除するため）
    final savedPath = await SpotPhotoService.savePhoto(
      sourceImagePath: picked.path,
      prefix: 'spot',
    );
    setState(() => _photoPath = savedPath);

    if (exif.lat != null) {
      setState(() => _statusMessage = '📍 GPS取得 → 場所を逆引き中...');

      // リバースジオコーディング（座標→住所・施設名）
      final reversed = await _reverseGeocode(exif.lat!, exif.lng!);
      _resolvedAddress = reversed.address;
      _resolvedPlaceName = reversed.placeName;

      // 施設名が取れた場合は名前フィールドに自動入力
      if ((_resolvedPlaceName ?? '').isNotEmpty &&
          _nameController.text.trim().isEmpty) {
        _nameController.text = _resolvedPlaceName!;
      }
    }

    setState(() {
      if (exif.lat != null) _latController.text = exif.lat!.toStringAsFixed(6);
      if (exif.lng != null) _lngController.text = exif.lng!.toStringAsFixed(6);
      _capturedAt = exif.capturedAt;

      if (exif.lat != null) {
        final placePart = (_resolvedPlaceName ?? '').isNotEmpty
            ? '「$_resolvedPlaceName」'
            : '';
        final addrPart = (_resolvedAddress ?? '').isNotEmpty
            ? '\n📮 $_resolvedAddress'
            : '';
        _statusMessage = '📍 GPS情報を取得しました$placePart$addrPart';
      } else {
        _statusMessage = 'GPS情報が写真に含まれていません。手動で入力できます。';
      }
      _isProcessing = false;
    });
  }

  /// Nominatim リバースジオコーディング（座標→住所・施設名）
  Future<({String? address, String? placeName})> _reverseGeocode(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'accept-language': 'ja',
        'zoom': '18', // 建物レベルの詳細度
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'NoesisApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return (address: null, placeName: null);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>? ?? {};

      // 施設名の候補: amenity（カフェ等）→ shop → tourism → leisure → 建物名
      final placeName =
          _str(addr['amenity']) ??
          _str(addr['shop']) ??
          _str(addr['tourism']) ??
          _str(addr['leisure']) ??
          _str(addr['building']) ??
          _str(data['name']);

      // 住所文字列を組み立て
      final parts = [
        _str(addr['postcode']),
        _str(addr['province']) ?? _str(addr['state']),
        _str(addr['city']) ?? _str(addr['town']) ?? _str(addr['village']),
        _str(addr['suburb']) ?? _str(addr['neighbourhood']),
        _str(addr['road']),
        _str(addr['house_number']),
      ].whereType<String>().toList();

      return (
        address: parts.isNotEmpty ? parts.join('') : _str(data['display_name']),
        placeName: placeName,
      );
    } catch (_) {
      return (address: null, placeName: null);
    }
  }

  Future<({double? lat, double? lng, DateTime? capturedAt})> _extractExif(
    String path,
  ) async {
    try {
      final bytes = await File(path).readAsBytes();
      final data = await readExifFromBytes(bytes);

      double? lat = _dmsToDecimal(
        data['GPS GPSLatitude'],
        data['GPS GPSLatitudeRef']?.printable == 'S',
      );
      double? lng = _dmsToDecimal(
        data['GPS GPSLongitude'],
        data['GPS GPSLongitudeRef']?.printable == 'W',
      );

      DateTime? capturedAt;
      final dateStr =
          data['EXIF DateTimeOriginal']?.printable ??
          data['Image DateTime']?.printable;
      if (dateStr != null) {
        capturedAt = _parseExifDateTime(dateStr);
      }

      return (lat: lat, lng: lng, capturedAt: capturedAt);
    } catch (_) {
      return (lat: null, lng: null, capturedAt: null);
    }
  }

  double? _dmsToDecimal(IfdTag? tag, bool negative) {
    if (tag == null) return null;
    try {
      // values は [度, 分, 秒] の Ratio リスト
      final vals = tag.values.toList();
      if (vals.length < 3) return null;
      double deg = _ratioToDouble(vals[0]);
      double min = _ratioToDouble(vals[1]);
      double sec = _ratioToDouble(vals[2]);
      double result = deg + min / 60.0 + sec / 3600.0;
      return negative ? -result : result;
    } catch (_) {
      return null;
    }
  }

  double _ratioToDouble(dynamic val) {
    // IfdRatio は numerator/denominator を持つ
    final str = val.toString();
    if (str.contains('/')) {
      final parts = str.split('/');
      final n = double.tryParse(parts[0]) ?? 0;
      final d = double.tryParse(parts[1]) ?? 1;
      return d == 0 ? 0 : n / d;
    }
    return double.tryParse(str) ?? 0;
  }

  DateTime? _parseExifDateTime(String raw) {
    // フォーマット: "2024:07:15 14:30:00"
    try {
      final cleaned = raw.replaceRange(4, 5, '-').replaceRange(7, 8, '-');
      return DateTime.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// 手動入力した座標から場所名・住所を逆引きしてフォームに反映する。
  Future<void> _lookupPlaceFromCoords() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = '座標から場所を逆引き中...';
    });

    final reversed = await _reverseGeocode(lat, lng);
    _resolvedAddress = reversed.address;
    _resolvedPlaceName = reversed.placeName;

    setState(() {
      if ((_resolvedPlaceName ?? '').isNotEmpty &&
          _nameController.text.trim().isEmpty) {
        _nameController.text = _resolvedPlaceName!;
      }
      final addrPart = (_resolvedAddress ?? '').isNotEmpty
          ? '\n📮 $_resolvedAddress'
          : '';
      final namePart = (_resolvedPlaceName ?? '').isNotEmpty
          ? '「$_resolvedPlaceName」'
          : '';
      _statusMessage = addrPart.isNotEmpty || namePart.isNotEmpty
          ? '📍 $namePart$addrPart'
          : '施設情報が見つかりませんでした。名前を手入力してください。';
      _isProcessing = false;
    });
  }

  // ── AI で情報を自動記入してスポットを登録 ─────────────────

  Future<void> _registerWithAI() async {
    final name = _nameController.text.trim();
    final memo = _memoController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (_photoPath == null) {
      _showSnack('写真を選択してください');
      return;
    }
    if (name.isEmpty && memo.isEmpty) {
      _showSnack('場所の名前かメモを入力してください');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'AIで情報を整理中...';
    });

    try {
      // 1. AIで基本情報を生成
      final locationHint = [
        if ((_resolvedPlaceName ?? '').isNotEmpty)
          '地図上の施設名: $_resolvedPlaceName',
        if ((_resolvedAddress ?? '').isNotEmpty)
          '住所（地図逆引き）: $_resolvedAddress',
      ].join('\n');

      final spotNameHint = name.isNotEmpty
          ? '「$name」'
          : (_resolvedPlaceName ?? '').isNotEmpty
          ? '「$_resolvedPlaceName」（地図逆引き）'
          : '不明な場所';

      final prompt = '''
あなたはスポット記録AIです。
ユーザーが $spotNameHint を訪問しました。
${memo.isNotEmpty ? 'メモ: $memo' : ''}
${_capturedAt != null ? '訪問日時: ${DateFormat('yyyy年M月d日 HH:mm').format(_capturedAt!)}' : ''}
${locationHint.isNotEmpty ? '\n$locationHint' : ''}

以下の情報をJSONで返してください。根拠のない情報は空欄にしてください。
名前が不明な場合は「思い出の場所」など適切なものをつけてください。
''';

      Map<String, dynamic> aiResult = {};
      if (AIClient.isConfigured) {
        // Web検索: 名前 or 施設名があれば検索して精度を上げる
        final searchTarget = name.isNotEmpty
            ? name
            : _resolvedPlaceName ?? '';
        if (searchTarget.isNotEmpty && SearchClient.canUseWebSearch) {
          setState(() => _statusMessage = 'Webで情報を検索中...');
          final addressHint = (_resolvedAddress ?? '').isNotEmpty
              ? ' $_resolvedAddress'
              : '';
          final results = await SearchClient.instance.search(
            '$searchTarget$addressHint',
            maxResults: 5,
          );
          final searchContext = results.isNotEmpty
              ? SearchClient.instance.formatSearchResults(results)
              : '';
          aiResult = await AIClient.instance.generateStructured(
            prompt: '$prompt\n\nWeb検索結果:\n$searchContext',
            jsonSchema: _spotSchema(),
            mode: AIMode.standard,
          );
        } else {
          aiResult = await AIClient.instance.generateStructured(
            prompt: prompt,
            jsonSchema: _spotSchema(),
            mode: AIMode.standard,
          );
        }
      }

      // 2. 座標の解決（EXIFから取得できていれば優先、なければジオコーディング）
      setState(() => _statusMessage = '地図情報を取得中...');
      double? finalLat = lat;
      double? finalLng = lng;
      String? mapUrl;
      String? geocodeSource;

      if (finalLat == null && name.isNotEmpty) {
        final resolved = await SpotGeocodingService.resolve(
          name: name,
          area: _str(aiResult['area']),
          address: _str(aiResult['address']),
        );
        finalLat = resolved.latitude;
        finalLng = resolved.longitude;
        mapUrl = resolved.mapUrl;
        geocodeSource = resolved.geocodeSource;
      } else if (finalLat != null) {
        // EXIFから座標が取れた場合はGoogle Maps検索URLを構築
        mapUrl = 'https://www.google.com/maps/search/?api=1&query=$finalLat,$finalLng';
        geocodeSource = 'exif';
      }

      // 3. DBに保存
      setState(() => _statusMessage = '保存中...');
      final now = DateTime.now();
      final visitedAt = _capturedAt ?? now;
      // 名前: 入力 → AI → 地図逆引き施設名 → デフォルト の優先順位
      final spotName =
          name.isNotEmpty
              ? name
              : _str(aiResult['name']) ??
                  _resolvedPlaceName ??
                  '記録された場所';
      // 住所: AI → 地図逆引き の優先順位
      final finalAddress =
          _str(aiResult['address']) ?? _resolvedAddress;

      final spotId = await _db.spotsDao.insertSpot(
        SpotsCompanion.insert(
          name: spotName,
          genre: drift.Value(_str(aiResult['genre'])),
          area: drift.Value(_str(aiResult['area'])),
          address: drift.Value(finalAddress),
          summary: drift.Value(_str(aiResult['summary'])),
          mapUrl: drift.Value(mapUrl),
          latitude: drift.Value(finalLat),
          longitude: drift.Value(finalLng),
          geocodeSource: drift.Value(geocodeSource),
          photoPath: drift.Value(_photoPath),
          tags: drift.Value(_str(aiResult['tags'])),
          isMapVisible: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      // 訪問記録も同時に追加
      await _db.spotsDao.insertVisit(
        SpotVisitsCompanion.insert(
          spotId: spotId,
          visitedAt: visitedAt,
          impression: drift.Value(_str(aiResult['impression']) ?? (memo.isNotEmpty ? memo : null)),
          photoPath: drift.Value(_photoPath),
          createdAt: drift.Value(now),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SpotDetailScreen(spotId: spotId),
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'エラーが発生しました: $e';
      });
    }
  }

  Map<String, dynamic> _spotSchema() => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': '場所の名前（ユーザー入力がある場合はそれを使用）'},
      'genre': {'type': 'string', 'description': 'カフェ・レストラン・公園など'},
      'area': {'type': 'string', 'description': '地域・エリア名'},
      'address': {'type': 'string', 'description': '住所'},
      'summary': {'type': 'string', 'description': '場所の概要・特徴'},
      'impression': {'type': 'string', 'description': 'ユーザーの感想'},
      'tags': {'type': 'string', 'description': 'タグ（JSON配列形式: ["タグ1","タグ2"]）'},
    },
  };

  String? _str(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('写真でスポット登録')),
      body: _isProcessing
          ? _buildProcessingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // ── 写真選択 ──
                _buildPhotoSection(theme),
                const SizedBox(height: 20),

                // ── EXIF 情報表示 ──
                if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppPalette.backgroundWarm,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusMessage, style: theme.textTheme.bodySmall),
                  ),

                if (_capturedAt != null)
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: '撮影日時',
                    value: DateFormat('yyyy年M月d日 HH:mm').format(_capturedAt!),
                  ),

                // ── GPS ──
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _latController,
                        label: '緯度',
                        icon: Icons.my_location_outlined,
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildField(
                        controller: _lngController,
                        label: '経度',
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 「座標から場所名を調べる」ボタン（GPS入力済みのとき表示）──
                if (double.tryParse(_latController.text) != null) ...[
                  OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _lookupPlaceFromCoords,
                    icon: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('この座標の場所を調べる'),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── 場所名（任意）──
                _buildField(
                  controller: _nameController,
                  label: '場所の名前（任意）',
                  icon: Icons.place_outlined,
                  hint: '例: コメダ西葛西店（なくてもOK）',
                ),
                const SizedBox(height: 12),

                // ── メモ ──
                _buildField(
                  controller: _memoController,
                  label: 'メモ・感想',
                  icon: Icons.edit_note,
                  hint: '感想や覚えておきたいことを自由に',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // ── 登録ボタン ──
                FilledButton.icon(
                  onPressed: _photoPath == null ? null : _registerWithAI,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AIで自動記入して登録'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '写真のGPS情報から位置を取得します。店名を入れるとAIがジャンル・住所・概要を自動入力します。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    if (_photoPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              File(_photoPath!),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _PhotoActionButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
                const SizedBox(width: 6),
                _PhotoActionButton(
                  icon: Icons.photo_library_outlined,
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // カメラ起動ボタン（大）
        GestureDetector(
          onTap: () => _pickPhoto(ImageSource.camera),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppPalette.soften(AppPalette.archive, 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppPalette.archive.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: AppPalette.archive,
                ),
                const SizedBox(height: 8),
                Text(
                  'カメラで撮影',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.archive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'GPS情報も自動取得',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.archive.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // ライブラリから選択ボタン
        OutlinedButton.icon(
          onPressed: () => _pickPhoto(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('フォトライブラリから選択'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppPalette.archive),
          const SizedBox(width: 6),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PhotoActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
