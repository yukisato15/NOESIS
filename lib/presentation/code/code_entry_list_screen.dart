import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/tables/code_entries_table.dart';
import 'code_entry_add_screen.dart';
import 'code_entry_detail_screen.dart';

/// コードエントリーリスト画面
class CodeEntryListScreen extends ConsumerStatefulWidget {
  const CodeEntryListScreen({super.key});

  @override
  ConsumerState<CodeEntryListScreen> createState() =>
      _CodeEntryListScreenState();
}

class _CodeEntryListScreenState extends ConsumerState<CodeEntryListScreen> {
  List<CodeEntry> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  CodeEntryType? _filterType;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<CodeEntry> entries;

      if (_searchQuery.isNotEmpty) {
        entries = await _db.codeEntriesDao.searchCodeEntries(_searchQuery);
      } else if (_filterType != null) {
        entries = await _db.codeEntriesDao.getCodeEntriesByType(_filterType!);
      } else {
        entries = await _db.codeEntriesDao.getAllCodeEntries();
      }

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _navigateToAddScreen() async {
    final result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => const CodeEntryAddScreen(),
      ),
    );

    if (result != null) {
      _loadEntries();
    }
  }

  Future<void> _navigateToDetailScreen(int entryId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CodeEntryDetailScreen(entryId: entryId),
      ),
    );
    _loadEntries();
  }

  String _getEntryTypeLabel(CodeEntryType type) {
    switch (type) {
      case CodeEntryType.whole:
        return '全体';
      case CodeEntryType.function:
        return '関数';
      case CodeEntryType.block:
        return 'ブロック';
    }
  }

  IconData _getEntryTypeIcon(CodeEntryType type) {
    switch (type) {
      case CodeEntryType.whole:
        return Icons.code;
      case CodeEntryType.function:
        return Icons.functions;
      case CodeEntryType.block:
        return Icons.view_compact;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ITコード学習'),
        actions: [
          PopupMenuButton<CodeEntryType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'タイプでフィルタ',
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
              _loadEntries();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('すべて'),
              ),
              PopupMenuItem(
                value: CodeEntryType.whole,
                child: Row(
                  children: [
                    const Icon(Icons.code, size: 16),
                    const SizedBox(width: 8),
                    Text(_getEntryTypeLabel(CodeEntryType.whole)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CodeEntryType.function,
                child: Row(
                  children: [
                    const Icon(Icons.functions, size: 16),
                    const SizedBox(width: 8),
                    Text(_getEntryTypeLabel(CodeEntryType.function)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: CodeEntryType.block,
                child: Row(
                  children: [
                    const Icon(Icons.view_compact, size: 16),
                    const SizedBox(width: 8),
                    Text(_getEntryTypeLabel(CodeEntryType.block)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'コード、タイトル、言語で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadEntries();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _loadEntries();
              },
            ),
          ),

          // フィルタ表示
          if (_filterType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    avatar: Icon(
                      _getEntryTypeIcon(_filterType!),
                      size: 16,
                    ),
                    label: Text(_getEntryTypeLabel(_filterType!)),
                    onDeleted: () {
                      setState(() {
                        _filterType = null;
                      });
                      _loadEntries();
                    },
                  ),
                ],
              ),
            ),

          // リスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.code_off,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'コードエントリーがありません',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _navigateToDetailScreen(entry.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getEntryTypeIcon(entry.entryType),
                                          size: 20,
                                          color: AppPalette.code,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 言語タグ
                                    if (entry.language != null) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppPalette.code.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              entry.language!,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: AppPalette.code,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // コードプレビュー
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        entry.code,
                                        style: const TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 12,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // 機能説明
                                    if (entry.capabilities != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.capabilities!,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],

                                    // 日時
                                    const SizedBox(height: 8),
                                    Text(
                                      '${entry.updatedAt.year}/${entry.updatedAt.month}/${entry.updatedAt.day}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddScreen,
        icon: const Icon(Icons.add),
        label: const Text('コード記録'),
        backgroundColor: AppPalette.code,
      ),
    );
  }
}
