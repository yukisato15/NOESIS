import 'package:drift/drift.dart';

/// 音声メモの種別
enum AudioMemoType { recording, file, text, url }

extension AudioMemoTypeLabel on AudioMemoType {
  String get label {
    switch (this) {
      case AudioMemoType.recording:
        return '録音';
      case AudioMemoType.file:
        return '音声ファイル';
      case AudioMemoType.text:
        return 'テキスト';
      case AudioMemoType.url:
        return 'URL';
    }
  }
}

/// エピソードクリップテーブル（音声記録メモ）
/// Reading の ReadingMemos に相当
@DataClassName('EpisodeClip')
class EpisodeClips extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属エピソード（PodcastEpisode）
  IntColumn get episodeId => integer()();

  /// メモのタイトル（任意）
  TextColumn get title => text().nullable()();

  /// メモの種別（recording/file/text/url）
  IntColumn get memoType =>
      intEnum<AudioMemoType>().withDefault(const Constant(0))();

  /// 音声ファイルパス（録音・ファイルインポート時）
  TextColumn get audioFilePath => text().nullable()();

  /// 録音時間（秒）
  IntColumn get durationSeconds => integer().nullable()();

  /// Whisper 文字起こし結果
  TextColumn get transcript => text().nullable()();

  /// ユーザーメモ・コメント
  TextColumn get note => text().nullable()();

  /// 抜粋テキスト（後方互換・検索用）
  TextColumn get clipText => text().withDefault(const Constant(''))();

  /// タイムスタンプ文字列（例: "12:34"、任意）
  TextColumn get timestampStr => text().nullable()();

  /// 他モジュールへの送信先（'dictionary', 'thinking', 'daily' など）
  TextColumn get sentTo => text().nullable()();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
