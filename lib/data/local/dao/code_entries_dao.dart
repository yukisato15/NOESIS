import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/code_entries_table.dart';

part 'code_entries_dao.g.dart';

@DriftAccessor(tables: [CodeEntries])
class CodeEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$CodeEntriesDaoMixin {
  CodeEntriesDao(super.db);

  Future<int> insertCodeEntry(CodeEntriesCompanion entry) {
    return into(codeEntries).insert(entry);
  }

  Future<List<CodeEntry>> getAllCodeEntries() {
    return (select(codeEntries)
          ..orderBy([
            (e) => OrderingTerm(expression: e.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<CodeEntry?> getCodeEntryById(int id) {
    return (select(codeEntries)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<List<CodeEntry>> getCodeEntriesByType(CodeEntryType type) {
    return (select(codeEntries)
          ..where((e) => e.entryType.equalsValue(type))
          ..orderBy([
            (e) => OrderingTerm(expression: e.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<List<CodeEntry>> getCodeEntriesByCategory(String category) {
    return (select(codeEntries)
          ..where((e) => e.category.equals(category))
          ..orderBy([
            (e) => OrderingTerm(expression: e.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<List<CodeEntry>> searchCodeEntries(String query) {
    return (select(codeEntries)
          ..where((e) =>
              e.title.contains(query) |
              e.code.contains(query) |
              e.language.contains(query) |
              e.capabilities.contains(query))
          ..orderBy([
            (e) => OrderingTerm(expression: e.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<bool> updateCodeEntry(CodeEntry entry) {
    return update(codeEntries).replace(entry);
  }

  Future<int> updateCodeEntryCompanion(int id, CodeEntriesCompanion entry) {
    return (update(codeEntries)..where((e) => e.id.equals(id))).write(entry);
  }

  Future<int> deleteCodeEntry(int id) {
    return (delete(codeEntries)..where((e) => e.id.equals(id))).go();
  }
}
