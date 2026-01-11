import 'package:drift/drift.dart';

enum DialogueRole {
  user,
  assistant,
}

enum DialogueInputType {
  text,
  voice,
  image,
}

@DataClassName('PhilosophicalMessage')
class PhilosophicalMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dialogueId => integer()();
  IntColumn get role => intEnum<DialogueRole>()();
  IntColumn get inputType =>
      intEnum<DialogueInputType>().withDefault(const Constant(0))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get persona => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
