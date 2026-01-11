import 'package:drift/drift.dart';

@DataClassName('ConceptMemo')
class ConceptMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()(); // 自由記述（長文）

  // AI処理結果
  TextColumn get summary => text().nullable()();
  TextColumn get extractedJson =>
      text().withDefault(const Constant('[]'))(); // [{"concept": "...", "definition": "..."}]

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
