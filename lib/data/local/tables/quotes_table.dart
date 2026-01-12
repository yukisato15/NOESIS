import 'package:drift/drift.dart';

/// 引用メモテーブル
/// 書籍から抜き出したテキスト（ライブテキスト経由でコピペされたもの）を保存
@DataClassName('Quote')
class Quotes extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 所属する書籍エントリ
  IntColumn get entryId => integer()();

  // 引用本文（ライブテキストから貼り付けられたテキスト）
  TextColumn get quoteText => text()();

  // ページ番号または位置（任意）
  TextColumn get pageOrLoc => text().nullable()();

  // 小項目／小タイトル（章名、トピック名など、任意）
  TextColumn get sectionTitle => text().nullable()();

  // ユーザーの解釈メモ（引用に対する考察、任意）
  TextColumn get note => text().nullable()();

  // 元画像パス（出典確認・再参照用、任意）
  TextColumn get sourceImagePath => text().nullable()();

  // 作成日時（システム自動取得）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // 更新日時
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
