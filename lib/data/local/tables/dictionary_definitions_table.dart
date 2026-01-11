import 'package:drift/drift.dart';

@DataClassName('DictionaryDefinition')
class DictionaryDefinitions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isWork => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  // 推奨タグリスト（JSON配列形式）
  TextColumn get recommendedTags => text().nullable()();
  // 推奨カテゴリリスト（JSON配列形式）
  TextColumn get recommendedCategories => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
