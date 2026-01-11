import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/daily_memos_table.dart';

part 'daily_memos_dao.g.dart';

@DriftAccessor(tables: [DailyMemos])
class DailyMemosDao extends DatabaseAccessor<AppDatabase>
    with _$DailyMemosDaoMixin {
  DailyMemosDao(super.db);

  // 全ての日常メモを取得
  Future<List<DailyMemo>> getAllDailyMemos() {
    return (select(dailyMemos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 日常メモの作成
  Future<int> createDailyMemo(DailyMemosCompanion memo) {
    return into(dailyMemos).insert(memo);
  }

  // 日常メモの更新
  Future<bool> updateDailyMemo(DailyMemo memo) {
    return update(dailyMemos).replace(memo);
  }

  // 日常メモの削除
  Future<int> deleteDailyMemo(int id) {
    return (delete(dailyMemos)..where((t) => t.id.equals(id))).go();
  }

  // ID指定で日常メモ取得
  Future<DailyMemo?> getDailyMemoById(int id) {
    return (select(dailyMemos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // FTS5全文検索
  Future<List<DailyMemo>> searchDailyMemos(String query) async {
    final results = await customSelect(
      '''
      SELECT dm.* FROM daily_memos dm
      JOIN daily_memos_fts f ON dm.id = f.rowid
      WHERE daily_memos_fts MATCH ?
      ORDER BY dm.updated_at DESC
      ''',
      variables: [Variable.withString(query)],
      readsFrom: {dailyMemos},
    ).get();

    return results.map((row) => dailyMemos.map(row.data)).toList();
  }

  // 最近の日常メモを取得
  Future<List<DailyMemo>> getRecentDailyMemos({int limit = 20}) {
    return (select(dailyMemos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  // 日付範囲でフィルター
  Future<List<DailyMemo>> getDailyMemosByDateRange(
      DateTime start, DateTime end) {
    return (select(dailyMemos)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerOrEqualValue(end))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 今日の日常メモを取得
  Future<List<DailyMemo>> getTodayDailyMemos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return getDailyMemosByDateRange(today, tomorrow);
  }
}
