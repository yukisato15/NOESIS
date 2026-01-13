import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/daily_memo_entries_table.dart';

part 'daily_memo_entries_dao.g.dart';

@DriftAccessor(tables: [DailyMemoEntries])
class DailyMemoEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$DailyMemoEntriesDaoMixin {
  DailyMemoEntriesDao(super.db);

  Future<int> insertEntry(DailyMemoEntriesCompanion entry) {
    return into(dailyMemoEntries).insert(entry);
  }

  Future<List<DailyMemoEntry>> getEntriesByMemoId(int memoId) {
    return (select(dailyMemoEntries)
          ..where((e) => e.memoId.equals(memoId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<List<DailyMemoEntry>> getEntriesByType(
      int memoId, DailyMemoEntryType type) {
    return (select(dailyMemoEntries)
          ..where((e) => e.memoId.equals(memoId) & e.entryType.equalsValue(type))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> updateEntry(int id, DailyMemoEntriesCompanion entry) {
    return (update(dailyMemoEntries)..where((e) => e.id.equals(id)))
        .write(entry);
  }

  Future<int> deleteEntry(int id) {
    return (delete(dailyMemoEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> deleteAllEntriesByMemoId(int memoId) {
    return (delete(dailyMemoEntries)..where((e) => e.memoId.equals(memoId)))
        .go();
  }
}
