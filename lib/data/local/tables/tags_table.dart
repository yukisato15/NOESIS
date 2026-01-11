import 'package:drift/drift.dart';

@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

@DataClassName('EntryTag')
class EntryTags extends Table {
  IntColumn get entryId => integer()();
  IntColumn get tagId => integer()();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}
