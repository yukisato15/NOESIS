import 'package:drift/drift.dart';

enum AggregateAiEntryType {
  summary,
  analysis,
  qa,
}

@DataClassName('BookAiEntry')
class BookAiEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer()();
  IntColumn get entryType => intEnum<AggregateAiEntryType>()();
  TextColumn get content => text()();
  TextColumn get question => text().nullable()();
  TextColumn get thinkingStyleName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
