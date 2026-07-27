import 'package:drift/drift.dart';

import 'book_ai_entries_table.dart';

@DataClassName('EpisodeAiEntry')
class EpisodeAiEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get episodeId => integer()();
  IntColumn get entryType => intEnum<AggregateAiEntryType>()();
  TextColumn get content => text()();
  TextColumn get question => text().nullable()();
  TextColumn get thinkingStyleName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
