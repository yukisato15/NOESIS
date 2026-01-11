import 'package:drift/drift.dart';

@DataClassName('Source')
class Sources extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
}

@DataClassName('EntrySource')
class EntrySources extends Table {
  IntColumn get entryId => integer()();
  IntColumn get sourceId => integer()();

  @override
  Set<Column> get primaryKey => {entryId, sourceId};
}
