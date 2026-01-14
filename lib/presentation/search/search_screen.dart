import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/selectable_context_text.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../code/code_entry_detail_screen.dart';
import 'advanced_search_screen.dart';
import 'analysis_screen.dart';

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
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];

  bool _isSearching = false;
  bool _isInitialLoading = true;
  bool _isReloading = false;

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
    _focusNode.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadAllData({bool silent = false}) async {
    setState(() {
      _isInitialLoading = !silent;
      _isReloading = silent;
    });

    try {
      _allResults = [];
      _allCategories = {};
      _allTags = {};

      // 辞書登録ワード検索（新しいDictionaryDefinitionsテーブル）
      final dictDefinitions = await _db.select(_db.dictionaryDefinitions).get();
      for (final def in dictDefinitions) {
        _allResults.add({
          'id': 'dict_def_${def.id}',
          'type': 'dictionary_definition',
          'title': def.name,
          'body': def.description ?? '',
          'category': def.category,
          'tags': null,
          'createdAt': def.createdAt,
          'updatedAt': def.updatedAt,
        });
      }

      // 書籍（読書アーカイブ）
      final books = await _db.booksDao.getAllBooks();
      for (final book in books) {
        if (book.genre != null && book.genre!.isNotEmpty) {
          _allCategories.add(book.genre!);
        }
        _allResults.add({
          'id': 'book_${book.id}',
          'type': 'book',
          'title': book.title,
          'body': book.author,
          'category': book.genre,
          'tags': null,
          'createdAt': book.createdAt,
          'updatedAt': book.updatedAt,
        });
      }

      // 読書メモ（読書アーカイブ）
      final bookTitleById = {
        for (final book in books) book.id: book.title,
      };
      final readingMemos = await _db.readingMemosDao.getAllMemos();
      for (final memo in readingMemos) {
        final memoBody =
            memo.excerptText ?? memo.thoughtText ?? memo.content ?? '';
        _allResults.add({
          'id': 'reading_memo_${memo.id}',
          'type': 'reading_memo',
          'title': memo.sectionTitle?.trim().isNotEmpty == true
              ? memo.sectionTitle!
              : (bookTitleById[memo.bookId] ?? '読書メモ'),
          'body': memoBody,
          'category': null,
          'tags': null,
          'createdAt': memo.createdAt,
          'updatedAt': memo.updatedAt ?? memo.createdAt,
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
          'updatedAt': concept.updatedAt ?? concept.createdAt,
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
          'updatedAt': memo.updatedAt ?? memo.createdAt,
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
          'updatedAt': memo.updatedAt ?? memo.createdAt,
        });
      }

      // ITコード学習検索
      final codeEntries = await _db.codeEntriesDao.getAllCodeEntries();
      for (final entry in codeEntries) {
        if (entry.category != null) _allCategories.add(entry.category!);
        if (entry.tags != null) {
          try {
            final tags = (jsonDecode(entry.tags!) as List).cast<String>();
            _allTags.addAll(tags);
          } catch (_) {}
        }
        _allResults.add({
          'id': 'code_${entry.id}',
          'type': 'code',
          'title': entry.title,
          'body': entry.code,
          'category': entry.category,
          'tags': entry.tags,
          'createdAt': entry.createdAt,
          'updatedAt': entry.updatedAt,
        });
      }

      _applyFiltersAndSort();

      setState(() {
        _isInitialLoading = false;
        _isReloading = false;
      });
    } catch (e) {
      setState(() {
        _isInitialLoading = false;
        _isReloading = false;
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
          final dateA = a['createdAt'] as DateTime?;
          final dateB = b['createdAt'] as DateTime?;
          if (dateA == null || dateB == null) return 0;
          result = dateA.compareTo(dateB);
          break;
        case SearchSortField.updatedAt:
          final dateA = a['updatedAt'] as DateTime?;
          final dateB = b['updatedAt'] as DateTime?;
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

  Future<void> _openTagPicker() async {
    if (_allTags.isEmpty) {
      return;
    }

    final controller = TextEditingController();
    final selected = [..._selectedTags];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyword = controller.text.trim().toLowerCase();
            final tags = _allTags
                .where(
                  (tag) => keyword.isEmpty || tag.toLowerCase().contains(keyword),
                )
                .toList()
              ..sort();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            'タグを選択',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    setSheetState(selected.clear);
                                  },
                            child: const Text('全解除'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: controller,
                        onChanged: (_) => setSheetState(() {}),
                        decoration: InputDecoration(
                          hintText: 'タグを検索',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    controller.clear();
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final isSelected = selected.contains(tag);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(tag),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(tag);
                                } else {
                                  selected.remove(tag);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('完了'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.dispose();
    setState(() {
      _selectedTags = selected;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索と分析'),
        actions: [
          IconButton(
            icon: _isReloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isReloading ? null : () => _loadAllData(silent: true),
            tooltip: '更新',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnalysisScreen(),
                ),
              );
            },
            tooltip: '分析',
          ),
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
      body: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _loadAllData(silent: true);
          }
        },
        child: Column(
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'タグ',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openTagPicker,
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('選択'),
                      ),
                    ],
                  ),
                  if (_selectedTags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _selectedTags
                          .map(
                            (tag) => InputChip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _selectedTags.remove(tag);
                                });
                                _applyFiltersAndSort();
                              },
                            ),
                          )
                          .toList(),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'タグ未選択',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
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
                child: RefreshIndicator(
                  onRefresh: () => _loadAllData(silent: true),
                  child: ListView.builder(
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      return _ResultTile(
                        item: _filteredResults[index],
                        onTap: _navigateToDetail,
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> result) {
    final type = result['type'] as String;
    final id = result['id'] as String;

    // IDからエンティティIDを抽出（例: "code_123" -> 123）
    final entityId = int.tryParse(id.split('_').last);
    if (entityId == null) return;

    switch (type) {
      case 'code':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CodeEntryDetailScreen(entryId: entityId),
          ),
        ).then((_) => _loadAllData(silent: true));
        break;
      // 他のタイプは今後実装
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('詳細画面は未実装です')),
        );
    }
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onTap;

  const _ResultTile({
    required this.item,
    required this.onTap,
  });

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
      case 'dictionary_definition':
        color = AppPalette.dictionaryGeneral;
        icon = Icons.book;
        typeLabel = '辞書登録ワード';
        break;
      case 'book':
        color = AppPalette.reading;
        icon = Icons.auto_stories;
        typeLabel = '書籍';
        break;
      case 'reading_memo':
        color = AppPalette.reading;
        icon = Icons.notes;
        typeLabel = '読書メモ';
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
      case 'code':
        color = AppPalette.code;
        icon = Icons.code;
        typeLabel = 'ITコード学習';
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
          onTap(item);
        },
      ),
    );
  }
}
