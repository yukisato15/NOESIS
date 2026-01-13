import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/reading_memo_entries_table.dart';

part 'reading_memo_entries_dao.g.dart';

@DriftAccessor(tables: [ReadingMemoEntries])
class ReadingMemoEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingMemoEntriesDaoMixin {
  ReadingMemoEntriesDao(super.db);

  /// エントリーを追加
  Future<int> insertEntry(ReadingMemoEntriesCompanion entry) {
    return into(readingMemoEntries).insert(entry);
  }

  /// エントリーを更新
  Future<bool> updateEntry(ReadingMemoEntry entry) {
    return update(readingMemoEntries).replace(entry);
  }

  /// エントリーを削除
  Future<int> deleteEntry(int entryId) {
    return (delete(readingMemoEntries)..where((e) => e.id.equals(entryId)))
        .go();
  }

  /// IDでエントリーを取得
  Future<ReadingMemoEntry?> getEntryById(int entryId) {
    return (select(readingMemoEntries)..where((e) => e.id.equals(entryId)))
        .getSingleOrNull();
  }

  /// メモIDで全エントリーを取得（時系列順）
  Future<List<ReadingMemoEntry>> getEntriesByMemoId(int memoId) {
    return (select(readingMemoEntries)
          ..where((e) => e.memoId.equals(memoId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// 特定の種類のエントリーのみ取得
  Future<List<ReadingMemoEntry>> getEntriesByType(
      int memoId, MemoEntryType type) {
    return (select(readingMemoEntries)
          ..where((e) =>
              e.memoId.equals(memoId) & e.entryType.equalsValue(type))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// メモに紐づく全エントリーを削除
  Future<int> deleteEntriesByMemoId(int memoId) {
    return (delete(readingMemoEntries)..where((e) => e.memoId.equals(memoId)))
        .go();
  }

  /// エントリー数を取得
  Future<int> getEntryCountByMemoId(int memoId) async {
    final query = selectOnly(readingMemoEntries)
      ..addColumns([readingMemoEntries.id.count()])
      ..where(readingMemoEntries.memoId.equals(memoId));

    final result = await query.getSingleOrNull();
    return result?.read(readingMemoEntries.id.count()) ?? 0;
  }
}
