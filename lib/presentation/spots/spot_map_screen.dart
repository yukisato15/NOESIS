import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/spot_map_filter_repository.dart';
import 'spot_detail_screen.dart';

class SpotMapScreen extends StatefulWidget {
  const SpotMapScreen({super.key});

  @override
  State<SpotMapScreen> createState() => _SpotMapScreenState();
}

class _SpotMapScreenState extends State<SpotMapScreen>
    with SingleTickerProviderStateMixin {
  static const _builtInPresets = [
    SpotMapFilterPreset(
      id: 'preset_tourist',
      name: '観光名所',
      tagContains: '観光名所',
    ),
    SpotMapFilterPreset(
      id: 'preset_izakaya',
      name: '居酒屋',
      genreContains: '居酒屋',
      minConversationScore: 4,
    ),
    SpotMapFilterPreset(
      id: 'preset_french',
      name: 'フレンチ',
      genreContains: 'フレンチ',
      minConversationScore: 4,
    ),
  ];

  final AppDatabase _db = AppDatabase();
  final SpotMapFilterRepository _filterRepository =
      const SpotMapFilterRepository();
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  List<Spot> _spots = [];
  List<Spot> _filtered = [];
  List<SpotMapFilterPreset> _savedFilters = [];
  String? _genre;
  String? _tag;
  int? _minConversationScore;
  int? _minWorkScore;
  LatLng? _currentLocation;
  Spot? _selectedSpot;
  String? _activePresetId;
  bool _isLoading = true;
  bool _showFilterPanel = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final spots = await _db.spotsDao.getMappableSpots();
    final savedFilters = await _filterRepository.loadSavedFilters();
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _savedFilters = savedFilters;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = _spots.where((spot) {
      final genre = (spot.genre ?? '').trim();
      if (_genre != null && _genre != genre) return false;
      final tags = _decodeTags(spot.tags);
      if (_tag != null && !tags.contains(_tag)) return false;
      if (_minConversationScore != null &&
          (spot.conversationFriendly ?? 0) < _minConversationScore!) {
        return false;
      }
      if (_minWorkScore != null && (spot.workFriendly ?? 0) < _minWorkScore!) {
        return false;
      }
      final bag = [
        spot.name,
        spot.genre ?? '',
        spot.area ?? '',
        spot.summary ?? '',
        spot.tags ?? '',
      ].join('\n').toLowerCase();
      return keyword.isEmpty || bag.contains(keyword);
    }).toList();
    setState(() {
      _filtered = filtered;
      if (_selectedSpot != null &&
          !_filtered.any((spot) => spot.id == _selectedSpot!.id)) {
        _selectedSpot = filtered.isEmpty ? null : filtered.first;
      } else if (_selectedSpot == null && filtered.isNotEmpty) {
        _selectedSpot = filtered.first;
      }
    });
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  List<String> _genres() {
    return _spots
        .map((spot) => (spot.genre ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _tags() {
    return _spots
        .expand((spot) => _decodeTags(spot.tags))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _applyPreset(SpotMapFilterPreset preset) {
    String? matchedGenre;
    if ((preset.genreContains ?? '').isNotEmpty) {
      matchedGenre = _genres().cast<String?>().firstWhere(
        (genre) => genre!.contains(preset.genreContains!),
        orElse: () => null,
      );
    }
    String? matchedTag;
    if ((preset.tagContains ?? '').isNotEmpty) {
      matchedTag = _tags().cast<String?>().firstWhere(
        (tag) => tag!.contains(preset.tagContains!),
        orElse: () => null,
      );
    }
    setState(() {
      _activePresetId = preset.id;
      _searchController.text = preset.keyword ?? '';
      _genre = matchedGenre;
      _tag = matchedTag;
      _minConversationScore = preset.minConversationScore;
      _minWorkScore = preset.minWorkScore;
      _showFilterPanel = false;
    });
    _applyFilters();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitFilteredBounds());
  }

  Future<void> _saveCurrentFilter() async {
    final nameController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('現在のフィルタを保存'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名前'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final preset = SpotMapFilterPreset(
      id: 'saved_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      keyword: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      genreContains: _genre,
      tagContains: _tag,
      minConversationScore: _minConversationScore,
      minWorkScore: _minWorkScore,
    );
    await _filterRepository.saveFilter(preset);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('フィルタを保存しました')),
    );
  }

  Future<void> _deleteSavedFilter(SpotMapFilterPreset preset) async {
    await _filterRepository.deleteFilter(preset.id);
    await _load();
  }

  Future<void> _openDetail(Spot spot) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SpotDetailScreen(spotId: spot.id)),
    );
    await _load();
  }

  Future<void> _openInGoogleMaps(Spot spot) async {
    final url = spot.mapUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置情報サービスが無効です')),
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置情報の許可が必要です')),
      );
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final location = LatLng(position.latitude, position.longitude);
    setState(() => _currentLocation = location);
    _mapController.move(location, 15);
  }

  void _fitFilteredBounds() {
    if (_filtered.isEmpty) return;
    if (_filtered.length == 1) {
      _mapController.move(
        LatLng(_filtered.first.latitude!, _filtered.first.longitude!),
        15,
      );
      return;
    }
    final points =
        _filtered.map((spot) => LatLng(spot.latitude!, spot.longitude!)).toList();
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 260),
      ),
    );
  }

  LatLng _mapCenter() {
    if (_filtered.isEmpty) return const LatLng(35.681236, 139.767125);
    final avgLat =
        _filtered.map((spot) => spot.latitude!).reduce((a, b) => a + b) /
        _filtered.length;
    final avgLng =
        _filtered.map((spot) => spot.longitude!).reduce((a, b) => a + b) /
        _filtered.length;
    return LatLng(avgLat, avgLng);
  }

  double _mapZoom() => _filtered.length <= 1 ? 15 : 12.5;

  void _clearSelection() => setState(() => _selectedSpot = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // ── 地図（フルスクリーン）──────────────────────────
                _filtered.isEmpty
                    ? _buildEmptyMapPlaceholder()
                    : FlutterMap(
                        key: ValueKey(
                          _filtered.map((s) => s.id).join('_'),
                        ),
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter(),
                          initialZoom: _mapZoom(),
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                          onTap: (tapPos, point) => _clearSelection(),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.noesis.noesis_flutter',
                          ),
                          MarkerLayer(
                            markers: [
                              ..._filtered.map(
                                (spot) => Marker(
                                  point: LatLng(
                                    spot.latitude!,
                                    spot.longitude!,
                                  ),
                                  width: 56,
                                  height: 72,
                                  alignment: Alignment.bottomCenter,
                                  child: _PinMarker(
                                    spot: spot,
                                    isSelected: _selectedSpot?.id == spot.id,
                                    onTap: () {
                                      setState(() => _selectedSpot = spot);
                                      _mapController.move(
                                        LatLng(spot.latitude!, spot.longitude!),
                                        _mapController.camera.zoom
                                            .clamp(13, 18),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 28,
                                  height: 28,
                                  child: const _CurrentLocationMarker(),
                                ),
                            ],
                          ),
                        ],
                      ),

                // ── 上部フィルターバー ──────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(context),
                ),

                // ── フィルターパネル（展開時） ──────────────────
                if (_showFilterPanel)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFilterPanel(context),
                  ),

                // ── 右側FABボタン群 ──────────────────────────
                Positioned(
                  right: 12,
                  bottom: _selectedSpot != null ? 220 : 24,
                  child: _buildFabColumn(),
                ),

                // ── 選択スポットカード（下部） ──────────────────
                if (_selectedSpot != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildSpotCard(context, _selectedSpot!),
                  ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('スポットマップ'),
      actions: [
        IconButton(
          onPressed: _saveCurrentFilter,
          icon: const Icon(Icons.bookmark_add_outlined),
          tooltip: 'フィルタを保存',
        ),
        IconButton(
          onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
          icon: Icon(
            _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
          ),
          tooltip: 'フィルタ',
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 56, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 検索バー
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '名前・ジャンル・タグで検索',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _activePresetId = null);
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (_) {
                  setState(() => _activePresetId = null);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(height: 8),
            // プリセット & ジャンルチップ（横スクロール）
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final preset in _builtInPresets) ...[
                    _buildPresetChip(preset),
                    const SizedBox(width: 6),
                  ],
                  for (final preset in _savedFilters) ...[
                    _buildPresetChip(preset, deletable: true),
                    const SizedBox(width: 6),
                  ],
                  if (_genres().isNotEmpty) ...[
                    Container(
                      height: 20,
                      width: 1,
                      color: theme.colorScheme.outlineVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    for (final genre in _genres()) ...[
                      _buildSmallFilterChip(
                        genre,
                        selected: _genre == genre,
                        onTap: () {
                          setState(() {
                            _genre = _genre == genre ? null : genre;
                            _activePresetId = null;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 件数バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_filtered.length} 件表示中',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(SpotMapFilterPreset preset, {bool deletable = false}) {
    final isActive = _activePresetId == preset.id;
    return GestureDetector(
      onLongPress: deletable ? () => _deleteSavedFilter(preset) : null,
      child: FilterChip(
        label: Text(preset.name),
        selected: isActive,
        onSelected: (_) => _applyPreset(preset),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        selectedColor: AppPalette.archive.withValues(alpha: 0.2),
        checkmarkColor: AppPalette.archive,
      ),
    );
  }

  Widget _buildSmallFilterChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      selectedColor: AppPalette.reading.withValues(alpha: 0.2),
      checkmarkColor: AppPalette.reading,
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showFilterPanel = false),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.topRight,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          right: 12,
        ),
        child: GestureDetector(
          onTap: () {}, // パネル内タップを貫通させない
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'フィルタ',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _showFilterPanel = false),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('スコアフィルタ'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('会話向き 4+'),
                      selected: _minConversationScore == 4,
                      onSelected: (_) {
                        setState(() {
                          _minConversationScore =
                              _minConversationScore == 4 ? null : 4;
                          _activePresetId = null;
                        });
                        _applyFilters();
                      },
                    ),
                    FilterChip(
                      label: const Text('作業向き 4+'),
                      selected: _minWorkScore == 4,
                      onSelected: (_) {
                        setState(() {
                          _minWorkScore = _minWorkScore == 4 ? null : 4;
                          _activePresetId = null;
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
                if (_tags().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('タグ'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _tags())
                        FilterChip(
                          label: Text(tag),
                          selected: _tag == tag,
                          onSelected: (_) {
                            setState(() {
                              _tag = _tag == tag ? null : tag;
                              _activePresetId = null;
                            });
                            _applyFilters();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFabColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapFab(
          icon: Icons.fit_screen_outlined,
          tooltip: '全体を表示',
          onTap: _fitFilteredBounds,
        ),
        const SizedBox(height: 8),
        _MapFab(
          icon: Icons.my_location_outlined,
          tooltip: '現在地',
          onTap: _moveToCurrentLocation,
        ),
      ],
    );
  }

  Widget _buildSpotCard(BuildContext context, Spot spot) {
    final theme = Theme.of(context);
    final hasMapUrl = (spot.mapUrl ?? '').isNotEmpty;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spot.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if ((spot.summary ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                spot.summary!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if ((spot.genre ?? '').isNotEmpty)
                  _InfoChip(label: spot.genre!),
                if ((spot.area ?? '').isNotEmpty)
                  _InfoChip(label: spot.area!),
                ..._decodeTags(spot.tags).map((tag) => _InfoChip(label: tag)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDetail(spot),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('詳細'),
                  ),
                ),
                if (hasMapUrl) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openInGoogleMaps(spot),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Google Maps'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMapPlaceholder() {
    return Container(
      color: const Color(0xFFE8E3DC),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '地図には、緯度・経度が入っていて「地図に表示する」がオンのスポットだけが出ます。\n各スポット編集画面の「Webリサーチで整理」または「地図情報を補完」を使ってください。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ピンマーカー（旗ピン型）
// ─────────────────────────────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final Spot spot;
  final bool isSelected;
  final VoidCallback onTap;

  const _PinMarker({
    required this.spot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppPalette.archive : AppPalette.reading;
    final size = isSelected ? 44.0 : 34.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              constraints: const BoxConstraints(maxWidth: 110),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                spot.mapLabel ?? spot.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          CustomPaint(
            size: Size(size, size + 10),
            painter: _PinPainter(color: color, selected: isSelected),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  _iconForGenre(spot.genre),
                  color: Colors.white,
                  size: isSelected ? 22 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForGenre(String? genre) {
    if (genre == null) return Icons.place;
    final g = genre.toLowerCase();
    if (g.contains('カフェ') || g.contains('コーヒー')) return Icons.coffee;
    if (g.contains('レストラン') || g.contains('フレンチ') || g.contains('イタリアン')) {
      return Icons.restaurant;
    }
    if (g.contains('居酒屋') || g.contains('バー') || g.contains('酒')) {
      return Icons.local_bar;
    }
    if (g.contains('ラーメン') || g.contains('麺')) return Icons.ramen_dining;
    if (g.contains('寿司') || g.contains('すし')) return Icons.set_meal;
    if (g.contains('観光') || g.contains('名所')) return Icons.photo_camera;
    if (g.contains('公園') || g.contains('自然')) return Icons.park;
    if (g.contains('ホテル') || g.contains('宿')) return Icons.hotel;
    if (g.contains('ショッピング') || g.contains('百貨店')) return Icons.shopping_bag;
    return Icons.place;
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  final bool selected;

  const _PinPainter({required this.color, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.25 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final r = size.width / 2;
    final center = Offset(r, r);

    // 影
    canvas.drawCircle(center.translate(0, 2), r, shadowPaint);
    // 丸い頭部分
    canvas.drawCircle(center, r, paint);
    // 白い縁取り
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // 下向き三角（ピン先）
    final tipPath = ui.Path()
      ..moveTo(r - r * 0.45, size.height - 10)
      ..lineTo(r + r * 0.45, size.height - 10)
      ..lineTo(r, size.height)
      ..close();
    canvas.drawPath(tipPath, paint);
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      old.color != color || old.selected != selected;
}

// ─────────────────────────────────────────────────────────────────────────────
// サブウィジェット
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(Icons.my_location, color: Colors.white, size: 14),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.backgroundWarm,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
