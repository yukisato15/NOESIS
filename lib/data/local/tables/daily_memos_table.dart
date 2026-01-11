import 'package:drift/drift.dart';

@DataClassName('DailyMemo')
class DailyMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()(); // 短文・即時的
  TextColumn get category => text().nullable()(); // カテゴリ/ジャンル
  TextColumn get tags => text().nullable()(); // JSON array of strings
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
