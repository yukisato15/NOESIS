import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/book_ai_entries_table.dart';
import '../tables/episode_ai_entries_table.dart';

part 'episode_ai_entries_dao.g.dart';

@DriftAccessor(tables: [EpisodeAiEntries])
class EpisodeAiEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$EpisodeAiEntriesDaoMixin {
  EpisodeAiEntriesDao(super.db);

  Future<int> insertEntry(EpisodeAiEntriesCompanion entry) {
    return into(episodeAiEntries).insert(entry);
  }

  Future<List<EpisodeAiEntry>> getEntriesByEpisodeId(int episodeId) {
    return (select(episodeAiEntries)
          ..where((e) => e.episodeId.equals(episodeId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> deleteEntryById(int id) {
    return (delete(episodeAiEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<int> deleteEntriesByType(
    int episodeId,
    AggregateAiEntryType type,
  ) {
    return (delete(episodeAiEntries)
          ..where(
            (e) =>
                e.episodeId.equals(episodeId) &
                e.entryType.equals(type.index),
          ))
        .go();
  }
}
