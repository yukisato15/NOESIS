import 'package:drift/drift.dart';

@DataClassName('Book')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get isbn => text().nullable()();
  TextColumn get overview => text().withDefault(const Constant(''))(); // AI生成可
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
