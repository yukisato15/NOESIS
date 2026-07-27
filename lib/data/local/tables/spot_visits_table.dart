import 'package:drift/drift.dart';

@DataClassName('SpotVisit')
class SpotVisits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spotId => integer().named('spot_id')();
  DateTimeColumn get visitedAt => dateTime().named('visited_at')();
  TextColumn get companionNote => text().named('companion_note').nullable()();
  TextColumn get orderNote => text().named('order_note').nullable()();
  TextColumn get situation => text().nullable()();
  TextColumn get impression => text().nullable()();
  TextColumn get conversationNote =>
      text().named('conversation_note').nullable()();
  IntColumn get rating => integer().nullable()();
  TextColumn get photoPath => text().named('photo_path').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
