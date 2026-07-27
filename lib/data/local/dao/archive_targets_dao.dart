import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/archive_entries_table.dart';
import '../tables/archive_targets_table.dart';

part 'archive_targets_dao.g.dart';

@DriftAccessor(tables: [ArchiveTargets, ArchiveEntries])
class ArchiveTargetsDao extends DatabaseAccessor<AppDatabase>
    with _$ArchiveTargetsDaoMixin {
  ArchiveTargetsDao(super.db);

  Future<List<ArchiveTarget>> getAllTargets() {
    return (select(archiveTargets)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<ArchiveTarget?> getTargetById(int id) {
    return (select(
      archiveTargets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTarget(ArchiveTargetsCompanion target) {
    return into(archiveTargets).insert(target);
  }

  Future<bool> updateTarget(ArchiveTarget target) {
    return update(archiveTargets).replace(target);
  }

  Future<void> deleteTarget(int id) async {
    await transaction(() async {
      await (delete(
        db.personProfileAttributes,
      )..where((t) => t.targetId.equals(id))).go();
      await (delete(archiveEntries)..where((t) => t.targetId.equals(id))).go();
      await (delete(archiveTargets)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<ArchiveEntry>> getEntriesByTarget(int targetId) {
    return (select(archiveEntries)
          ..where((t) => t.targetId.equals(targetId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.happenedAt,
              mode: OrderingMode.desc,
              nulls: NullsOrder.last,
            ),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertEntry(ArchiveEntriesCompanion entry) {
    return into(archiveEntries).insert(entry);
  }

  Future<bool> updateEntry(ArchiveEntry entry) {
    return update(archiveEntries).replace(entry);
  }

  Future<int> touchTarget(int targetId) {
    return (update(archiveTargets)..where((t) => t.id.equals(targetId))).write(
      ArchiveTargetsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<int> deleteEntry(int id) {
    return (delete(archiveEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<int> getTargetCount() async {
    final row = await (selectOnly(
      archiveTargets,
    )..addColumns([archiveTargets.id.count()])).getSingle();
    return row.read(archiveTargets.id.count()) ?? 0;
  }
}
