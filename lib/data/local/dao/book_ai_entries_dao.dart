import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/book_ai_entries_table.dart';

part 'book_ai_entries_dao.g.dart';

@DriftAccessor(tables: [BookAiEntries])
class BookAiEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$BookAiEntriesDaoMixin {
  BookAiEntriesDao(super.db);

  Future<int> insertEntry(BookAiEntriesCompanion entry) {
    return into(bookAiEntries).insert(entry);
  }

  Future<List<BookAiEntry>> getEntriesByBookId(int bookId) {
    return (select(bookAiEntries)
          ..where((e) => e.bookId.equals(bookId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> deleteEntryById(int id) {
    return (delete(bookAiEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<int> deleteEntriesByType(int bookId, AggregateAiEntryType type) {
    return (delete(bookAiEntries)
          ..where(
            (e) => e.bookId.equals(bookId) & e.entryType.equals(type.index),
          ))
        .go();
  }
}
