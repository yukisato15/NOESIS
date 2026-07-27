import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/maps/spot_geocoding_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/spot_photo_service.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/spots_table.dart';
import '../shared/surface_field.dart';

class SpotEditScreen extends StatefulWidget {
  final int? spotId;

  const SpotEditScreen({super.key, this.spotId});

  @override
  State<SpotEditScreen> createState() => _SpotEditScreenState();
}

enum _SpotAssistMode { webResearch, normalAi }

class _SpotEditScreenState extends State<SpotEditScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aliasesController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mapUrlController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _placeIdController = TextEditingController();
  final TextEditingController _geocodeSourceController =
      TextEditingController();
  final TextEditingController _mapLabelController = TextEditingController();
  final TextEditingController _mapPinColorController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _snsUrlsController = TextEditingController();
  final TextEditingController _businessHoursController =
      TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _atmosphereController = TextEditingController();
  final TextEditingController _strengthsController = TextEditingController();
  final TextEditingController _weaknessesController = TextEditingController();
  final TextEditingController _recommendedForController =
      TextEditingController();
  final TextEditingController _avoidForController = TextEditingController();
  final TextEditingController _stayDurationController = TextEditingController();
  final TextEditingController _paymentNoteController = TextEditingController();
  final TextEditingController _smokingPolicyController =
      TextEditingController();
  final TextEditingController _seatComfortController = TextEditingController();
  final TextEditingController _accessNoteController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _rawMemoController = TextEditingController();
  final TextEditingController _aiSummaryController = TextEditingController();
  final TextEditingController _aiRecommendationNoteController =
      TextEditingController();
  final TextEditingController _aiUseCaseNoteController =
      TextEditingController();

  Spot? _spot;
  SpotPriceRange? _priceRange;
  bool? _hasWifi;
  bool? _hasPower;
  double _soloFriendly = 3;
  double _friendFriendly = 3;
  double _dateFriendly = 3;
  double _workFriendly = 3;
  double _conversationFriendly = 3;
  double _quietness = 3;
  double _crowdedness = 3;
  double _favoriteScore = 50;
  double _revisitScore = 50;
  bool _isMapVisible = true;
  String? _photoPath;
  final _picker = ImagePicker();
  _SpotAssistMode _assistMode = _SpotAssistMode.webResearch;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPolishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _nameController.dispose();
    _aliasesController.dispose();
    _genreController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _mapUrlController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _placeIdController.dispose();
    _geocodeSourceController.dispose();
    _mapLabelController.dispose();
    _mapPinColorController.dispose();
    _websiteUrlController.dispose();
    _snsUrlsController.dispose();
    _businessHoursController.dispose();
    _summaryController.dispose();
    _atmosphereController.dispose();
    _strengthsController.dispose();
    _weaknessesController.dispose();
    _recommendedForController.dispose();
    _avoidForController.dispose();
    _stayDurationController.dispose();
    _paymentNoteController.dispose();
    _smokingPolicyController.dispose();
    _seatComfortController.dispose();
    _accessNoteController.dispose();
    _tagsController.dispose();
    _rawMemoController.dispose();
    _aiSummaryController.dispose();
    _aiRecommendationNoteController.dispose();
    _aiUseCaseNoteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.spotId != null) {
      final spot = await _db.spotsDao.getSpotById(widget.spotId!);
      if (spot != null) {
        _spot = spot;
        _nameController.text = spot.name;
        _aliasesController.text = _decodeJsonList(spot.aliases).join(', ');
        _genreController.text = spot.genre ?? '';
        _areaController.text = spot.area ?? '';
        _addressController.text = spot.address ?? '';
        _mapUrlController.text = spot.mapUrl ?? '';
        _latitudeController.text = spot.latitude?.toString() ?? '';
        _longitudeController.text = spot.longitude?.toString() ?? '';
        _placeIdController.text = spot.placeId ?? '';
        _geocodeSourceController.text = spot.geocodeSource ?? '';
        _mapLabelController.text = spot.mapLabel ?? '';
        _mapPinColorController.text = spot.mapPinColor ?? '';
        _websiteUrlController.text = spot.websiteUrl ?? '';
        _snsUrlsController.text = _decodeJsonList(spot.snsUrls).join('\n');
        _businessHoursController.text = spot.businessHoursNote ?? '';
        _summaryController.text = spot.summary ?? '';
        _atmosphereController.text = spot.atmosphere ?? '';
        _strengthsController.text = spot.strengths ?? '';
        _weaknessesController.text = spot.weaknesses ?? '';
        _recommendedForController.text = spot.recommendedFor ?? '';
        _avoidForController.text = spot.avoidFor ?? '';
        _stayDurationController.text = spot.stayDurationNote ?? '';
        _paymentNoteController.text = spot.paymentNote ?? '';
        _smokingPolicyController.text = spot.smokingPolicy ?? '';
        _seatComfortController.text = spot.seatComfortNote ?? '';
        _accessNoteController.text = spot.accessNote ?? '';
        _tagsController.text = _decodeJsonList(spot.tags).join(', ');
        _aiSummaryController.text = spot.aiSummary ?? '';
        _aiRecommendationNoteController.text = spot.aiRecommendationNote ?? '';
        _aiUseCaseNoteController.text = spot.aiUseCaseNote ?? '';
        _priceRange = spot.priceRange;
        _hasWifi = spot.hasWifi;
        _hasPower = spot.hasPower;
        _soloFriendly = (spot.soloFriendly ?? 3).toDouble();
        _friendFriendly = (spot.friendFriendly ?? 3).toDouble();
        _dateFriendly = (spot.dateFriendly ?? 3).toDouble();
        _workFriendly = (spot.workFriendly ?? 3).toDouble();
        _conversationFriendly = (spot.conversationFriendly ?? 3).toDouble();
        _quietness = (spot.quietnessLevel ?? 3).toDouble();
        _crowdedness = (spot.crowdednessLevel ?? 3).toDouble();
        _favoriteScore = spot.favoriteScore.toDouble();
        _revisitScore = spot.revisitScore.toDouble();
        _isMapVisible = spot.isMapVisible;
        _photoPath = spot.photoPath;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<String> _decodeJsonList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return raw
          .split(RegExp(r'[\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  String? _encodeList(String raw) {
    final items = raw
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return items.isEmpty ? null : jsonEncode(items);
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _nullableDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  String _buildResearchQuery() {
    final parts = [
      _nameController.text.trim(),
      _genreController.text.trim(),
      _areaController.text.trim(),
    ].where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '';
    }
    return '${parts.join(' ')} 住所 公式サイト 営業時間';
  }

  Map<String, dynamic> _spotPolishSchema() {
    return {
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'genre': {'type': 'string'},
        'area': {'type': 'string'},
        'address': {'type': 'string'},
        'latitude': {'type': 'number'},
        'longitude': {'type': 'number'},
        'map_url': {'type': 'string'},
        'website_url': {'type': 'string'},
        'sns_urls': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'business_hours_note': {'type': 'string'},
        'summary': {'type': 'string'},
        'atmosphere': {'type': 'string'},
        'strengths': {'type': 'string'},
        'weaknesses': {'type': 'string'},
        'recommended_for': {'type': 'string'},
        'avoid_for': {'type': 'string'},
        'stay_duration_note': {'type': 'string'},
        'payment_note': {'type': 'string'},
        'smoking_policy': {'type': 'string'},
        'seat_comfort_note': {'type': 'string'},
        'access_note': {'type': 'string'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'ai_summary': {'type': 'string'},
        'ai_recommendation_note': {'type': 'string'},
        'ai_use_case_note': {'type': 'string'},
      },
    };
  }

  void _applyAiResult(Map<String, dynamic> result) {
    _nameController.text = (result['name'] ?? _nameController.text).toString();
    _genreController.text = (result['genre'] ?? _genreController.text)
        .toString();
    _areaController.text = (result['area'] ?? _areaController.text).toString();
    _addressController.text = (result['address'] ?? _addressController.text)
        .toString();
    final latitude = result['latitude'];
    if (latitude != null) {
      _latitudeController.text = latitude.toString();
    }
    final longitude = result['longitude'];
    if (longitude != null) {
      _longitudeController.text = longitude.toString();
    }
    _mapUrlController.text = (result['map_url'] ?? _mapUrlController.text)
        .toString();
    _websiteUrlController.text =
        (result['website_url'] ?? _websiteUrlController.text).toString();
    final snsUrls = (result['sns_urls'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    if (snsUrls.isNotEmpty) {
      _snsUrlsController.text = snsUrls.join('\n');
    }
    _businessHoursController.text =
        (result['business_hours_note'] ?? _businessHoursController.text)
            .toString();
    _summaryController.text = (result['summary'] ?? _summaryController.text)
        .toString();
    _atmosphereController.text =
        (result['atmosphere'] ?? _atmosphereController.text).toString();
    _strengthsController.text =
        (result['strengths'] ?? _strengthsController.text).toString();
    _weaknessesController.text =
        (result['weaknesses'] ?? _weaknessesController.text).toString();
    _recommendedForController.text =
        (result['recommended_for'] ?? _recommendedForController.text)
            .toString();
    _avoidForController.text = (result['avoid_for'] ?? _avoidForController.text)
        .toString();
    _stayDurationController.text =
        (result['stay_duration_note'] ?? _stayDurationController.text)
            .toString();
    _paymentNoteController.text =
        (result['payment_note'] ?? _paymentNoteController.text).toString();
    _smokingPolicyController.text =
        (result['smoking_policy'] ?? _smokingPolicyController.text).toString();
    _seatComfortController.text =
        (result['seat_comfort_note'] ?? _seatComfortController.text).toString();
    _accessNoteController.text =
        (result['access_note'] ?? _accessNoteController.text).toString();
    final tags = (result['tags'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    if (tags.isNotEmpty) {
      _tagsController.text = tags.join(', ');
    }
    _aiSummaryController.text =
        (result['ai_summary'] ?? _aiSummaryController.text).toString();
    _aiRecommendationNoteController.text =
        (result['ai_recommendation_note'] ??
                _aiRecommendationNoteController.text)
            .toString();
    _aiUseCaseNoteController.text =
        (result['ai_use_case_note'] ?? _aiUseCaseNoteController.text)
            .toString();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() => _isPolishing = true);
    try {
      final savedPath = await SpotPhotoService.savePhoto(
        sourceImagePath: picked.path,
        prefix: 'spot',
      );
      setState(() => _photoPath = savedPath);
    } finally {
      if (mounted) setState(() => _isPolishing = false);
    }
  }

  Future<void> _removePhoto() async {
    await SpotPhotoService.deletePhoto(_photoPath);
    setState(() => _photoPath = null);
  }

  /// 地図情報を解決して各フィールドに反映する。
  /// [showSnackBar] が true のとき完了メッセージを表示する。
  Future<void> _fillMapMetadata({bool showSnackBar = true}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (showSnackBar) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('店名や場所名を入力してください')));
      }
      return;
    }
    setState(() => _isPolishing = true);
    try {
      final resolved = await SpotGeocodingService.resolve(
        name: name,
        area: _areaController.text.trim(),
        address: _addressController.text.trim(),
        mapUrl: _mapUrlController.text.trim(),
      );

      bool hasCoords = false;
      if (resolved.latitude != null) {
        _latitudeController.text = resolved.latitude!.toString();
        hasCoords = true;
      }
      if (resolved.longitude != null) {
        _longitudeController.text = resolved.longitude!.toString();
      }
      if ((resolved.address ?? '').isNotEmpty &&
          _addressController.text.trim().isEmpty) {
        _addressController.text = resolved.address!;
      }
      if ((resolved.mapUrl ?? '').isNotEmpty &&
          _mapUrlController.text.trim().isEmpty) {
        _mapUrlController.text = resolved.mapUrl!;
      }
      if ((resolved.websiteUrl ?? '').isNotEmpty &&
          _websiteUrlController.text.trim().isEmpty) {
        _websiteUrlController.text = resolved.websiteUrl!;
      }
      if ((resolved.mapLabel ?? '').isNotEmpty) {
        _mapLabelController.text = resolved.mapLabel!;
      }
      if ((resolved.geocodeSource ?? '').isNotEmpty) {
        _geocodeSourceController.text = resolved.geocodeSource!;
      }

      if (showSnackBar && mounted) {
        final msg = hasCoords
            ? '地図情報を補完しました（座標あり）'
            : (resolved.mapUrl ?? '').isNotEmpty
            ? '地図URLを補完しました（座標なし）'
            : '地図情報の補完に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('地図情報の補完に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPolishing = false);
      }
    }
  }

  Future<void> _polishWithAi(_SpotAssistMode mode) async {
    final raw = _rawMemoController.text.trim();
    final name = _nameController.text.trim();
    if (mode == _SpotAssistMode.webResearch && name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Webリサーチには店名や場所名が必要です')));
      return;
    }
    if (mode == _SpotAssistMode.normalAi &&
        raw.isEmpty &&
        _summaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('元メモか概要を入力してください')));
      return;
    }
    if (mode == _SpotAssistMode.webResearch && !SearchClient.canUseWebSearch) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Web検索設定が未構成です')));
      return;
    }
    if (!AIClient.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI設定が未構成です')));
      return;
    }
    setState(() => _isPolishing = true);
    try {
      final prompt = mode == _SpotAssistMode.webResearch
          ? '''
あなたは事実ベースでスポット情報を整理するリサーチ補助AIです。
以下の検索結果だけを根拠に、店や場所の基本情報を構造化してください。
検索結果に根拠がない項目は空欄にしてください。推測で埋めてはいけません。

対象:
- 名前: $name
- 補助メモ: ${raw.isEmpty ? 'なし' : raw}

検索結果:
{{SEARCH_RESULTS}}

条件:
- address, map_url, website_url, sns_urls, business_hours_note は検索結果に根拠がある時だけ
- summary, atmosphere, strengths, recommended_for は検索結果から読み取れる範囲だけ
- 誇張禁止
- ハルシネーション禁止
'''
          : '''
あなたはスポットアーカイブ編集者です。
以下のメモから、店や場所を再訪・紹介しやすい形に整理してください。

元メモ:
${raw.isEmpty ? _summaryController.text.trim() : raw}

条件:
- 誇張しない
- 実際に再訪や紹介に使いやすい項目に整理
- 分からない項目は空欄でよい
- map_url や website_url のようなURLは、確信がある時だけ
''';
      late final Map<String, dynamic> result;
      if (mode == _SpotAssistMode.webResearch) {
        final searchResults = await SearchClient.instance.search(
          _buildResearchQuery(),
          maxResults: 8,
        );
        final searchContext = SearchClient.instance.formatSearchResults(
          searchResults,
        );
        result = await AIClient.instance.generateStructured(
          prompt: prompt.replaceFirst('{{SEARCH_RESULTS}}', searchContext),
          jsonSchema: _spotPolishSchema(),
          mode: AIMode.standard,
        );
      } else {
        result = await AIClient.instance.generateStructured(
          prompt: prompt,
          jsonSchema: _spotPolishSchema(),
          mode: AIMode.standard,
        );
      }
      _applyAiResult(result);
      if (mode == _SpotAssistMode.webResearch) {
        final resolved = await SpotGeocodingService.resolve(
          name: _nameController.text.trim(),
          area: _areaController.text.trim(),
          address: _addressController.text.trim(),
          mapUrl: _mapUrlController.text.trim(),
        );
        if (resolved.latitude != null) {
          _latitudeController.text = resolved.latitude!.toString();
        }
        if (resolved.longitude != null) {
          _longitudeController.text = resolved.longitude!.toString();
        }
        if ((resolved.mapUrl ?? '').isNotEmpty &&
            _mapUrlController.text.trim().isEmpty) {
          _mapUrlController.text = resolved.mapUrl!;
        }
        if ((resolved.mapLabel ?? '').isNotEmpty &&
            _mapLabelController.text.trim().isEmpty) {
          _mapLabelController.text = resolved.mapLabel!;
        }
        if ((resolved.geocodeSource ?? '').isNotEmpty) {
          _geocodeSourceController.text = resolved.geocodeSource!;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI整理に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPolishing = false);
      }
    }
  }

  Widget _buildPhotoSection() {
    final theme = Theme.of(context);
    if (_photoPath != null && File(_photoPath!).existsSync()) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(_photoPath!),
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _editPhotoButton(
                  icon: Icons.camera_alt_outlined,
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
                const SizedBox(width: 6),
                _editPhotoButton(
                  icon: Icons.photo_library_outlined,
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
                const SizedBox(width: 6),
                _editPhotoButton(
                  icon: Icons.delete_outline,
                  onTap: _removePhoto,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('撮影して登録'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              'ライブラリから',
              style: theme.textTheme.labelMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _editPhotoButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.85)
              : Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名前を入力してください')));
      return;
    }
    setState(() => _isSaving = true);
    final now = DateTime.now();
    try {
      if (_spot == null) {
        await _db.spotsDao.insertSpot(
          SpotsCompanion.insert(
            name: name,
            aliases: drift.Value(_encodeList(_aliasesController.text)),
            genre: drift.Value(_nullable(_genreController.text)),
            area: drift.Value(_nullable(_areaController.text)),
            address: drift.Value(_nullable(_addressController.text)),
            mapUrl: drift.Value(_nullable(_mapUrlController.text)),
            latitude: drift.Value(_nullableDouble(_latitudeController.text)),
            longitude: drift.Value(_nullableDouble(_longitudeController.text)),
            placeId: drift.Value(_nullable(_placeIdController.text)),
            geocodeSource: drift.Value(
              _nullable(_geocodeSourceController.text),
            ),
            mapLabel: drift.Value(_nullable(_mapLabelController.text)),
            isMapVisible: drift.Value(_isMapVisible),
            photoPath: drift.Value(_photoPath),
            mapPinColor: drift.Value(_nullable(_mapPinColorController.text)),
            websiteUrl: drift.Value(_nullable(_websiteUrlController.text)),
            snsUrls: drift.Value(_encodeList(_snsUrlsController.text)),
            businessHoursNote: drift.Value(
              _nullable(_businessHoursController.text),
            ),
            summary: drift.Value(_nullable(_summaryController.text)),
            atmosphere: drift.Value(_nullable(_atmosphereController.text)),
            strengths: drift.Value(_nullable(_strengthsController.text)),
            weaknesses: drift.Value(_nullable(_weaknessesController.text)),
            recommendedFor: drift.Value(
              _nullable(_recommendedForController.text),
            ),
            avoidFor: drift.Value(_nullable(_avoidForController.text)),
            soloFriendly: drift.Value(_soloFriendly.round()),
            friendFriendly: drift.Value(_friendFriendly.round()),
            dateFriendly: drift.Value(_dateFriendly.round()),
            workFriendly: drift.Value(_workFriendly.round()),
            conversationFriendly: drift.Value(_conversationFriendly.round()),
            stayDurationNote: drift.Value(
              _nullable(_stayDurationController.text),
            ),
            quietnessLevel: drift.Value(_quietness.round()),
            crowdednessLevel: drift.Value(_crowdedness.round()),
            priceRange: drift.Value(_priceRange),
            paymentNote: drift.Value(_nullable(_paymentNoteController.text)),
            hasWifi: drift.Value(_hasWifi),
            hasPower: drift.Value(_hasPower),
            smokingPolicy: drift.Value(
              _nullable(_smokingPolicyController.text),
            ),
            seatComfortNote: drift.Value(
              _nullable(_seatComfortController.text),
            ),
            accessNote: drift.Value(_nullable(_accessNoteController.text)),
            favoriteScore: drift.Value(_favoriteScore.round()),
            revisitScore: drift.Value(_revisitScore.round()),
            tags: drift.Value(_encodeList(_tagsController.text)),
            aiSummary: drift.Value(_nullable(_aiSummaryController.text)),
            aiRecommendationNote: drift.Value(
              _nullable(_aiRecommendationNoteController.text),
            ),
            aiUseCaseNote: drift.Value(
              _nullable(_aiUseCaseNoteController.text),
            ),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
      } else {
        await _db.spotsDao.updateSpot(
          _spot!.copyWith(
            name: name,
            aliases: drift.Value(_encodeList(_aliasesController.text)),
            genre: drift.Value(_nullable(_genreController.text)),
            area: drift.Value(_nullable(_areaController.text)),
            address: drift.Value(_nullable(_addressController.text)),
            mapUrl: drift.Value(_nullable(_mapUrlController.text)),
            latitude: drift.Value(_nullableDouble(_latitudeController.text)),
            longitude: drift.Value(_nullableDouble(_longitudeController.text)),
            placeId: drift.Value(_nullable(_placeIdController.text)),
            geocodeSource: drift.Value(
              _nullable(_geocodeSourceController.text),
            ),
            mapLabel: drift.Value(_nullable(_mapLabelController.text)),
            isMapVisible: _isMapVisible,
            photoPath: drift.Value(_photoPath),
            mapPinColor: drift.Value(_nullable(_mapPinColorController.text)),
            websiteUrl: drift.Value(_nullable(_websiteUrlController.text)),
            snsUrls: drift.Value(_encodeList(_snsUrlsController.text)),
            businessHoursNote: drift.Value(
              _nullable(_businessHoursController.text),
            ),
            summary: drift.Value(_nullable(_summaryController.text)),
            atmosphere: drift.Value(_nullable(_atmosphereController.text)),
            strengths: drift.Value(_nullable(_strengthsController.text)),
            weaknesses: drift.Value(_nullable(_weaknessesController.text)),
            recommendedFor: drift.Value(
              _nullable(_recommendedForController.text),
            ),
            avoidFor: drift.Value(_nullable(_avoidForController.text)),
            soloFriendly: drift.Value(_soloFriendly.round()),
            friendFriendly: drift.Value(_friendFriendly.round()),
            dateFriendly: drift.Value(_dateFriendly.round()),
            workFriendly: drift.Value(_workFriendly.round()),
            conversationFriendly: drift.Value(_conversationFriendly.round()),
            stayDurationNote: drift.Value(
              _nullable(_stayDurationController.text),
            ),
            quietnessLevel: drift.Value(_quietness.round()),
            crowdednessLevel: drift.Value(_crowdedness.round()),
            priceRange: drift.Value(_priceRange),
            paymentNote: drift.Value(_nullable(_paymentNoteController.text)),
            hasWifi: drift.Value(_hasWifi),
            hasPower: drift.Value(_hasPower),
            smokingPolicy: drift.Value(
              _nullable(_smokingPolicyController.text),
            ),
            seatComfortNote: drift.Value(
              _nullable(_seatComfortController.text),
            ),
            accessNote: drift.Value(_nullable(_accessNoteController.text)),
            favoriteScore: _favoriteScore.round(),
            revisitScore: _revisitScore.round(),
            tags: drift.Value(_encodeList(_tagsController.text)),
            aiSummary: drift.Value(_nullable(_aiSummaryController.text)),
            aiRecommendationNote: drift.Value(
              _nullable(_aiRecommendationNoteController.text),
            ),
            aiUseCaseNote: drift.Value(
              _nullable(_aiUseCaseNoteController.text),
            ),
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _scoreSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${value.round()}'),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spotId == null ? 'スポットを追加' : 'スポットを編集'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SurfaceField(
                  label: 'ラフメモ',
                  hintText: '訪問メモ、店の特徴、雰囲気など',
                  controller: _rawMemoController,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SegmentedButton<_SpotAssistMode>(
                  segments: const [
                    ButtonSegment(
                      value: _SpotAssistMode.webResearch,
                      icon: Icon(Icons.travel_explore),
                      label: Text('Webリサーチ'),
                    ),
                    ButtonSegment(
                      value: _SpotAssistMode.normalAi,
                      icon: Icon(Icons.auto_awesome),
                      label: Text('通常AI'),
                    ),
                  ],
                  selected: {_assistMode},
                  onSelectionChanged: _isPolishing
                      ? null
                      : (selection) {
                          setState(() => _assistMode = selection.first);
                        },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isPolishing
                      ? null
                      : () => _polishWithAi(_assistMode),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.talkingTopic,
                  ),
                  icon: _isPolishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _assistMode == _SpotAssistMode.webResearch
                              ? Icons.travel_explore
                              : Icons.auto_awesome,
                        ),
                  label: Text(
                    _isPolishing
                        ? '整理中...'
                        : _assistMode == _SpotAssistMode.webResearch
                        ? 'Webリサーチで補完'
                        : '通常AIで整理',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _assistMode == _SpotAssistMode.webResearch
                      ? '店名や場所名から検索して、住所や概要などを自動補完します'
                      : 'ラフメモをもとに、通常の AI で内容を整えます',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isPolishing ? null : _fillMapMetadata,
                  icon: const Icon(Icons.pin_drop_outlined),
                  label: const Text('地図情報を補完'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoSection(),
          const SizedBox(height: 16),
          SurfaceField(label: '名前', controller: _nameController),
          const SizedBox(height: 16),
          SurfaceField(label: '別名', controller: _aliasesController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SurfaceField(
                  label: 'ジャンル',
                  controller: _genreController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SurfaceField(label: 'エリア', controller: _areaController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SurfaceField(label: '住所', controller: _addressController),
          const SizedBox(height: 16),
          SurfaceField(label: 'Google Maps URL', controller: _mapUrlController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SurfaceField(
                  label: '緯度',
                  controller: _latitudeController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SurfaceField(
                  label: '経度',
                  controller: _longitudeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DraggablePinMap(
            latController: _latitudeController,
            lngController: _longitudeController,
          ),
          const SizedBox(height: 16),
          SurfaceField(label: '地図ラベル', controller: _mapLabelController),
          const SizedBox(height: 16),
          SurfaceField(label: 'Place ID', controller: _placeIdController),
          const SizedBox(height: 16),
          SurfaceField(label: '地図情報の取得元', controller: _geocodeSourceController),
          const SizedBox(height: 16),
          SurfaceField(label: 'ピン色', controller: _mapPinColorController),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _isMapVisible,
            onChanged: (value) => setState(() => _isMapVisible = value),
            title: const Text('地図に表示する'),
          ),
          const SizedBox(height: 8),
          SurfaceField(label: '公式サイト', controller: _websiteUrlController),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'SNS URL',
            hintText: '1行に1URL',
            controller: _snsUrlsController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '営業情報メモ',
            controller: _businessHoursController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '一言説明',
            controller: _summaryController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '雰囲気',
            controller: _atmosphereController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '良い点',
            controller: _strengthsController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '微妙な点',
            controller: _weaknessesController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '向いている相手・場面',
            controller: _recommendedForController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '向かない相手・場面',
            controller: _avoidForController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '滞在時間メモ',
            controller: _stayDurationController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SurfaceField(label: '支払いメモ', controller: _paymentNoteController),
          const SizedBox(height: 16),
          SurfaceField(label: '喫煙ポリシー', controller: _smokingPolicyController),
          const SizedBox(height: 16),
          SurfaceField(
            label: '席の快適さ',
            controller: _seatComfortController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'アクセスメモ',
            controller: _accessNoteController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SurfaceField(label: 'タグ', controller: _tagsController),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'AI総評',
            controller: _aiSummaryController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'AIおすすめメモ',
            controller: _aiRecommendationNoteController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'AI使いどころメモ',
            controller: _aiUseCaseNoteController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使いやすさ',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                _scoreSlider(
                  '1人向き',
                  _soloFriendly,
                  (v) => setState(() => _soloFriendly = v),
                ),
                _scoreSlider(
                  '友人向き',
                  _friendFriendly,
                  (v) => setState(() => _friendFriendly = v),
                ),
                _scoreSlider(
                  'デート向き',
                  _dateFriendly,
                  (v) => setState(() => _dateFriendly = v),
                ),
                _scoreSlider(
                  '作業向き',
                  _workFriendly,
                  (v) => setState(() => _workFriendly = v),
                ),
                _scoreSlider(
                  '会話向き',
                  _conversationFriendly,
                  (v) => setState(() => _conversationFriendly = v),
                ),
                _scoreSlider(
                  '静かさ',
                  _quietness,
                  (v) => setState(() => _quietness = v),
                ),
                _scoreSlider(
                  '混みやすさ',
                  _crowdedness,
                  (v) => setState(() => _crowdedness = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SpotPriceRange?>(
                  value: _priceRange,
                  decoration: const InputDecoration(labelText: '価格帯'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('未設定')),
                    DropdownMenuItem(
                      value: SpotPriceRange.low,
                      child: Text('安い'),
                    ),
                    DropdownMenuItem(
                      value: SpotPriceRange.medium,
                      child: Text('普通'),
                    ),
                    DropdownMenuItem(
                      value: SpotPriceRange.high,
                      child: Text('高め'),
                    ),
                    DropdownMenuItem(
                      value: SpotPriceRange.unknown,
                      child: Text('不明'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _priceRange = value),
                ),
                DropdownButtonFormField<bool?>(
                  value: _hasWifi,
                  decoration: const InputDecoration(labelText: 'Wi-Fi'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('未設定')),
                    DropdownMenuItem(value: true, child: Text('あり')),
                    DropdownMenuItem(value: false, child: Text('なし')),
                  ],
                  onChanged: (value) => setState(() => _hasWifi = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<bool?>(
                  value: _hasPower,
                  decoration: const InputDecoration(labelText: '電源'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('未設定')),
                    DropdownMenuItem(value: true, child: Text('あり')),
                    DropdownMenuItem(value: false, child: Text('なし')),
                  ],
                  onChanged: (value) => setState(() => _hasPower = value),
                ),
                Text('お気に入り度 ${_favoriteScore.round()}'),
                Slider(
                  value: _favoriteScore,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (value) => setState(() => _favoriteScore = value),
                ),
                Text('再訪したい度 ${_revisitScore.round()}'),
                Slider(
                  value: _revisitScore,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (value) => setState(() => _revisitScore = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ドラッグで位置を修正できるミニマップ
// ─────────────────────────────────────────────────────────────────────────────

class _DraggablePinMap extends StatefulWidget {
  final TextEditingController latController;
  final TextEditingController lngController;

  const _DraggablePinMap({
    required this.latController,
    required this.lngController,
  });

  @override
  State<_DraggablePinMap> createState() => _DraggablePinMapState();
}

class _DraggablePinMapState extends State<_DraggablePinMap> {
  final MapController _mapController = MapController();
  LatLng? _pinPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pinPosition = _parseLatLng();
    widget.latController.addListener(_onFieldChanged);
    widget.lngController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    widget.latController.removeListener(_onFieldChanged);
    widget.lngController.removeListener(_onFieldChanged);
    super.dispose();
  }

  void _onFieldChanged() {
    final pos = _parseLatLng();
    if (pos != null && pos != _pinPosition) {
      setState(() => _pinPosition = pos);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(pos, _mapController.camera.zoom);
      });
    }
  }

  LatLng? _parseLatLng() {
    final lat = double.tryParse(widget.latController.text.trim());
    final lng = double.tryParse(widget.lngController.text.trim());
    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  void _updateFields(LatLng pos) {
    widget.latController.text = pos.latitude.toStringAsFixed(6);
    widget.lngController.text = pos.longitude.toStringAsFixed(6);
    setState(() => _pinPosition = pos);
  }

  @override
  Widget build(BuildContext context) {
    if (_pinPosition == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E3DC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '緯度・経度を入力すると\nドラッグで位置を修正できます',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.open_with, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'ピンをドラッグして位置を修正',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinPosition!,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.noesis.noesis_flutter',
                    ),
                  ],
                ),
                // ドラッグ可能なピン（画面中央固定、地図を動かす方式）
                Center(
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => _isDragging = true),
                    onPanEnd: (_) {
                      setState(() => _isDragging = false);
                      _updateFields(_mapController.camera.center);
                    },
                    onPanUpdate: (details) {
                      final camera = _mapController.camera;
                      final newCenter = camera.center;
                      // パン中はピンを中心として地図を動かす
                      _mapController.move(
                        LatLng(
                          newCenter.latitude -
                              details.delta.dy *
                                  (0.00001 / camera.zoom * 180),
                          newCenter.longitude +
                              details.delta.dx *
                                  (0.00001 / camera.zoom * 180),
                        ),
                        camera.zoom,
                      );
                    },
                    child: AnimatedScale(
                      scale: _isDragging ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: CustomPaint(
                        size: const Size(40, 50),
                        painter: _EditPinPainter(dragging: _isDragging),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditPinPainter extends CustomPainter {
  final bool dragging;
  const _EditPinPainter({required this.dragging});

  @override
  void paint(Canvas canvas, Size size) {
    final color = dragging ? AppPalette.talkingTopic : AppPalette.archive;
    final paint = Paint()..color = color;
    final r = size.width / 2;
    final center = Offset(r, r);

    canvas.drawCircle(
      center.translate(0, 2),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tip = ui.Path()
      ..moveTo(r - r * 0.4, size.height - 10)
      ..lineTo(r + r * 0.4, size.height - 10)
      ..lineTo(r, size.height)
      ..close();
    canvas.drawPath(tip, paint);
    canvas.drawLine(
      Offset(r, r - r * 0.35),
      Offset(r, r + r * 0.35),
      Paint()..color = Colors.white..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(r - r * 0.35, r),
      Offset(r + r * 0.35, r),
      Paint()..color = Colors.white..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_EditPinPainter old) => old.dragging != dragging;
}
