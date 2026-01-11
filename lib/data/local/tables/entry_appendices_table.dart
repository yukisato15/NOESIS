import 'package:drift/drift.dart';

enum AppendixType {
  log,      // 全文会話ログ
  extract,  // 抜粋のみ
  summary,  // AI要約
}

@DataClassName('EntryAppendix')
class EntryAppendices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer()();
  IntColumn get type => intEnum<AppendixType>()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
