import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import 'reading_memo_add_screen.dart';
import 'reading_memo_detail_screen.dart';

/// 本の詳細画面
/// 書籍のメタデータと、その書籍に紐づく読書メモの一覧を表示
class BookDetailScreen extends ConsumerStatefulWidget {
  final int bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  final AppDatabase _db = AppDatabase();
  Book? _book;
  List<ReadingMemo> _memos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final book = await _db.booksDao.getBookById(widget.bookId);
      final memos = await _db.readingMemosDao.getMemosByBookId(widget.bookId);

      if (mounted) {
        setState(() {
          _book = book;
          _memos = memos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('書籍を削除'),
        content: const Text(
          'この書籍とすべての読書メモを削除しますか？\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // メモを削除
      for (final memo in _memos) {
        await _db.readingMemosDao.deleteMemo(memo.id);
      }
      // 書籍を削除
      await _db.booksDao.deleteBook(widget.bookId);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('書籍を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteMemo(ReadingMemo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _db.readingMemosDao.deleteMemo(memo.id);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('書籍詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('書籍詳細')),
        body: const Center(
          child: Text('書籍が見つかりませんでした'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteBook,
            tooltip: '書籍を削除',
          ),
        ],
      ),
      body: Column(
        children: [
          // 書籍情報カード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // タイトル・著者
                SelectableContextText(
                  text: _book!.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SelectableContextText(
                        text: _book!.author,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_book!.genre != null && _book!.genre!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_book!.genre!),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const SizedBox(height: 16),

                // 詳細情報（折りたたみ可能）
                ExpansionTile(
                  title: const Text('詳細情報を表示'),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    if (_book!.publisher != null &&
                        _book!.publisher!.isNotEmpty) ...[
                      _buildInfoRow('出版社', _book!.publisher!),
                    ],
                    if (_book!.publishedDate != null &&
                        _book!.publishedDate!.isNotEmpty) ...[
                      _buildInfoRow('出版日', _book!.publishedDate!),
                    ],
                    if (_book!.isbn != null && _book!.isbn!.isNotEmpty) ...[
                      _buildInfoRow('ISBN', _book!.isbn!),
                    ],
                    if (_book!.synopsis != null &&
                        _book!.synopsis!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'あらすじ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableContextText(
                        text: _book!.synopsis!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_book!.rating != null && _book!.rating!.isNotEmpty) ...[
                      _buildInfoRow('評価', _book!.rating!),
                    ],
                    if (_book!.relatedUrl != null &&
                        _book!.relatedUrl!.isNotEmpty) ...[
                      _buildInfoRow('関連URL', _book!.relatedUrl!, isUrl: true),
                    ],
                    if (_book!.reviewSummary != null &&
                        _book!.reviewSummary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'レビュー要約',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableContextText(
                        text: _book!.reviewSummary!,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // メモ一覧
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '読書メモ (${_memos.length}件)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _memos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 64,
                          color: theme.colorScheme.secondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'メモがありません',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.secondary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '右下のボタンでメモを追加',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _memos.length,
                    itemBuilder: (context, index) {
                      final memo = _memos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReadingMemoDetailScreen(
                                  memoId: memo.id,
                                  bookTitle: _book!.title,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // メタ情報
                                Row(
                                  children: [
                                    if (memo.sectionTitle != null &&
                                        memo.sectionTitle!.isNotEmpty) ...[
                                      Expanded(
                                        child: Text(
                                          memo.sectionTitle!,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: AppPalette.reading,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (memo.pageNumber != null &&
                                        memo.pageNumber!.isNotEmpty) ...[
                                      Chip(
                                        label: Text(
                                          'p.${memo.pageNumber}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      onPressed: () => _deleteMemo(memo),
                                      tooltip: '削除',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // メモ本文
                                SelectableContextText(
                                  text: memo.content ?? memo.thoughtText,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // 作成日時
                                Text(
                                  '${memo.createdAt.year}/${memo.createdAt.month}/${memo.createdAt.day}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.6),
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
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReadingMemoAddScreen(
                bookId: widget.bookId,
                bookTitle: _book!.title,
              ),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        backgroundColor: AppPalette.reading,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('メモを追加'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isUrl
                ? GestureDetector(
                    onTap: () => _launchUrl(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : SelectableContextText(
                    text: value,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URLを開けませんでした: $urlString')),
        );
      }
    }
  }
}
