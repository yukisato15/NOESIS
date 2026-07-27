import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/spot_links_table.dart';
import '../tables/spot_messages_table.dart';
import '../tables/spot_visits_table.dart';
import '../tables/spots_table.dart';

part 'spots_dao.g.dart';

@DriftAccessor(tables: [Spots, SpotVisits, SpotLinks, SpotMessages])
class SpotsDao extends DatabaseAccessor<AppDatabase> with _$SpotsDaoMixin {
  SpotsDao(super.db);

  Future<List<Spot>> getAllSpots() {
    return (select(spots)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<Spot?> getSpotById(int id) {
    return (select(spots)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Spot>> getMappableSpots() {
    return (select(spots)
          ..where(
            (t) =>
                t.isMapVisible.equals(true) &
                t.latitude.isNotNull() &
                t.longitude.isNotNull(),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertSpot(SpotsCompanion spot) => into(spots).insert(spot);

  Future<bool> updateSpot(Spot spot) => update(spots).replace(spot);

  Future<void> deleteSpot(int id) async {
    await transaction(() async {
      await (delete(spotVisits)..where((t) => t.spotId.equals(id))).go();
      await (delete(spotLinks)..where((t) => t.spotId.equals(id))).go();
      await (delete(spotMessages)..where((t) => t.spotId.equals(id))).go();
      await (delete(spots)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<SpotVisit>> getVisits(int spotId) {
    return (select(spotVisits)
          ..where((t) => t.spotId.equals(spotId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.visitedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertVisit(SpotVisitsCompanion visit) =>
      into(spotVisits).insert(visit);

  Future<int> deleteVisit(int id) =>
      (delete(spotVisits)..where((t) => t.id.equals(id))).go();

  Future<List<SpotLink>> getLinks(int spotId) {
    return (select(spotLinks)
          ..where((t) => t.spotId.equals(spotId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> insertLink(SpotLinksCompanion link) =>
      into(spotLinks).insert(link);

  Future<int> deleteLink(int id) =>
      (delete(spotLinks)..where((t) => t.id.equals(id))).go();

  Future<List<SpotMessage>> getMessages(int spotId) {
    return (select(spotMessages)
          ..where((t) => t.spotId.equals(spotId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> insertMessage(SpotMessagesCompanion message) =>
      into(spotMessages).insert(message);

  Future<int> updateCoordinates({
    required int spotId,
    double? latitude,
    double? longitude,
    String? placeId,
    String? geocodeSource,
    String? mapLabel,
  }) {
    return (update(spots)..where((t) => t.id.equals(spotId))).write(
      SpotsCompanion(
        latitude: Value(latitude),
        longitude: Value(longitude),
        placeId: Value(placeId),
        geocodeSource: Value(geocodeSource),
        mapLabel: Value(mapLabel),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateMapVisibility(int spotId, bool isVisible) {
    return (update(spots)..where((t) => t.id.equals(spotId))).write(
      SpotsCompanion(
        isMapVisible: Value(isVisible),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> touchSpot(int spotId) {
    return (update(spots)..where((t) => t.id.equals(spotId))).write(
      SpotsCompanion(updatedAt: Value(DateTime.now())),
    );
  }
}
