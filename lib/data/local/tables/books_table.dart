import 'package:drift/drift.dart';

/// 書籍（本）テーブル
/// 読書アーカイブの「本」を管理
@DataClassName('Book')
class Books extends Table {
  IntColumn get id => integer().autoIncrement()();

  // ===== 必須項目（手入力） =====
  /// 書名
  TextColumn get title => text()();

  /// 著者名
  TextColumn get author => text()();

  // ===== 任意項目 =====
  /// ジャンル（手入力またはAI補完）
  TextColumn get genre => text().nullable()();

  /// 出版社（AI補完）
  TextColumn get publisher => text().nullable()();

  /// 出版年月日（AI補完）
  TextColumn get publishedDate => text().nullable()();

  /// ISBN（AI補完）
  TextColumn get isbn => text().nullable()();

  /// あらすじ概要（AI補完）
  TextColumn get synopsis => text().nullable()();

  /// 評価（★や短文、AI補完）
  TextColumn get rating => text().nullable()();

  /// 関連URL（AI補完）
  TextColumn get relatedUrl => text().nullable()();

  /// 一般的なレビュー要約（AI補完）
  TextColumn get reviewSummary => text().nullable()();

  /// 表紙画像のローカル保存パス
  TextColumn get coverImagePath => text().nullable()();

  // ===== 自動取得 =====
  /// 登録日時（＝読み始めた日時）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 更新日時
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
