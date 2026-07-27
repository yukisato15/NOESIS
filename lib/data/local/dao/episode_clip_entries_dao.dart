import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/episode_clip_entries_table.dart';

part 'episode_clip_entries_dao.g.dart';

@DriftAccessor(tables: [EpisodeClipEntries])
class EpisodeClipEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$EpisodeClipEntriesDaoMixin {
  EpisodeClipEntriesDao(super.db);

  Future<int> insertEntry(EpisodeClipEntriesCompanion entry) {
    return into(episodeClipEntries).insert(entry);
  }

  Future<bool> updateEntry(EpisodeClipEntry entry) {
    return update(episodeClipEntries).replace(entry);
  }

  Future<int> deleteEntry(int entryId) {
    return (delete(episodeClipEntries)..where((e) => e.id.equals(entryId)))
        .go();
  }

  Future<EpisodeClipEntry?> getEntryById(int entryId) {
    return (select(episodeClipEntries)..where((e) => e.id.equals(entryId)))
        .getSingleOrNull();
  }

  Future<List<EpisodeClipEntry>> getEntriesByClipId(int clipId) {
    return (select(episodeClipEntries)
          ..where((e) => e.clipId.equals(clipId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> deleteEntriesByClipId(int clipId) {
    return (delete(episodeClipEntries)..where((e) => e.clipId.equals(clipId)))
        .go();
  }
}
