import 'package:drift/drift.dart';

@DataClassName('AISession')
class AISessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subjectType =>
      text()(); // 'concept_memo', 'reading_reflection'
  IntColumn get subjectId => integer()();
  TextColumn get role => text()(); // 'user', 'assistant', 'system'
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
