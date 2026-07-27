import 'package:drift/drift.dart';

enum SpotLinkType {
  map,
  official,
  instagram,
  x,
  tiktok,
  review,
  article,
  other,
}

@DataClassName('SpotLink')
class SpotLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get spotId => integer().named('spot_id')();
  IntColumn get linkType => intEnum<SpotLinkType>()
      .named('link_type')
      .withDefault(const Constant(7))();
  TextColumn get url => text()();
  TextColumn get label => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
