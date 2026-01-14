import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/ai/ai_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';

enum SearchMode {
  semantic, // AIセマンティック検索
  timeline, // 時系列分析
  conceptMap, // 関連概念マップ
}

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;

  SearchMode _searchMode = SearchMode.semantic; // デフォルトはセマンティック検索

  // 結果データ
  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _semanticResults = [];
  Map<String, dynamic>? _timelineAnalysis;
  Map<String, dynamic>? _conceptMapData;

  // フィルタ条件
  String? _selectedCategory;
  List<String> _selectedTags = [];
  DateTimeRange? _dateRange;
  String? _selectedArchiveType; // dictionary, reading, thinking, daily

  bool _isSearching = false;
  bool _hasSearched = false; // 検索が実行されたかどうか

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // キーボードを閉じる
    _searchFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _hasSearched = false;
      _semanticResults = [];
      _timelineAnalysis = null;
      _conceptMapData = null;
    });

    try {
      // 1. 全データを取得（フィルタ適用）
      await _fetchAllData();

      // 2. 検索モードに応じた処理
      switch (_searchMode) {
        case SearchMode.semantic:
          await _semanticSearch(query);
          break;
        case SearchMode.timeline:
          await _timelineSearch(query);
          break;
        case SearchMode.conceptMap:
          await _conceptMapSearch(query);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('検索に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    }
  }

  Future<void> _fetchAllData() async {
    _allResults = [];

    // 辞書
    if (_selectedArchiveType == null || _selectedArchiveType == 'dictionary') {
      final dictEntries = await _db.entriesDao.getAllDictionaryEntries();
      for (final entry in dictEntries) {
        _allResults.add({
          'id': 'dict_${entry.id}',
          'type': 'dictionary',
          'title': entry.title,
          'body': entry.body,
          'reading': entry.reading,
          'createdAt': entry.createdAt,
        });
      }
    }

    // 読書
    if (_selectedArchiveType == null || _selectedArchiveType == 'reading') {
      final readingEntries = await _db.entriesDao.getAllReadingNotes();
      for (final entry in readingEntries) {
        _allResults.add({
          'id': 'reading_${entry.id}',
          'type': 'reading',
          'title': entry.title,
          'body': entry.body,
          'createdAt': entry.createdAt,
        });
      }
    }

    // 概念辞書
    if (_selectedArchiveType == null || _selectedArchiveType == 'thinking') {
      final conceptDicts = await (_db.select(_db.conceptDictionaries)).get();
      for (final concept in conceptDicts) {
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
    }

    // 日常メモ
    if (_selectedArchiveType == null || _selectedArchiveType == 'daily') {
      final dailyMemos = await _db.dailyMemosDao.getAllDailyMemos();
      for (final memo in dailyMemos) {
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
    }

    // フィルタ適用
    _applyFilters();
  }

  void _applyFilters() {
    if (_selectedCategory != null) {
      _allResults = _allResults.where((item) {
        final category = item['category'] as String?;
        return category == _selectedCategory;
      }).toList();
    }

    if (_selectedTags.isNotEmpty) {
      _allResults = _allResults.where((item) {
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

    if (_dateRange != null) {
      _allResults = _allResults.where((item) {
        final createdAt = item['createdAt'] as DateTime?;
        if (createdAt == null) return false;
        return createdAt.isAfter(_dateRange!.start) &&
            createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
  }

  Future<void> _semanticSearch(String query) async {
    if (_allResults.isEmpty) {
      _semanticResults = [];
      return;
    }

    final relatedIds = await _aiClient.semanticSearch(
      query: query,
      corpus: _allResults,
    );

    _semanticResults = _allResults
        .where((item) => relatedIds.contains(item['id']))
        .toList();
  }

  Future<void> _timelineSearch(String query) async {
    if (_allResults.isEmpty) {
      _timelineAnalysis = null;
      return;
    }

    // 日付順にソート
    _allResults.sort((a, b) {
      final dateA = a['createdAt'] as DateTime?;
      final dateB = b['createdAt'] as DateTime?;
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    _timelineAnalysis = await _aiClient.analyzeTimeline(
      theme: query,
      chronologicalItems: _allResults,
    );

    _semanticResults = _allResults;
  }

  Future<void> _conceptMapSearch(String query) async {
    if (_allResults.isEmpty) {
      _conceptMapData = null;
      return;
    }

    // まずセマンティック検索で関連項目を絞る
    final relatedIds = await _aiClient.semanticSearch(
      query: query,
      corpus: _allResults,
    );

    final relatedItems = _allResults
        .where((item) => relatedIds.contains(item['id']))
        .toList();

    if (relatedItems.isEmpty) {
      _conceptMapData = null;
      _semanticResults = [];
      return;
    }

    _conceptMapData = await _aiClient.extractRelatedConcepts(
      searchResults: relatedItems,
    );

    _semanticResults = relatedItems;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('高度な検索'),
      ),
      body: Column(
        children: [
          // 検索バー（検索後は折りたたみ可能）
          if (!_hasSearched) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: '検索キーワード...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 12),
                  // 検索モード選択
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ModeChip(
                          label: 'AI意味検索',
                          icon: Icons.auto_awesome,
                          selected: _searchMode == SearchMode.semantic,
                          onSelected: () =>
                              setState(() => _searchMode = SearchMode.semantic),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: '時系列分析',
                          icon: Icons.timeline,
                          selected: _searchMode == SearchMode.timeline,
                          onSelected: () =>
                              setState(() => _searchMode = SearchMode.timeline),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: '概念マップ',
                          icon: Icons.hub,
                          selected: _searchMode == SearchMode.conceptMap,
                          onSelected: () => setState(
                              () => _searchMode = SearchMode.conceptMap),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? '検索中...' : '検索'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ] else
            // 検索後はコンパクトなヘッダー
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '検索: ${_searchController.text}',
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      setState(() {
                        _hasSearched = false;
                      });
                    },
                    tooltip: '検索条件を変更',
                  ),
                ],
              ),
            ),
          // 結果表示
          Expanded(
            child: _buildResultsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'キーワードを入力して検索開始',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'AI意味検索で関連する内容を見つけよう',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    switch (_searchMode) {
      case SearchMode.semantic:
        return _buildSemanticResults();
      case SearchMode.timeline:
        return _buildTimelineView();
      case SearchMode.conceptMap:
        return _buildConceptMapView();
    }
  }

  Widget _buildSemanticResults() {
    if (_semanticResults.isEmpty) {
      return const Center(
        child: Text('結果が見つかりませんでした'),
      );
    }

    return ListView.builder(
      itemCount: _semanticResults.length,
      itemBuilder: (context, index) {
        final item = _semanticResults[index];
        return _ResultTile(
          item: item,
          onTap: () => _navigateToDetail(item),
        );
      },
    );
  }

  Future<void> _navigateToDetail(Map<String, dynamic> item) async {
    final shouldNavigate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('詳細を表示'),
        content: Text('「${item['title']}」の詳細ページに移動しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('表示'),
          ),
        ],
      ),
    );

    if (shouldNavigate != true || !mounted) return;

    // itemのIDから詳細画面に遷移
    final id = item['id'] as String;
    final type = item['type'] as String;

    // TODO: 各タイプに応じた詳細画面に遷移
    // 現在は未実装なので、Snackbarで通知
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('詳細画面への遷移機能は実装中です (ID: $id, Type: $type)')),
      );
    }
  }

  Widget _buildTimelineView() {
    if (_timelineAnalysis == null) {
      return const Center(child: Text('分析結果がありません'));
    }

    final summary = _timelineAnalysis!['summary'] as String;
    final evolution = _timelineAnalysis!['evolution'] as String;
    final phases = _timelineAnalysis!['phases'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: AppPalette.thinking),
                    const SizedBox(width: 8),
                    Text(
                      '時系列分析',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '要約',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(summary),
                const SizedBox(height: 16),
                Text(
                  '思考の進化',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(evolution),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...phases.map((phase) {
          final period = phase['period'] as String;
          final characteristics = phase['characteristics'] as String;
          final itemIds = (phase['items'] as List).cast<String>();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(characteristics),
                  const SizedBox(height: 12),
                  Text(
                    '該当項目: ${itemIds.length}件',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itemIds.map((itemId) {
                      final relatedItem = _semanticResults.firstWhere(
                        (item) => item['id'] == itemId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (relatedItem.isEmpty) return const SizedBox.shrink();

                      return ActionChip(
                        avatar: const Icon(Icons.article, size: 16),
                        label: Text(
                          relatedItem['title'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _navigateToDetail(relatedItem),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildConceptMapView() {
    if (_conceptMapData == null) {
      return const Center(child: Text('概念マップデータがありません'));
    }

    final concepts = _conceptMapData!['concepts'] as List<dynamic>;
    final relations = _conceptMapData!['relations'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: AppPalette.thinking.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub, color: AppPalette.thinking),
                    const SizedBox(width: 8),
                    Text(
                      '関連概念マップ',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '検出された概念: ${concepts.length}個',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '関係性: ${relations.length}個',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...concepts.map((concept) {
          final label = concept['label'] as String;
          final category = concept['category'] as String;
          final itemIds = (concept['item_ids'] as List).cast<String>();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.thinking,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '関連項目: ${itemIds.length}件',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itemIds.map((itemId) {
                      final relatedItem = _semanticResults.firstWhere(
                        (item) => item['id'] == itemId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (relatedItem.isEmpty) return const SizedBox.shrink();

                      return ActionChip(
                        avatar: const Icon(Icons.article, size: 16),
                        label: Text(
                          relatedItem['title'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _navigateToDetail(relatedItem),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        if (relations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '概念間の関係性',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...relations.map((relation) {
                    final from = relation['from'] as String;
                    final to = relation['to'] as String;
                    final type = relation['type'] as String;

                    final fromConcept = concepts.firstWhere(
                      (c) => c['id'] == from,
                      orElse: () => {'label': from},
                    );
                    final toConcept = concepts.firstWhere(
                      (c) => c['id'] == to,
                      orElse: () => {'label': to},
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              fromConcept['label'] as String,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              type,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Expanded(
                            child: Text(
                              toConcept['label'] as String,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) => onSelected(),
      selectedColor: AppPalette.thinking.withOpacity(0.2),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const _ResultTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String;
    final title = item['title'] as String;
    final body = item['body'] as String;
    final createdAt = item['createdAt'] as DateTime?;

    Color color;
    IconData icon;

    switch (type) {
      case 'dictionary':
        color = AppPalette.dictionaryGeneral;
        icon = Icons.book;
        break;
      case 'reading':
        color = AppPalette.reading;
        icon = Icons.menu_book;
        break;
      case 'concept_dictionary':
      case 'thinking':
        color = AppPalette.thinking;
        icon = Icons.lightbulb;
        break;
      case 'daily':
        color = AppPalette.daily;
        icon = Icons.note;
        break;
      default:
        color = Colors.grey;
        icon = Icons.article;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt != null)
              Text(
                DateFormat('yyyy/MM/dd').format(createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
