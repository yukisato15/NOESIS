import 'package:drift/drift.dart';

/// 音声ソースの種別
enum EpisodeSourceType { youtube, podcast, file, recording, text }

extension EpisodeSourceTypeLabel on EpisodeSourceType {
  String get label {
    switch (this) {
      case EpisodeSourceType.youtube:
        return 'YouTube';
      case EpisodeSourceType.podcast:
        return 'ポッドキャスト';
      case EpisodeSourceType.file:
        return '音声ファイル';
      case EpisodeSourceType.recording:
        return '録音';
      case EpisodeSourceType.text:
        return 'テキスト入力';
    }
  }

  String get icon {
    switch (this) {
      case EpisodeSourceType.youtube:
        return '▶';
      case EpisodeSourceType.podcast:
        return '🎙';
      case EpisodeSourceType.file:
        return '📁';
      case EpisodeSourceType.recording:
        return '🔴';
      case EpisodeSourceType.text:
        return '📝';
    }
  }
}

/// ポッドキャスト・音声記録エピソードテーブル
/// Reading の Books に相当する「1エピソード = 1レコード」
@DataClassName('PodcastEpisode')
class PodcastEpisodes extends Table {
  IntColumn get id => integer().autoIncrement()();

  // ===== 必須項目 =====
  /// エピソードタイトル
  TextColumn get title => text()();

  /// ソースの種別
  IntColumn get sourceType =>
      intEnum<EpisodeSourceType>().withDefault(const Constant(0))();

  // ===== ソース情報 =====
  /// 元URL（YouTube・ポッドキャストRSSなど）
  TextColumn get sourceUrl => text().nullable()();

  /// 番組名・チャンネル名
  TextColumn get programName => text().nullable()();

  /// 話者・出演者
  TextColumn get speaker => text().nullable()();

  // ===== コンテンツ =====
  /// トランスクリプト全文
  TextColumn get transcript => text().nullable()();

  /// AI要約
  TextColumn get summary => text().nullable()();

  /// AI構造化メモ（章立て・キーワードなど）
  TextColumn get structuredNotes => text().nullable()();

  // ===== メディア =====
  /// ローカル音声ファイルパス（インポート・録音ファイル）
  TextColumn get audioFilePath => text().nullable()();

  /// 再生時間（秒）
  IntColumn get durationSeconds => integer().nullable()();

  // ===== 追加メタデータ =====
  /// ジャンル
  TextColumn get genre => text().nullable()();

  /// あらすじ・概要
  TextColumn get synopsis => text().nullable()();

  /// 評価
  TextColumn get rating => text().nullable()();

  /// 関連URL（AI補完等で取得したリンク）
  TextColumn get relatedUrl => text().nullable()();

  /// 一般的なレビュー要約
  TextColumn get reviewSummary => text().nullable()();

  // ===== メタデータ =====
  /// 配信日・公開日
  DateTimeColumn get publishedAt => dateTime().nullable()();

  /// 登録日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
