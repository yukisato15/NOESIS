import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import 'reading_detail_screen.dart';
import 'reading_add_screen.dart';

enum ReadingSortField { title, reading, createdAt, updatedAt }
enum SortOrder { ascending, descending }

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final AppDatabase _db = AppDatabase();
  List<Entry> _allEntries = [];
  List<Entry> _filteredEntries = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  ReadingSortField _sortField = ReadingSortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _db.entriesDao.getAllReadingNotes();
      if (mounted) {
        setState(() {
          _allEntries = entries;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    var filtered = _allEntries;

    // キーワード検索（タイトルと書籍名）
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((entry) {
        final title = entry.title.toLowerCase();
        final reading = (entry.reading ?? '').toLowerCase();
        return title.contains(keyword) || reading.contains(keyword);
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
        case ReadingSortField.title:
          comparison = a.title.compareTo(b.title);
          break;
        case ReadingSortField.reading:
          comparison = (a.reading ?? '').compareTo(b.reading ?? '');
          break;
        case ReadingSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case ReadingSortField.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    setState(() {
      _filteredEntries = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('読書アーカイブ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 検索バー
                      TextField(
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                      const SizedBox(height: 12),
                      // ソートオプション
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ReadingSortField>(
                              value: _sortField,
                              decoration: const InputDecoration(
                                labelText: '並び順',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ReadingSortField.title,
                                  child: Text('タイトル順'),
                                ),
                                DropdownMenuItem(
                                  value: ReadingSortField.reading,
                                  child: Text('書籍名順'),
                                ),
                                DropdownMenuItem(
                                  value: ReadingSortField.createdAt,
                                  child: Text('作成日時'),
                                ),
                                DropdownMenuItem(
                                  value: ReadingSortField.updatedAt,
                                  child: Text('更新日時'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _sortField = value);
                                  _applyFilters();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              _sortOrder == SortOrder.ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            tooltip: _sortOrder == SortOrder.ascending ? '昇順' : '降順',
                            onPressed: () {
                              setState(() {
                                _sortOrder = _sortOrder == SortOrder.ascending
                                    ? SortOrder.descending
                                    : SortOrder.ascending;
                              });
                              _applyFilters();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // フィルターチップス
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // 日付範囲フィルター
                            ActionChip(
                              avatar: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                _dateRange == null ? '日付' : '日付 (選択中)',
                                style: theme.textTheme.bodySmall,
                              ),
                              onPressed: () => _showDateRangePicker(),
                            ),
                            if (_dateRange != null) ...[
                              const SizedBox(width: 8),
                              ActionChip(
                                avatar: const Icon(Icons.clear, size: 18),
                                label: Text(
                                  'クリア',
                                  style: theme.textTheme.bodySmall,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _dateRange = null;
                                  });
                                  _applyFilters();
                                },
                              ),
                            ],
                          ],
                        ),
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
                                _allEntries.isEmpty
                                    ? Icons.menu_book_outlined
                                    : Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.secondary.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _allEntries.isEmpty
                                    ? '読書ノートがありません'
                                    : 'エントリが見つかりません',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary.withOpacity(0.6),
                                ),
                              ),
                              if (_allEntries.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '右下の+ボタンで追加',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            final bookTitle = entry.reading ?? '不明な書籍';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppPalette.soften(
                                    AppPalette.reading,
                                    0.2,
                                  ),
                                  child: Text(
                                    bookTitle.isNotEmpty ? bookTitle[0] : '?',
                                    style: const TextStyle(color: AppPalette.reading),
                                  ),
                                ),
                                title: Text(entry.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookTitle,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.reading,
                                      ),
                                    ),
                                    Text(
                                      entry.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary.withOpacity(0.6),
                                  ),
                                ),
                                isThreeLine: true,
                                onTap: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ReadingDetailScreen(entryId: entry.id),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _loadEntries();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ReadingAddScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadEntries();
          }
        },
        backgroundColor: AppPalette.reading,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
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
