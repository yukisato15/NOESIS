import 'package:drift/drift.dart';

enum DictionaryFieldType { text, multiline, list, urlList }

@DataClassName('DictionaryField')
class DictionaryFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dictionaryId => integer()();
  TextColumn get fieldKey => text().named('field_key')();
  TextColumn get label => text()();
  IntColumn get fieldType => intEnum<DictionaryFieldType>()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => ['UNIQUE(dictionary_id, field_key)'];
}
