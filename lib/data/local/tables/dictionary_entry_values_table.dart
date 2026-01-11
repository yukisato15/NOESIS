import 'package:drift/drift.dart';

@DataClassName('DictionaryEntryValue')
class DictionaryEntryValues extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer()();
  IntColumn get fieldId => integer()();
  TextColumn get value => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => ['UNIQUE(entry_id, field_id)'];
}
