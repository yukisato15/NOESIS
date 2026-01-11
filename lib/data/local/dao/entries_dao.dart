import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/entries_table.dart';

part 'entries_dao.g.dart';

@DriftAccessor(tables: [Entries])
class EntriesDao extends DatabaseAccessor<AppDatabase> with _$EntriesDaoMixin {
  EntriesDao(super.db);

  // 辞書エントリーの取得（全て）
  Future<List<Entry>> getAllDictionaryEntries() {
    return (select(entries)
          ..where((t) => t.type.equals(EntryType.dictionary.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 辞書エントリーの取得（ドメイン別）
  Future<List<Entry>> getDictionaryEntriesByDomain(DictionaryDomain domain) {
    return (select(entries)
          ..where((t) =>
              t.type.equals(EntryType.dictionary.index) &
              t.domain.equals(domain.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 読書ノートの取得（全て）
  Future<List<Entry>> getAllReadingNotes() {
    return (select(entries)
          ..where((t) => t.type.equals(EntryType.readingNote.index))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 読書ノートの取得（書籍別）
  Future<List<Entry>> getReadingNotesByBook(String bookTitle) {
    return (select(entries)
          ..where((t) =>
              t.type.equals(EntryType.readingNote.index) &
              t.reading.equals(bookTitle))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // エントリーの作成
  Future<int> createEntry(EntriesCompanion entry) {
    return into(entries).insert(entry);
  }

  // エントリーの更新
  Future<bool> updateEntry(Entry entry) {
    return update(entries).replace(entry);
  }

  // エントリーの削除
  Future<int> deleteEntry(int id) {
    return (delete(entries)..where((t) => t.id.equals(id))).go();
  }

  // ID指定でエントリー取得
  Future<Entry?> getEntryById(int id) {
    return (select(entries)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // 全文検索（辞書）
  Future<List<Entry>> searchDictionaryEntries(String query) async {
    return (select(entries)
          ..where((t) =>
              t.type.equals(EntryType.dictionary.index) &
              (t.title.like('%$query%') | t.body.like('%$query%')))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 全文検索（読書ノート）
  Future<List<Entry>> searchReadingNotes(String query) async {
    return (select(entries)
          ..where((t) =>
              t.type.equals(EntryType.readingNote.index) &
              (t.title.like('%$query%') | t.body.like('%$query%')))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 最近更新されたエントリー
  Future<List<Entry>> getRecentEntries({int limit = 20}) {
    return (select(entries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }
}
