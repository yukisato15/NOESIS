import 'package:drift/drift.dart';

enum CodeEntryType {
  whole,    // コード全体
  function, // 関数単位
  block,    // ブロック単位
}

/// ITコード理解アーカイブのエントリー
@DataClassName('CodeEntry')
class CodeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // コード情報
  TextColumn get title => text()(); // コードのタイトル（関数名など）
  TextColumn get code => text()(); // コード本体
  IntColumn get entryType => intEnum<CodeEntryType>()(); // エントリータイプ

  // AI解析結果（基本）
  TextColumn get language => text().nullable()(); // 言語名
  TextColumn get libraries => text().nullable()(); // ライブラリ（JSON配列）
  TextColumn get structure => text().nullable()(); // 構造解析結果
  TextColumn get capabilities => text().nullable()(); // できること
  TextColumn get useCases => text().nullable()(); // 用途・用例
  TextColumn get learningPoints => text().nullable()(); // 学習ポイント

  // AI解析結果（拡張）
  TextColumn get synonymousCodes => text().nullable()(); // 類義のコード（JSON配列）
  TextColumn get antonymousCodes => text().nullable()(); // 対義のコード（JSON配列）
  TextColumn get relatedCodes => text().nullable()(); // 関連するコード（JSON配列）
  TextColumn get examples => text().nullable()(); // 具体例（JSON配列）
  TextColumn get cautions => text().nullable()(); // 使用上の注意
  TextColumn get trivia => text().nullable()(); // 面白エピソード・トリビア
  TextColumn get tips => text().nullable()(); // ワンポイントアドバイス
  TextColumn get commonMistakes => text().nullable()(); // よくある誤用・間違い
  TextColumn get gyaruExplanation => text().nullable()(); // ギャルによる説明
  TextColumn get kindergartenExplanation => text().nullable()(); // 幼稚園児でも理解できる説明

  // 学習サポート
  IntColumn get learningLevel => integer().nullable()(); // 学習レベル（1=初心者, 2=中級者, 3=上級者）

  // メタ情報
  TextColumn get tags => text().nullable()(); // タグ（JSON配列）
  TextColumn get category => text().nullable()(); // カテゴリ

  // タイムスタンプ
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();
}
