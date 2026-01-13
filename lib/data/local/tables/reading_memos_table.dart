import 'package:drift/drift.dart';

/// メモの種類
enum MemoType {
  excerpt,  // 本文抜粋メモ
  thought,  // 思考メモ
  review,   // 感想
}

/// 読書メモテーブル
/// 書籍から取得したメモ（手入力 + Live Textによるコピペ）を保存
@DataClassName('ReadingMemo')
class ReadingMemos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属する書籍ID
  IntColumn get bookId => integer()();

  /// メモの種類（本文抜粋/思考メモ/感想）
  IntColumn get type => intEnum<MemoType>()();

  // ===== メモ本文 =====
  /// 本文抜粋（typeがexcerptの時のみ使用）
  TextColumn get excerptText => text().nullable()();

  /// 思考メモ（全タイプで使用可能）
  TextColumn get thoughtText => text()();

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

  // 下位互換性のため、contentカラムを残す（非推奨）
  @Deprecated('Use excerptText and thoughtText instead')
  TextColumn get content => text().nullable()();
}
