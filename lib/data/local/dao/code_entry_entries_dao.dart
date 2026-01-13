import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/code_entry_entries_table.dart';

part 'code_entry_entries_dao.g.dart';

@DriftAccessor(tables: [CodeEntryEntries])
class CodeEntryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$CodeEntryEntriesDaoMixin {
  CodeEntryEntriesDao(super.db);

  Future<int> insertEntry(CodeEntryEntriesCompanion entry) {
    return into(codeEntryEntries).insert(entry);
  }

  Future<List<CodeEntryEntry>> getEntriesByCodeEntryId(int codeEntryId) {
    return (select(codeEntryEntries)
          ..where((e) => e.codeEntryId.equals(codeEntryId))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<List<CodeEntryEntry>> getEntriesByType(
      int codeEntryId, CodeEntryEntryType type) {
    return (select(codeEntryEntries)
          ..where((e) =>
              e.codeEntryId.equals(codeEntryId) & e.entryType.equalsValue(type))
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> updateEntry(int id, CodeEntryEntriesCompanion entry) {
    return (update(codeEntryEntries)..where((e) => e.id.equals(id)))
        .write(entry);
  }

  Future<int> deleteEntry(int id) {
    return (delete(codeEntryEntries)..where((e) => e.id.equals(id))).go();
  }

  Future<void> deleteAllEntriesByCodeEntryId(int codeEntryId) {
    return (delete(codeEntryEntries)
          ..where((e) => e.codeEntryId.equals(codeEntryId)))
        .go();
  }
}
