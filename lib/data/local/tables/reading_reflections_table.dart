import 'package:drift/drift.dart';

@DataClassName('ReadingReflection')
class ReadingReflections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer()();
  TextColumn get content => text()(); // 思考のまとまり（長文）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
