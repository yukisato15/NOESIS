import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/selectable_context_text.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import 'advanced_search_screen.dart';

enum SearchSortField { title, createdAt, updatedAt }
enum SortOrder { ascending, descending }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AppDatabase _db = AppDatabase();

  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];

  bool _isSearching = false;
  bool _isInitialLoading = true;

  // フィルタ・ソート
  SearchSortField _sortField = SearchSortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;
  String? _selectedCategory;
  List<String> _selectedTags = [];
  DateTimeRange? _dateRange;
  Set<String> _allCategories = {};
  Set<String> _allTags = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      _allResults = [];
      _allCategories = {};
      _allTags = {};

      // 辞書検索
      final dictEntries = await _db.entriesDao.getAllDictionaryEntries();
      for (final entry in dictEntries) {
        _allResults.add({
          'id': 'dict_${entry.id}',
          'type': 'dictionary',
          'title': entry.title,
          'body': entry.body,
          'category': null,
          'tags': null,
          'createdAt': entry.createdAt,
        });
      }

      // 読書検索
      final readingEntries = await _db.entriesDao.getAllReadingNotes();
      for (final entry in readingEntries) {
        _allResults.add({
          'id': 'reading_${entry.id}',
          'type': 'reading',
          'title': entry.title,
          'body': entry.body,
          'category': null,
          'tags': null,
          'createdAt': entry.createdAt,
        });
      }

      // 概念辞書検索
      final allConceptDicts = await _db.select(_db.conceptDictionaries).get();
      for (final concept in allConceptDicts) {
        if (concept.category != null) _allCategories.add(concept.category!);
        if (concept.tags != null) {
          try {
            final tags = (jsonDecode(concept.tags!) as List).cast<String>();
            _allTags.addAll(tags);
          } catch (_) {}
        }
        _allResults.add({
          'id': 'concept_${concept.id}',
          'type': 'concept_dictionary',
          'title': concept.title,
          'body': concept.body,
          'category': concept.category,
          'tags': concept.tags,
          'createdAt': concept.createdAt,
        });
      }

      // 概念メモ検索
      final conceptMemos = await _db.conceptMemosDao.getAllConceptMemos();
      for (final memo in conceptMemos) {
        _allResults.add({
          'id': 'concept_memo_${memo.id}',
          'type': 'concept_memo',
          'title': memo.title ?? '',
          'body': memo.content,
          'category': null,
          'tags': null,
          'createdAt': memo.createdAt,
        });
      }

      // 日常メモ検索
      final dailyMemos = await _db.dailyMemosDao.getAllDailyMemos();
      for (final memo in dailyMemos) {
        if (memo.category != null) _allCategories.add(memo.category!);
        if (memo.tags != null) {
          try {
            final tags = (jsonDecode(memo.tags!) as List).cast<String>();
            _allTags.addAll(tags);
          } catch (_) {}
        }
        _allResults.add({
          'id': 'daily_${memo.id}',
          'type': 'daily',
          'title': memo.title ?? '',
          'body': memo.content,
          'category': memo.category,
          'tags': memo.tags,
          'createdAt': memo.createdAt,
        });
      }

      _applyFiltersAndSort();

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _performSearch(String query) {
    // 検索はフィルター処理に統合
    // SchedulerBinding.addPostFrameCallbackを使用してビルド完了後に実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyFiltersAndSort();
      }
    });
  }

  void _applyFiltersAndSort() {
    if (!mounted) return;

    var filtered = List<Map<String, dynamic>>.from(_allResults);

    // キーワード検索
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((item) {
        final title = (item['title'] as String).toLowerCase();
        final body = (item['body'] as String).toLowerCase();
        return title.contains(keyword) || body.contains(keyword);
      }).toList();
    }

    // カテゴリフィルタ
    if (_selectedCategory != null) {
      filtered = filtered.where((item) {
        return item['category'] == _selectedCategory;
      }).toList();
    }

    // タグフィルタ
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((item) {
        final tagsJson = item['tags'] as String?;
        if (tagsJson == null) return false;
        try {
          final tags = (jsonDecode(tagsJson) as List).cast<String>();
          return _selectedTags.any((tag) => tags.contains(tag));
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // 日付フィルタ
    if (_dateRange != null) {
      filtered = filtered.where((item) {
        final createdAt = item['createdAt'] as DateTime?;
        if (createdAt == null) return false;
        return createdAt.isAfter(_dateRange!.start) &&
            createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // ソート
    filtered.sort((a, b) {
      int result;
      switch (_sortField) {
        case SearchSortField.title:
          result = (a['title'] as String).compareTo(b['title'] as String);
          break;
        case SearchSortField.createdAt:
        case SearchSortField.updatedAt:
          final dateA = a['createdAt'] as DateTime?;
          final dateB = b['createdAt'] as DateTime?;
          if (dateA == null || dateB == null) return 0;
          result = dateA.compareTo(dateB);
          break;
      }
      return _sortOrder == SortOrder.ascending ? result : -result;
    });

    if (mounted) {
      setState(() {
        _filteredResults = filtered;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _applyFiltersAndSort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdvancedSearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI検索'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '全アーカイブを検索...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    _performSearch(value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // ソート
                        DropdownButton<SearchSortField>(
                          value: _sortField,
                          items: const [
                            DropdownMenuItem(
                              value: SearchSortField.title,
                              child: Text('名前順'),
                            ),
                            DropdownMenuItem(
                              value: SearchSortField.createdAt,
                              child: Text('作成日時'),
                            ),
                            DropdownMenuItem(
                              value: SearchSortField.updatedAt,
                              child: Text('更新日時'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortField = value);
                              _applyFiltersAndSort();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _sortOrder == SortOrder.ascending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                          onPressed: () {
                            setState(() {
                              _sortOrder = _sortOrder == SortOrder.ascending
                                  ? SortOrder.descending
                                  : SortOrder.ascending;
                            });
                            _applyFiltersAndSort();
                          },
                        ),
                        const SizedBox(width: 8),
                        // カテゴリフィルタ
                        if (_allCategories.isNotEmpty)
                          DropdownButton<String?>(
                            value: _selectedCategory,
                            hint: const Text('カテゴリ'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('すべて'),
                              ),
                              ..._allCategories.map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                              _applyFiltersAndSort();
                            },
                          ),
                        const SizedBox(width: 8),
                        // 日付フィルタ
                        ActionChip(
                          label: Text(_dateRange == null
                              ? '日付'
                              : DateFormat('M/d').format(_dateRange!.start)),
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          onPressed: _selectDateRange,
                        ),
                        if (_dateRange != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              setState(() => _dateRange = null);
                              _applyFiltersAndSort();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                // タグチップ
                if (_allTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          _applyFiltersAndSort();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (_isInitialLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredResults.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '結果が見つかりませんでした',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filteredResults.length,
                itemBuilder: (context, index) {
                  return _ResultTile(item: _filteredResults[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ResultTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final title = item['title'] as String;
    final body = item['body'] as String;
    final createdAt = item['createdAt'] as DateTime?;
    final category = item['category'] as String?;

    Color color;
    IconData icon;
    String typeLabel;

    switch (type) {
      case 'dictionary':
        color = AppPalette.dictionaryGeneral;
        icon = Icons.book;
        typeLabel = '辞書';
        break;
      case 'reading':
        color = AppPalette.reading;
        icon = Icons.menu_book;
        typeLabel = '読書';
        break;
      case 'concept_dictionary':
        color = AppPalette.thinking;
        icon = Icons.auto_stories;
        typeLabel = '概念辞書';
        break;
      case 'concept_memo':
        color = AppPalette.thinking;
        icon = Icons.lightbulb;
        typeLabel = '概念メモ';
        break;
      case 'daily':
        color = AppPalette.daily;
        icon = Icons.note;
        typeLabel = '日常メモ';
        break;
      default:
        color = Colors.grey;
        icon = Icons.article;
        typeLabel = '';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: SelectableContextText(
          text: title.isEmpty ? '無題' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category != null) ...[
              SelectableContextText(
                text: category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
            ],
            SelectableContextText(
              text: body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  typeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                ),
                if (createdAt != null) ...[
                  const Text(' • '),
                  Text(
                    DateFormat('yyyy/MM/dd').format(createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: 詳細画面へ遷移
        },
      ),
    );
  }
}
