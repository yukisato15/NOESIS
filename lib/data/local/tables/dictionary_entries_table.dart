import 'package:drift/drift.dart';

@DataClassName('DictionaryEntry')
class DictionaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictionaryId => integer()();
  TextColumn get headword => text()();
  TextColumn get category => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array of strings
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
