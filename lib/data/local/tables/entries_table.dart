import 'package:drift/drift.dart';

enum EntryType {
  dictionary,
  readingNote,
}

enum DictionaryDomain {
  general,
  technology,
  english,
}

@DataClassName('Entry')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 基本情報
  IntColumn get type => intEnum<EntryType>()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  // 辞書用フィールド
  TextColumn get genre => text().nullable()(); // "哲学", "データベース"
  IntColumn get domain =>
      intEnum<DictionaryDomain>().withDefault(const Constant(0))(); // general
  TextColumn get field =>
      text().withDefault(const Constant('unspecified'))();

  // 読書ノート用フィールド
  IntColumn get bookId => integer().nullable()();

  // 概念関連
  TextColumn get concept => text().nullable()(); // 上位概念への参照（テキスト）

  // 読み仮名（五十音順ソート用）
  TextColumn get reading => text().withDefault(const Constant(''))();
  TextColumn get readingSource =>
      text().withDefault(const Constant('manual'))(); // 'manual', 'ai', 'mecab'

  // 言語
  TextColumn get language => text().withDefault(const Constant('ja'))();

  // タイムスタンプ
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
