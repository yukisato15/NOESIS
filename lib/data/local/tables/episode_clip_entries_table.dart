import 'package:drift/drift.dart';

/// 音声記録メモへの追記エントリーの種類
enum EpisodeClipEntryType {
  original,
  aiSummary,
  aiRewrite,
  aiQA,
  manualNote,
}

/// 音声記録メモへの追記履歴
@DataClassName('EpisodeClipEntry')
class EpisodeClipEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 親クリップID
  IntColumn get clipId => integer()();

  /// エントリー種別
  IntColumn get entryType => intEnum<EpisodeClipEntryType>()();

  /// エントリー本文
  TextColumn get content => text()();

  /// 質問内容（QA時のみ）
  TextColumn get question => text().nullable()();

  /// 使用した思考スタイル
  TextColumn get thinkingStyleName => text().nullable()();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
