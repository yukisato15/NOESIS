import 'package:drift/drift.dart';

/// 追記エントリーの種類
enum MemoEntryType {
  original,     // 初回記録
  aiSummary,    // AI要約
  aiRewrite,    // AIリライト
  aiQA,         // 質問応答
  manualNote,   // 手動追記
}

/// 読書メモへの追記エントリーテーブル
/// 各メモに対する時系列の追記を管理
@DataClassName('ReadingMemoEntry')
class ReadingMemoEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 親メモのID
  IntColumn get memoId => integer()();

  /// エントリーの種類
  IntColumn get entryType => intEnum<MemoEntryType>()();

  /// エントリーの内容
  TextColumn get content => text()();

  /// 質問（entryTypeがaiQAの場合のみ使用）
  TextColumn get question => text().nullable()();

  /// 使用した思考スタイル（AI系エントリーの場合）
  TextColumn get thinkingStyleName => text().nullable()();

  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
