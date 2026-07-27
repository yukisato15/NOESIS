import 'package:drift/drift.dart';

import 'person_profile_attributes_table.dart';

enum ArchiveEntryType { note, interaction, observation, event, visit, idea }

extension ArchiveEntryTypeLabel on ArchiveEntryType {
  String get label {
    switch (this) {
      case ArchiveEntryType.note:
        return 'メモ';
      case ArchiveEntryType.interaction:
        return 'やりとり';
      case ArchiveEntryType.observation:
        return '観察';
      case ArchiveEntryType.event:
        return '出来事';
      case ArchiveEntryType.visit:
        return '訪問';
      case ArchiveEntryType.idea:
        return 'アイデア';
    }
  }
}

@DataClassName('ArchiveEntry')
class ArchiveEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetId => integer()();
  IntColumn get entryType => intEnum<ArchiveEntryType>()();
  TextColumn get title => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get happenedAt => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get dataType =>
      intEnum<PersonDataType>().withDefault(const Constant(1))();
  IntColumn get confidenceScore =>
      integer().named('confidence_score').withDefault(const Constant(50))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
