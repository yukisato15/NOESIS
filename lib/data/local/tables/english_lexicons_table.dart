import 'package:drift/drift.dart';

@DataClassName('EnglishLexicon')
class EnglishLexicons extends Table {
  IntColumn get entryId => integer()();

  // 見出し・発音
  TextColumn get headword => text()();
  TextColumn get language => text()(); // 'en', 'fr', etc.
  TextColumn get ipa => text()(); // IPA記号
  TextColumn get readingKana => text().withDefault(const Constant(''))();
  TextColumn get pronunciationNote => text()();

  // 品詞・可算性
  TextColumn get partOfSpeech => text()(); // 'noun', 'verb', etc.
  TextColumn get countability =>
      text()(); // 'countable', 'uncountable', 'both'

  // 定義
  TextColumn get definitionEn => text()();
  TextColumn get definitionJa => text()();

  // JSON配列フィールド
  TextColumn get synonymsJson => text()(); // ["ruin", "wreck"]
  TextColumn get antonymsJson => text()();
  TextColumn get relatedTermsJson => text()();
  TextColumn get examplesJson => text()(); // [{"en": "...", "ja": "..."}]
  TextColumn get phrasesJson => text()();

  // 語法・語源
  TextColumn get register => text()(); // 'formal', 'informal', 'slang'
  TextColumn get etymology => text()();
  TextColumn get usageNote => text()();

  // 概念メモ
  TextColumn get conceptMemo => text().withDefault(const Constant(''))();

  // 音声（将来拡張）
  TextColumn get audioTtsText => text().withDefault(const Constant(''))();
  TextColumn get audioUrl => text().withDefault(const Constant(''))();
  TextColumn get audioNote => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {entryId};
}
