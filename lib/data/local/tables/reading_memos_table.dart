import 'package:drift/drift.dart';

/// 読書メモテーブル
/// 書籍から取得したメモ（手入力 + Live Textによるコピペ）を保存
@DataClassName('ReadingMemo')
class ReadingMemos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属する書籍ID
  IntColumn get bookId => integer()();

  // ===== 必須項目 =====
  /// 本文（手入力またはLive Textでコピペ）
  TextColumn get content => text()();

  // ===== 任意項目 =====
  /// 小タイトル（章名、トピック名など）
  TextColumn get sectionTitle => text().nullable()();

  /// ページ番号
  TextColumn get pageNumber => text().nullable()();

  // ===== 自動取得 =====
  /// 作成日時
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
