import 'package:drift/drift.dart';

@DataClassName('ReadingMemo')
class ReadingMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer()();
  TextColumn get content => text()(); // 断片・引用・気づき
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
