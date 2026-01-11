import 'package:drift/drift.dart';

@DataClassName('PhilosophicalDialogue')
class PhilosophicalDialogues extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get summary => text().nullable()();
  TextColumn get category => text().nullable()(); // カテゴリ/ジャンル
  TextColumn get tags => text().nullable()(); // JSON array of strings
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
