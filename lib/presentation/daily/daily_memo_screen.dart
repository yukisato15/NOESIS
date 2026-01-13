import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import 'daily_memo_detail_screen.dart';
import 'daily_memo_add_screen.dart';
import 'package:intl/intl.dart';
import '../shared/surface_field.dart';

enum DailyMemoSortField { title, createdAt, updatedAt }
enum SortOrder { ascending, descending }

class DailyMemoScreen extends ConsumerStatefulWidget {
  const DailyMemoScreen({super.key});

  @override
  ConsumerState<DailyMemoScreen> createState() => _DailyMemoScreenState();
}

class _DailyMemoScreenState extends ConsumerState<DailyMemoScreen> {
  final AppDatabase _db = AppDatabase();
  List<DailyMemo> _allMemos = [];
  List<DailyMemo> _filteredMemos = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  DailyMemoSortField _sortField = DailyMemoSortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    try {
      final memos = await _db.dailyMemosDao.getAllDailyMemos();
      if (mounted) {
        setState(() {
          _allMemos = memos;
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
    var filtered = _allMemos;

    // キーワード検索（タイトルとコンテンツ）
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((memo) {
        final title = (memo.title ?? '').toLowerCase();
        final content = memo.content.toLowerCase();
        return title.contains(keyword) || content.contains(keyword);
      }).toList();
    }

    // 日付範囲フィルター
    if (_dateRange != null) {
      filtered = filtered.where((memo) {
        return memo.createdAt.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               memo.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // ソート
    filtered.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case DailyMemoSortField.title:
          comparison = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case DailyMemoSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case DailyMemoSortField.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    setState(() {
      _filteredMemos = filtered;
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
            : '${DateFormat('yyyy/MM/dd').format(_dateRange!.start)} - ${DateFormat('yyyy/MM/dd').format(_dateRange!.end)}';
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
                SegmentedButton<DailyMemoSortField>(
                  segments: const [
                    ButtonSegment(
                      value: DailyMemoSortField.title,
                      label: Text('タイトル'),
                    ),
                    ButtonSegment(
                      value: DailyMemoSortField.createdAt,
                      label: Text('作成日'),
                    ),
                    ButtonSegment(
                      value: DailyMemoSortField.updatedAt,
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
                  '日付',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('日常メモアーカイブ'),
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
                // メモリスト
                Expanded(
                  child: _filteredMemos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _allMemos.isEmpty
                                    ? Icons.note_outlined
                                    : Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.secondary.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _allMemos.isEmpty
                                    ? '日常メモがありません'
                                    : 'メモが見つかりません',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary.withOpacity(0.6),
                                ),
                              ),
                              if (_allMemos.isEmpty) ...[
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
                          itemCount: _filteredMemos.length,
                          itemBuilder: (context, index) {
                            final memo = _filteredMemos[index];
                            final dateFormat = DateFormat('MM/dd HH:mm');
                            final date = dateFormat.format(memo.createdAt);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppPalette.soften(
                                    AppPalette.daily,
                                    0.2,
                                  ),
                                  child: const Icon(
                                    Icons.note,
                                    color: AppPalette.daily,
                                  ),
                                ),
                                title: SelectableContextText(
                                  text: memo.title ?? '無題',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    SelectableContextText(
                                      text: memo.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DailyMemoDetailScreen(memoId: memo.id),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _loadMemos();
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
              builder: (_) => const DailyMemoAddScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadMemos();
          }
        },
        backgroundColor: AppPalette.daily,
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
