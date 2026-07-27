import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/episode_clips_table.dart';

part 'episode_clips_dao.g.dart';

@DriftAccessor(tables: [EpisodeClips])
class EpisodeClipsDao extends DatabaseAccessor<AppDatabase>
    with _$EpisodeClipsDaoMixin {
  EpisodeClipsDao(super.db);

  /// クリップを挿入
  Future<int> insertClip(EpisodeClipsCompanion clip) {
    return into(episodeClips).insert(clip);
  }

  /// クリップを更新
  Future<bool> updateClip(EpisodeClip clip) {
    return update(episodeClips).replace(clip);
  }

  /// クリップを削除
  Future<int> deleteClip(int id) {
    return (delete(episodeClips)..where((t) => t.id.equals(id))).go();
  }

  /// エピソードに属する全クリップを取得（作成日時昇順）
  Future<List<EpisodeClip>> getClipsByEpisode(int episodeId) {
    return (select(episodeClips)
          ..where((t) => t.episodeId.equals(episodeId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// エピソードのクリップを削除（エピソード削除時に使用）
  Future<int> deleteClipsByEpisode(int episodeId) {
    return (delete(episodeClips)
          ..where((t) => t.episodeId.equals(episodeId)))
        .go();
  }

  /// ID指定でクリップを取得
  Future<EpisodeClip?> getClipById(int id) {
    return (select(episodeClips)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 全クリップを全文検索
  Future<List<EpisodeClip>> searchClips(String query) {
    return (select(episodeClips)
          ..where((t) => t.clipText.like('%$query%') | t.note.like('%$query%'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }
}
