import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/podcast_episodes_table.dart';

part 'podcast_episodes_dao.g.dart';

@DriftAccessor(tables: [PodcastEpisodes])
class PodcastEpisodesDao extends DatabaseAccessor<AppDatabase>
    with _$PodcastEpisodesDaoMixin {
  PodcastEpisodesDao(super.db);

  /// エピソードを挿入
  Future<int> insertEpisode(PodcastEpisodesCompanion episode) {
    return into(podcastEpisodes).insert(episode);
  }

  /// エピソードを更新
  Future<bool> updateEpisode(PodcastEpisode episode) {
    return update(podcastEpisodes).replace(episode);
  }

  /// エピソードを削除
  Future<int> deleteEpisode(int id) {
    return (delete(podcastEpisodes)..where((t) => t.id.equals(id))).go();
  }

  /// ID指定でエピソードを取得
  Future<PodcastEpisode?> getEpisodeById(int id) {
    return (select(podcastEpisodes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 全エピソードを取得（登録日時降順）
  Future<List<PodcastEpisode>> getAllEpisodes() {
    return (select(podcastEpisodes)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 全文検索（title, programName, speaker, transcript, summary）
  Future<List<PodcastEpisode>> searchEpisodes(String query) {
    return (select(podcastEpisodes)
          ..where((t) =>
              t.title.like('%$query%') |
              t.programName.like('%$query%') |
              t.speaker.like('%$query%') |
              t.transcript.like('%$query%') |
              t.summary.like('%$query%'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 番組名でフィルタ
  Future<List<PodcastEpisode>> getEpisodesByProgram(String programName) {
    return (select(podcastEpisodes)
          ..where((t) => t.programName.equals(programName))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// ソース種別でフィルタ
  Future<List<PodcastEpisode>> getEpisodesBySourceType(
      EpisodeSourceType type) {
    return (select(podcastEpisodes)
          ..where((t) => t.sourceType.equals(type.index))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// エピソード総数
  Future<int> getEpisodeCount() async {
    final countQuery = selectOnly(podcastEpisodes)
      ..addColumns([podcastEpisodes.id.count()]);
    final result = await countQuery.getSingle();
    return result.read(podcastEpisodes.id.count()) ?? 0;
  }

  /// 番組名一覧（重複なし）
  Future<List<String>> getAllProgramNames() async {
    final query = selectOnly(podcastEpisodes, distinct: true)
      ..addColumns([podcastEpisodes.programName])
      ..where(podcastEpisodes.programName.isNotNull());
    final rows = await query.get();
    return rows
        .map((r) => r.read(podcastEpisodes.programName))
        .whereType<String>()
        .toList();
  }
}
