import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/reading_memos_table.dart';

part 'reading_memos_dao.g.dart';

@DriftAccessor(tables: [ReadingMemos])
class ReadingMemosDao extends DatabaseAccessor<AppDatabase> with _$ReadingMemosDaoMixin {
  ReadingMemosDao(super.db);

  /// 読書メモを挿入
  Future<int> insertMemo(ReadingMemosCompanion memo) {
    return into(readingMemos).insert(memo);
  }

  /// 読書メモを更新
  Future<bool> updateMemo(ReadingMemo memo) {
    return update(readingMemos).replace(memo);
  }

  /// 読書メモを削除
  Future<int> deleteMemo(int id) {
    return (delete(readingMemos)..where((t) => t.id.equals(id))).go();
  }

  /// ID指定で読書メモを取得
  Future<ReadingMemo?> getMemoById(int id) {
    return (select(readingMemos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 書籍IDで読書メモを取得（作成日時降順）
  Future<List<ReadingMemo>> getMemosByBookId(int bookId) {
    return (select(readingMemos)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 全読書メモを取得（作成日時降順）
  Future<List<ReadingMemo>> getAllMemos() {
    return (select(readingMemos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 読書メモを全文検索（content, sectionTitleを検索対象とする）
  Future<List<ReadingMemo>> searchMemos(String query) {
    return (select(readingMemos)
          ..where((t) =>
              t.content.like('%$query%') |
              t.sectionTitle.like('%$query%'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 特定の書籍IDに属する読書メモの件数を取得
  Future<int> getMemoCountByBookId(int bookId) async {
    final countQuery = selectOnly(readingMemos)
      ..addColumns([readingMemos.id.count()])
      ..where(readingMemos.bookId.equals(bookId));
    final result = await countQuery.getSingle();
    return result.read(readingMemos.id.count()) ?? 0;
  }

  /// ページ番号で読書メモを取得
  Future<List<ReadingMemo>> getMemosByPageNumber(int bookId, String pageNumber) {
    return (select(readingMemos)
          ..where((t) => t.bookId.equals(bookId) & t.pageNumber.equals(pageNumber))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// セクションタイトルで読書メモを取得
  Future<List<ReadingMemo>> getMemosBySectionTitle(int bookId, String sectionTitle) {
    return (select(readingMemos)
          ..where((t) => t.bookId.equals(bookId) & t.sectionTitle.equals(sectionTitle))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }
}
