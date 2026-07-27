import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/person_profile_attributes_table.dart';

part 'person_profile_attributes_dao.g.dart';

@DriftAccessor(tables: [PersonProfileAttributes])
class PersonProfileAttributesDao extends DatabaseAccessor<AppDatabase>
    with _$PersonProfileAttributesDaoMixin {
  PersonProfileAttributesDao(super.db);

  Future<List<PersonProfileAttribute>> getAttributesByTarget(int targetId) {
    return (select(personProfileAttributes)
          ..where((t) => t.targetId.equals(targetId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.category, mode: OrderingMode.asc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertAttribute(PersonProfileAttributesCompanion attribute) {
    return into(personProfileAttributes).insert(attribute);
  }

  Future<bool> updateAttribute(PersonProfileAttribute attribute) {
    return update(personProfileAttributes).replace(attribute);
  }

  Future<PersonProfileAttribute?> getLatestAttributeForType({
    required int targetId,
    required String category,
    required String attributeName,
    required PersonDataType dataType,
  }) {
    return (select(personProfileAttributes)
          ..where((t) => t.targetId.equals(targetId))
          ..where((t) => t.category.equals(category))
          ..where((t) => t.attributeName.equals(attributeName))
          ..where((t) => t.dataType.equals(dataType.index))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertAttributeForType({
    required int targetId,
    required String category,
    required String attributeName,
    required String attributeValue,
    required PersonDataType dataType,
    required int confidenceScore,
    required String source,
    String? note,
  }) async {
    final existing = await getLatestAttributeForType(
      targetId: targetId,
      category: category,
      attributeName: attributeName,
      dataType: dataType,
    );
    final now = DateTime.now();
    if (existing == null) {
      await insertAttribute(
        PersonProfileAttributesCompanion.insert(
          targetId: targetId,
          category: category,
          attributeName: attributeName,
          attributeValue: attributeValue,
          dataType: dataType,
          confidenceScore: Value(confidenceScore),
          source: Value(source),
          note: Value(note),
          updatedAt: Value(now),
        ),
      );
      return;
    }
    await updateAttribute(
      existing.copyWith(
        attributeValue: attributeValue,
        confidenceScore: confidenceScore,
        source: source,
        note: Value(note),
        updatedAt: now,
      ),
    );
  }

  Future<int> deleteAttribute(int id) {
    return (delete(
      personProfileAttributes,
    )..where((t) => t.id.equals(id))).go();
  }
}
