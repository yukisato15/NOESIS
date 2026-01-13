import 'package:drift/drift.dart';

enum DailyMemoEntryType {
  original,     // 初回記録
  aiSummary,    // AI要約
  aiRewrite,    // AIリライト
  aiQA,         // 質問応答
  manualNote,   // 手動追記
}

@DataClassName('DailyMemoEntry')
class DailyMemoEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get memoId => integer()();
  IntColumn get entryType => intEnum<DailyMemoEntryType>()();
  TextColumn get content => text()();
  TextColumn get question => text().nullable()();
  TextColumn get thinkingStyleName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
