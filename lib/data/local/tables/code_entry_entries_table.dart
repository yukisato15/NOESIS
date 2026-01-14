import 'package:drift/drift.dart';

enum CodeEntryEntryType {
  original,      // 初回記録
  aiExplanation, // AI解説
  userNote,      // ユーザーメモ
  aiRewrite,     // AIリライト
  aiQA,          // AI質問応答
}

/// コードエントリーへの追記履歴
@DataClassName('CodeEntryEntry')
class CodeEntryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get codeEntryId => integer()(); // 関連するコードエントリーID
  IntColumn get entryType => intEnum<CodeEntryEntryType>()(); // エントリータイプ
  TextColumn get content => text()(); // 追記内容
  TextColumn get thinkingStyleName => text().nullable()(); // 思考スタイル名（AI解説時）
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
}
