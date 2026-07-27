import 'package:drift/drift.dart';

enum SpotMessageRole { system, user, assistant }

@DataClassName('SpotMessage')
class SpotMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spotId => integer().named('spot_id')();
  IntColumn get role =>
      intEnum<SpotMessageRole>().withDefault(const Constant(1))();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
