/// テキスト正規化ユーティリティ
/// ライブテキストから貼り付けられたテキストを整形する
/// OCRの再実行は行わず、あくまで「整形」のみ
class TextNormalizer {
  /// 引用テキストを正規化
  /// - 不要な改行を除去
  /// - 行頭・行末の不自然な空白を除去
  /// - 文字の推定・補完・修正は行わない
  static String normalizeQuoteText(String rawText) {
    if (rawText.isEmpty) return rawText;

    // 1. 前後の空白を削除
    String text = rawText.trim();

    // 2. 複数の連続する空白を1つに統一
    text = text.replaceAll(RegExp(r' +'), ' ');

    // 3. 行末の不要な空白を削除
    text = text.replaceAll(RegExp(r' +\n'), '\n');

    // 4. 行頭の不要な空白を削除
    text = text.replaceAll(RegExp(r'\n +'), '\n');

    // 5. 不自然な改行の正規化
    // 日本語の場合：句読点の後に改行がある場合は改行を削除して続ける
    text = text.replaceAll(RegExp(r'([。、！？])\n(?![\n　])'), r'$1');

    // 6. 3つ以上の連続する改行を2つに制限（段落区切りとして残す）
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text;
  }

  /// ページ番号文字列を正規化
  /// 例: "p.123", "123", "123-125" など
  static String? normalizePageNumber(String? pageNumber) {
    if (pageNumber == null || pageNumber.trim().isEmpty) return null;

    String normalized = pageNumber.trim();

    // 全角数字を半角に変換
    normalized = normalized.replaceAllMapped(
      RegExp(r'[０-９]'),
      (match) => String.fromCharCode(
        match.group(0)!.codeUnitAt(0) - '０'.codeUnitAt(0) + '0'.codeUnitAt(0),
      ),
    );

    return normalized;
  }

  /// 小タイトル／セクションタイトルを正規化
  static String? normalizeSectionTitle(String? title) {
    if (title == null || title.trim().isEmpty) return null;

    // 前後の空白を削除
    String normalized = title.trim();

    // 複数の連続する空白を1つに統一
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    return normalized;
  }
}
