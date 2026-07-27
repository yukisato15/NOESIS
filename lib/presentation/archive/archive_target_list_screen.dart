import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/archive_targets_table.dart';
import '../shared/surface_field.dart';
import 'archive_target_add_screen.dart';
import 'archive_target_detail_screen.dart';

class ArchiveTargetListScreen extends StatefulWidget {
  const ArchiveTargetListScreen({super.key});

  @override
  State<ArchiveTargetListScreen> createState() =>
      _ArchiveTargetListScreenState();
}

class _ArchiveTargetListScreenState extends State<ArchiveTargetListScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();

  List<ArchiveTarget> _allTargets = [];
  List<ArchiveTarget> _filteredTargets = [];
  ArchiveTargetType? _selectedType;
  String? _selectedCategory;
  bool _isLoading = true;
  List<ArchiveTargetType> get _visibleTypes => ArchiveTargetType.values
      .where(
        (type) =>
            type != ArchiveTargetType.publicFigure &&
            type != ArchiveTargetType.place &&
            type != ArchiveTargetType.topic,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    setState(() => _isLoading = true);
    final targets = await _db.archiveTargetsDao.getAllTargets();
    if (!mounted) {
      return;
    }
    setState(() {
      _allTargets = targets
          .where(
            (target) =>
                target.targetType != ArchiveTargetType.topic &&
                target.targetType != ArchiveTargetType.place,
          )
          .toList();
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = _allTargets.where((target) {
      if (_selectedType != null && target.targetType != _selectedType) {
        return false;
      }
      if (_selectedCategory != null && _selectedCategory != target.category) {
        return false;
      }
      if (keyword.isEmpty) {
        return true;
      }
      final bag = [
        target.name,
        target.category ?? '',
        target.summary ?? '',
        target.tags ?? '',
      ].join('\n').toLowerCase();
      return bag.contains(keyword);
    }).toList();

    setState(() {
      _filteredTargets = filtered;
    });
  }

  List<String> _categories() {
    final categories =
        _allTargets
            .map((target) => target.category?.trim() ?? '')
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('知人アーカイブ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ArchiveTargetAddScreen()),
          );
          await _loadTargets();
        },
        backgroundColor: AppPalette.archive,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('知人を追加'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTargets,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SurfaceField(
                    label: '検索',
                    controller: _searchController,
                    hintText: '名前、カテゴリ、概要、タグで検索',
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('すべて'),
                          selected: _selectedType == null,
                          onSelected: (_) {
                            setState(() => _selectedType = null);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final type in _visibleTypes) ...[
                          FilterChip(
                            label: Text(type.label),
                            selected: _selectedType == type,
                            onSelected: (_) {
                              setState(() => _selectedType = type);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  if (_categories().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('カテゴリ未指定含む'),
                            selected: _selectedCategory == null,
                            onSelected: (_) {
                              setState(() => _selectedCategory = null);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                          for (final category in _categories()) ...[
                            FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '${_filteredTargets.length}件',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredTargets.isEmpty)
                    SurfaceCard(
                      child: Text(
                        'まだ知人がありません。知人を追加して記録を始められます。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  for (final target in _filteredTargets) ...[
                    _TargetCard(
                      target: target,
                      onOpen: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ArchiveTargetDetailScreen(targetId: target.id),
                          ),
                        );
                        await _loadTargets();
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  final ArchiveTarget target;
  final VoidCallback onOpen;

  const _TargetCard({required this.target, required this.onOpen});

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
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
    final theme = Theme.of(context);
    final tags = _decodeTags(target.tags);
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.soften(AppPalette.archive, 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    target.targetType.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppPalette.archive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy/MM/dd').format(target.updatedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              target.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((target.category ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                target.category!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
            if ((target.summary ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                target.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.take(5).map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
