import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/books_table.dart';

part 'books_dao.g.dart';

@DriftAccessor(tables: [Books])
class BooksDao extends DatabaseAccessor<AppDatabase> with _$BooksDaoMixin {
  BooksDao(super.db);

  /// 書籍を挿入
  Future<int> insertBook(BooksCompanion book) {
    return into(books).insert(book);
  }

  /// 書籍を更新
  Future<bool> updateBook(Book book) {
    return update(books).replace(book);
  }

  /// 書籍を削除
  Future<int> deleteBook(int id) {
    return (delete(books)..where((t) => t.id.equals(id))).go();
  }

  /// ID指定で書籍を取得
  Future<Book?> getBookById(int id) {
    return (select(books)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 全書籍を取得（登録日時降順）
  Future<List<Book>> getAllBooks() {
    return (select(books)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 書籍を全文検索（title, author, genre, synopsisを検索対象とする）
  Future<List<Book>> searchBooks(String query) {
    return (select(books)
          ..where((t) =>
              t.title.like('%$query%') |
              t.author.like('%$query%') |
              t.genre.like('%$query%') |
              t.synopsis.like('%$query%'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// ジャンル別に書籍を取得
  Future<List<Book>> getBooksByGenre(String genre) {
    return (select(books)
          ..where((t) => t.genre.equals(genre))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 著者別に書籍を取得
  Future<List<Book>> getBooksByAuthor(String author) {
    return (select(books)
          ..where((t) => t.author.equals(author))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 書籍の総数を取得
  Future<int> getBookCount() async {
    final countQuery = selectOnly(books)
      ..addColumns([books.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(books.id.count()) ?? 0;
  }
}
