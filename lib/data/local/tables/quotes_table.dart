import 'package:drift/drift.dart';

@DataClassName('Quote')
class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId => integer()();
  TextColumn get quoteText => text()();
  TextColumn get pageOrLoc => text().nullable()();
  TextColumn get note => text().nullable()();
}
