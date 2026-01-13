import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import 'book_add_screen.dart';
import 'book_detail_screen.dart';

enum BookSortField { title, author, createdAt }
enum SortOrder { ascending, descending }

/// 読書アーカイブ一覧画面
/// 書籍（本）の一覧を表示し、検索・ソート・フィルター機能を提供
class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  final AppDatabase _db = AppDatabase();
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedGenre;
  BookSortField _sortField = BookSortField.createdAt;
  SortOrder _sortOrder = SortOrder.descending;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await _db.booksDao.getAllBooks();
      if (mounted) {
        setState(() {
          _allBooks = books;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('書籍の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _allBooks;

    // キーワード検索（タイトル・著者・ジャンル・あらすじ）
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      filtered = filtered.where((book) {
        final title = book.title.toLowerCase();
        final author = book.author.toLowerCase();
        final genre = (book.genre ?? '').toLowerCase();
        final synopsis = (book.synopsis ?? '').toLowerCase();
        return title.contains(keyword) ||
            author.contains(keyword) ||
            genre.contains(keyword) ||
            synopsis.contains(keyword);
      }).toList();
    }

    // ジャンルフィルター
    if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
      filtered = filtered.where((book) => book.genre == _selectedGenre).toList();
    }

    // ソート
    filtered.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case BookSortField.title:
          comparison = a.title.compareTo(b.title);
          break;
        case BookSortField.author:
          comparison = a.author.compareTo(b.author);
          break;
        case BookSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    setState(() {
      _filteredBooks = filtered;
    });
  }

  List<String> _getAvailableGenres() {
    final genres = <String>{};
    for (final book in _allBooks) {
      if (book.genre != null && book.genre!.isNotEmpty) {
        genres.add(book.genre!);
      }
    }
    return genres.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('読書アーカイブ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('読書アーカイブについて'),
                  content: const Text(
                    '書籍ごとにメモを管理できます。\n\n'
                    '• 書籍情報はAIで自動補完可能\n'
                    '• メモはLive Textで画像から取り込み可能\n'
                    '• AIキャラクターと対話しながら考察を深められます',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                          hintText: '書名、著者名、ジャンルで検索',
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
                      // ソート・フィルターオプション
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<BookSortField>(
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
                                  value: BookSortField.title,
                                  child: Text('書名順'),
                                ),
                                DropdownMenuItem(
                                  value: BookSortField.author,
                                  child: Text('著者名順'),
                                ),
                                DropdownMenuItem(
                                  value: BookSortField.createdAt,
                                  child: Text('登録日時'),
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
                      // ジャンルフィルター
                      if (_getAvailableGenres().isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('すべて'),
                                selected: _selectedGenre == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedGenre = null;
                                  });
                                  _applyFilters();
                                },
                              ),
                              const SizedBox(width: 8),
                              ..._getAvailableGenres().map((genre) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(genre),
                                    selected: _selectedGenre == genre,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedGenre = selected ? genre : null;
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // 書籍リスト
                Expanded(
                  child: _filteredBooks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _allBooks.isEmpty
                                    ? Icons.menu_book_outlined
                                    : Icons.search_off,
                                size: 64,
                                color: theme.colorScheme.secondary.withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _allBooks.isEmpty
                                    ? '書籍がありません'
                                    : '該当する書籍が見つかりません',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.secondary.withOpacity(0.6),
                                ),
                              ),
                              if (_allBooks.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '右下の + ボタンで本を追加',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredBooks.length,
                          itemBuilder: (context, index) {
                            final book = _filteredBooks[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppPalette.soften(
                                    AppPalette.reading,
                                    0.2,
                                  ),
                                  child: Text(
                                    book.title.isNotEmpty ? book.title[0] : '?',
                                    style: const TextStyle(
                                      color: AppPalette.reading,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: SelectableContextText(
                                  text: book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    SelectableContextText(
                                      text: book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    if (book.genre != null && book.genre!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Chip(
                                        label: Text(
                                          book.genre!,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${book.createdAt.year}/${book.createdAt.month}/${book.createdAt.day}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailScreen(bookId: book.id),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _loadBooks();
                                  }
                                },
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
              builder: (_) => const BookAddScreen(),
            ),
          );
          if (result == true && mounted) {
            _loadBooks();
          }
        },
        backgroundColor: AppPalette.reading,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('本を追加'),
      ),
    );
  }
}
