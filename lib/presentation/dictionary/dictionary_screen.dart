import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import 'dictionary_create_screen.dart';
import 'dictionary_archive_settings_screen.dart';
import 'dictionary_entries_screen.dart';
import 'dictionary_entry_detail_screen.dart';
import 'dictionary_settings_screen.dart';
import '../shared/surface_field.dart';

enum SortField { headword, createdAt, updatedAt }
enum SortOrder { ascending, descending }

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen>
    with TickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  TabController? _tabController;
  List<DictionaryDefinition> _dictionaries = [];
  List<DictionaryEntry> _allEntries = [];
  List<DictionaryEntry> _filteredEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  List<String> _selectedTags = [];
  DateTimeRange? _dateRange;
  SortField _sortField = SortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    try {
      debugPrint('[DictionaryScreen] _loadDictionaries: Starting...');
      await _db.ensureDictionaryRecovery();
      debugPrint('[DictionaryScreen] _loadDictionaries: Recovery complete, fetching dictionaries...');
      final result = await _db.dictionariesDao.getAllDictionaries();
      debugPrint('[DictionaryScreen] _loadDictionaries: Complete, found ${result.length} dictionaries');

      if (!mounted) return;

      // Only create new controller if length changed (+1 for "すべて" tab)
      final tabCount = result.isNotEmpty ? result.length + 1 : 0;
      final needsNewController = _tabController == null ||
                                   _tabController!.length != tabCount;

      if (needsNewController) {
        _tabController?.dispose();
        if (result.isNotEmpty) {
          _tabController = TabController(
            length: tabCount,
            vsync: this,
          );
        } else {
          _tabController = null;
        }
      }

      setState(() {
        _dictionaries = result;
        _isLoading = false;
        _errorMessage = null;
      });

      // Load all entries when dictionaries are loaded
      if (result.isNotEmpty) {
        await _loadAllEntries(dictionaries: result);
      }
    } catch (e, stackTrace) {
      debugPrint('[DictionaryScreen] ERROR in _loadDictionaries: $e');
      debugPrint('[DictionaryScreen] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadAllEntries({List<DictionaryDefinition>? dictionaries}) async {
    final targetDictionaries = dictionaries ?? _dictionaries;
    final allEntries = <DictionaryEntry>[];
    for (final dict in targetDictionaries) {
      final entries = await _db.dictionariesDao.getEntries(dict.id);
      allEntries.addAll(entries);
    }

    if (mounted) {
      setState(() {
        _allEntries = allEntries;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    var filtered = _allEntries;

    // キーワード検索
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((entry) {
        return entry.headword.toLowerCase().contains(keyword);
      }).toList();
    }

    // カテゴリフィルター
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((entry) {
        return entry.category == _selectedCategory;
      }).toList();
    }

    // タグフィルター
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((entry) {
        if (entry.tags == null || entry.tags!.isEmpty) return false;
        try {
          final entryTags = (jsonDecode(entry.tags!) as List)
              .map((e) => e.toString())
              .toList();
          return _selectedTags.any((tag) => entryTags.contains(tag));
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // 日付範囲フィルター
    if (_dateRange != null) {
      filtered = filtered.where((entry) {
        return entry.createdAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               entry.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // ソート
    filtered.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case SortField.headword:
          comparison = a.headword.compareTo(b.headword);
          break;
        case SortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortField.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    setState(() {
      _filteredEntries = filtered;
    });
  }

  Future<void> _showFilterSheet() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final dateLabel = _dateRange == null
            ? '未設定'
            : '${_dateRange!.start.year}/${_dateRange!.start.month}/${_dateRange!.start.day} - ${_dateRange!.end.year}/${_dateRange!.end.month}/${_dateRange!.end.day}';
        final hasFilters =
            _selectedCategory != null || _selectedTags.isNotEmpty || _dateRange != null;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'フィルタと並び替え',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '並び順',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<SortField>(
                  segments: const [
                    ButtonSegment(
                      value: SortField.headword,
                      label: Text('名前'),
                    ),
                    ButtonSegment(
                      value: SortField.createdAt,
                      label: Text('作成日'),
                    ),
                    ButtonSegment(
                      value: SortField.updatedAt,
                      label: Text('更新日'),
                    ),
                  ],
                  selected: {_sortField},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() {
                      _sortField = selection.first;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<SortOrder>(
                  segments: const [
                    ButtonSegment(
                      value: SortOrder.descending,
                      label: Text('新しい順'),
                    ),
                    ButtonSegment(
                      value: SortOrder.ascending,
                      label: Text('古い順'),
                    ),
                  ],
                  selected: {_sortOrder},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() {
                      _sortOrder = selection.first;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '絞り込み',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'カテゴリ',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCategory ?? '未設定',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _showCategoryFilter();
                        },
                        child: const Text('選択'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'タグ',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTags.isEmpty
                                  ? '未設定'
                                  : '${_selectedTags.length}件',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _showTagFilter();
                        },
                        child: const Text('選択'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '日付',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _showDateRangePicker();
                        },
                        child: const Text('選択'),
                      ),
                      if (_dateRange != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _dateRange = null;
                            });
                            _applyFilters();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('クリア'),
                        ),
                    ],
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedTags.clear();
                        _dateRange = null;
                      });
                      _applyFilters();
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('すべてクリア'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('辞書アーカイブ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('辞書アーカイブ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  '読み込みに失敗しました',
                  style: theme.textTheme.titleMedium,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'エラー: $_errorMessage',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_dictionaries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('辞書アーカイブ')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 80,
                color: theme.colorScheme.secondary.withOpacity(0.3),
              ),
              const SizedBox(height: 24),
              Text(
                '辞書がありません',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'dictionary_add_empty',
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DictionaryCreateScreen()),
            );
            if (result == true && mounted) {
              await _loadDictionaries();
            }
          },
          backgroundColor: AppPalette.dictionaryGeneral,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('辞書を追加'),
        ),
      );
    }

    final tabController = _tabController;
    if (tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('辞書アーカイブ'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DictionaryArchiveSettingsScreen(
                    database: _db,
                  ),
                ),
              );
              if (mounted) {
                await _loadDictionaries();
              }
            },
            child: const Text('設定'),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DictionaryCreateScreen()),
              );
              if (result == true && mounted) {
                await _loadDictionaries();
              }
            },
            child: const Text('辞書を追加'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppPalette.dictionaryGeneral,
              labelColor: AppPalette.dictionaryGeneral,
              unselectedLabelColor: theme.colorScheme.secondary.withOpacity(0.6),
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.normal,
              ),
              indicatorWeight: 3,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.grid_view, size: 18),
                      SizedBox(width: 8),
                      Text('すべて'),
                    ],
                  ),
                ),
                ..._dictionaries.map((dict) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dict.isWork ? Icons.pending_actions : Icons.menu_book,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(dict.name),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildAllEntriesView(theme),
          ..._dictionaries.map((dict) {
            return DictionaryEntriesScreen(
              key: ValueKey('dict_${dict.id}'),
              dictionaryId: dict.id,
              database: _db,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAllEntriesView(ThemeData theme) {
    return Column(
      children: [
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '検索',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _showFilterSheet,
                    child: const Text('フィルタ'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // エントリリスト
        Expanded(
          child: _filteredEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: theme.colorScheme.secondary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'エントリが見つかりません',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.secondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    final dict = _dictionaries.firstWhere(
                      (d) => d.id == entry.dictionaryId,
                      orElse: () => _dictionaries.first,
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: SelectableContextText(
                          text: entry.headword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableContextText(
                              text: dict.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppPalette.dictionaryGeneral
                                    .withOpacity(0.7),
                              ),
                            ),
                            if (entry.category != null &&
                                entry.category!.isNotEmpty)
                              SelectableContextText(
                                text: 'カテゴリ: ${entry.category}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: Text(
                          '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary.withOpacity(0.6),
                          ),
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DictionaryEntryDetailScreen(
                                dictionaryId: entry.dictionaryId,
                                entryId: entry.id,
                                database: _db,
                              ),
                            ),
                          );
                          _loadAllEntries();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showCategoryFilter() async {
    final categories = _allEntries
        .map((e) => e.category)
        .where((c) => c != null && c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('カテゴリを選択'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('すべて'),
            ),
            ...categories.map((category) {
              return SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(category),
                child: Text(category!),
              );
            }),
          ],
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedCategory = selected;
    });
    _applyFilters();
  }

  Future<void> _showTagFilter() async {
    final allTags = <String>{};
    for (final entry in _allEntries) {
      if (entry.tags != null && entry.tags!.isNotEmpty) {
        try {
          final tags = (jsonDecode(entry.tags!) as List)
              .map((e) => e.toString())
              .toList();
          allTags.addAll(tags);
        } catch (_) {}
      }
    }
    final tagList = allTags.toList()..sort();

    if (!mounted) return;

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        final selectedTags = List<String>.from(_selectedTags);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('タグを選択'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: tagList.map((tag) {
                    return CheckboxListTile(
                      value: selectedTags.contains(tag),
                      title: Text(tag),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedTags),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedTags = selected;
    });
    _applyFilters();
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateRange = picked;
    });
    _applyFilters();
  }
}
