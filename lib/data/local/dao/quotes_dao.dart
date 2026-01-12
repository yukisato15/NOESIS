import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/quotes_table.dart';

part 'quotes_dao.g.dart';

@DriftAccessor(tables: [Quotes])
class QuotesDao extends DatabaseAccessor<AppDatabase> with _$QuotesDaoMixin {
  QuotesDao(super.db);

  /// 引用メモを挿入
  Future<int> insertQuote(QuotesCompanion quote) {
    return into(quotes).insert(quote);
  }

  /// 引用メモを更新
  Future<bool> updateQuote(Quote quote) {
    return update(quotes).replace(quote);
  }

  /// 引用メモを削除
  Future<int> deleteQuote(int id) {
    return (delete(quotes)..where((t) => t.id.equals(id))).go();
  }

  /// ID指定で引用メモを取得
  Future<Quote?> getQuoteById(int id) {
    return (select(quotes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 書籍エントリIDで引用メモを取得（作成日時降順）
  Future<List<Quote>> getQuotesByEntryId(int entryId) {
    return (select(quotes)
          ..where((t) => t.entryId.equals(entryId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 全引用メモを取得（作成日時降順）
  Future<List<Quote>> getAllQuotes() {
    return (select(quotes)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 引用メモを全文検索（quoteText, sectionTitle, noteを検索対象とする）
  Future<List<Quote>> searchQuotes(String query) {
    return (select(quotes)
          ..where((t) =>
              t.quoteText.like('%$query%') |
              t.sectionTitle.like('%$query%') |
              t.note.like('%$query%'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 特定の書籍エントリIDに属する引用メモの件数を取得
  Future<int> getQuoteCountByEntryId(int entryId) async {
    final countQuery = selectOnly(quotes)
      ..addColumns([quotes.id.count()])
      ..where(quotes.entryId.equals(entryId));
    final result = await countQuery.getSingle();
    return result.read(quotes.id.count()) ?? 0;
  }
}
