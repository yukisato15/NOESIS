import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../shared/surface_field.dart';
import 'spot_detail_screen.dart';
import 'spot_edit_screen.dart';
import 'spot_map_screen.dart';
import 'spot_photo_entry_screen.dart';

class SpotListScreen extends StatefulWidget {
  const SpotListScreen({super.key});

  @override
  State<SpotListScreen> createState() => _SpotListScreenState();
}

class _SpotListScreenState extends State<SpotListScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();
  List<Spot> _spots = [];
  List<Spot> _filtered = [];
  String? _genre;
  String? _area;
  bool _isLoading = true;

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
    final spots = await _db.spotsDao.getAllSpots();
    if (!mounted) return;
    setState(() {
      _spots = spots;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = _spots.where((spot) {
      if (_genre != null && _genre != spot.genre) return false;
      if (_area != null && _area != spot.area) return false;
      final bag = [
        spot.name,
        spot.genre ?? '',
        spot.area ?? '',
        spot.summary ?? '',
        spot.tags ?? '',
      ].join('\n').toLowerCase();
      return keyword.isEmpty || bag.contains(keyword);
    }).toList();
    setState(() => _filtered = filtered);
  }

  List<String> _values(String? Function(Spot) pick) {
    final values =
        _spots
            .map((s) => (pick(s) ?? '').trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スポットアーカイブ'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SpotMapScreen()));
            },
            icon: const Icon(Icons.map_outlined),
            tooltip: 'スポットマップ',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // カメラで記録ボタン
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SpotPhotoEntryScreen(),
                ),
              );
              await _load();
            },
            backgroundColor: AppPalette.talkingTopic,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('写真で記録'),
          ),
          const SizedBox(height: 10),
          // 手動追加ボタン
          FloatingActionButton.extended(
            heroTag: 'manual',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SpotEditScreen()),
              );
              await _load();
            },
            backgroundColor: AppPalette.archive,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('スポットを追加'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SurfaceField(
                    label: '検索',
                    controller: _searchController,
                    hintText: '名前、ジャンル、エリア、タグ',
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('すべてのジャンル'),
                          selected: _genre == null,
                          onSelected: (_) {
                            setState(() => _genre = null);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final value in _values((s) => s.genre)) ...[
                          FilterChip(
                            label: Text(value),
                            selected: _genre == value,
                            onSelected: (_) {
                              setState(() => _genre = value);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('すべてのエリア'),
                          selected: _area == null,
                          onSelected: (_) {
                            setState(() => _area = null);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final value in _values((s) => s.area)) ...[
                          FilterChip(
                            label: Text(value),
                            selected: _area == value,
                            onSelected: (_) {
                              setState(() => _area = value);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    const SurfaceCard(
                      child: Text('まだスポットがありません。お気に入りの場所を追加できます。'),
                    ),
                  for (final spot in _filtered) ...[
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpotDetailScreen(spotId: spot.id),
                          ),
                        );
                        await _load();
                      },
                      child: SurfaceCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if ((spot.summary ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(spot.summary!),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if ((spot.genre ?? '').isNotEmpty)
                                  _Chip(label: spot.genre!),
                                if ((spot.area ?? '').isNotEmpty)
                                  _Chip(label: spot.area!),
                                _Chip(label: '作業${spot.workFriendly ?? '-'}'),
                                _Chip(
                                  label:
                                      '会話${spot.conversationFriendly ?? '-'}',
                                ),
                                ..._decodeTags(
                                  spot.tags,
                                ).take(2).map((e) => _Chip(label: e)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.soften(AppPalette.archive, 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
