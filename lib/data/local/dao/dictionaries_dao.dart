import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database.dart';
import '../tables/dictionary_definitions_table.dart';
import '../tables/dictionary_entries_table.dart';
import '../tables/dictionary_entry_values_table.dart';
import '../tables/dictionary_fields_table.dart';

part 'dictionaries_dao.g.dart';

enum EntryConflictPolicy { skip, overwrite }

@DriftAccessor(
  tables: [
    DictionaryDefinitions,
    DictionaryFields,
    DictionaryEntries,
    DictionaryEntryValues,
  ],
)
class DictionariesDao extends DatabaseAccessor<AppDatabase>
    with _$DictionariesDaoMixin {
  DictionariesDao(super.db);

  Future<List<DictionaryDefinition>> getAllDictionaries() async {
    try {
      debugPrint('[DAO] getAllDictionaries: Starting query');
      final result = await (select(dictionaryDefinitions)..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
          .get();
      debugPrint('[DAO] getAllDictionaries: Found ${result.length} dictionaries');
      for (final dict in result) {
        debugPrint('[DAO]   - ${dict.id}: ${dict.name} (system: ${dict.isSystem}, work: ${dict.isWork})');
      }
      return result;
    } catch (e, stackTrace) {
      debugPrint('[DAO] ERROR in getAllDictionaries: $e');
      debugPrint('[DAO] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<DictionaryDefinition?> getDictionary(int id) {
    return (select(
      dictionaryDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createDictionary(DictionaryDefinitionsCompanion definition) {
    return into(dictionaryDefinitions).insert(definition);
  }

  Future<bool> updateDictionary(DictionaryDefinition definition) {
    return update(dictionaryDefinitions).replace(definition);
  }

  Future<int> deleteDictionary(int id) {
    return (delete(dictionaryDefinitions)..where((t) => t.id.equals(id))).go();
  }

  Future<List<DictionaryField>> getFields(int dictionaryId) {
    return (select(dictionaryFields)
          ..where((t) => t.dictionaryId.equals(dictionaryId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<bool> updateField(DictionaryField field) {
    return update(dictionaryFields).replace(field);
  }

  Future<List<DictionaryEntry>> getEntries(int dictionaryId) {
    return (select(dictionaryEntries)
          ..where((t) => t.dictionaryId.equals(dictionaryId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<DictionaryEntry?> getEntry(int id) {
    return (select(
      dictionaryEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> createEntry(DictionaryEntriesCompanion entry) {
    return into(dictionaryEntries).insert(entry);
  }

  Future<bool> updateEntry(DictionaryEntry entry) {
    return update(dictionaryEntries).replace(entry);
  }

  Future<int> deleteEntry(int id) {
    return (delete(dictionaryEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<List<DictionaryEntryValue>> getEntryValues(int entryId) {
    return (select(
      dictionaryEntryValues,
    )..where((t) => t.entryId.equals(entryId))).get();
  }

  Future<int> upsertEntryValue(DictionaryEntryValuesCompanion value) {
    return into(dictionaryEntryValues).insert(
      value,
      onConflict: DoUpdate(
        (old) => DictionaryEntryValuesCompanion(
          value: value.value,
          updatedAt: Value(DateTime.now()),
        ),
        target: [
          dictionaryEntryValues.entryId,
          dictionaryEntryValues.fieldId,
        ],
      ),
    );
  }

  Future<int> deleteEntryValues(int entryId) {
    return (delete(
      dictionaryEntryValues,
    )..where((t) => t.entryId.equals(entryId))).go();
  }

  Future<void> moveEntries({
    required List<int> entryIds,
    required int targetDictionaryId,
  }) async {
    await (update(dictionaryEntries)..where((t) => t.id.isIn(entryIds))).write(
      DictionaryEntriesCompanion(
        dictionaryId: Value(targetDictionaryId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<int>> mergeEntries({
    required List<int> entryIds,
    required int targetDictionaryId,
    required EntryConflictPolicy conflictPolicy,
  }) async {
    final movedIds = <int>[];
    await transaction(() async {
      for (final entryId in entryIds) {
        final entry = await (select(dictionaryEntries)
              ..where((t) => t.id.equals(entryId)))
            .getSingleOrNull();
        if (entry == null) {
          continue;
        }

        if (entry.dictionaryId == targetDictionaryId) {
          movedIds.add(entry.id);
          continue;
        }

        final existing = await (select(dictionaryEntries)
              ..where((t) => t.dictionaryId.equals(targetDictionaryId))
              ..where((t) => t.headword.equals(entry.headword)))
            .getSingleOrNull();

        if (existing != null) {
          if (conflictPolicy == EntryConflictPolicy.skip) {
            continue;
          }
          await (delete(dictionaryEntryValues)
                ..where((t) => t.entryId.equals(existing.id)))
              .go();
          await (delete(dictionaryEntries)
                ..where((t) => t.id.equals(existing.id)))
              .go();
        }

        await (update(dictionaryEntries)..where((t) => t.id.equals(entry.id)))
            .write(
          DictionaryEntriesCompanion(
            dictionaryId: Value(targetDictionaryId),
            updatedAt: Value(DateTime.now()),
          ),
        );
        movedIds.add(entry.id);
      }
    });

    return movedIds;
  }

  /// 指定された辞書の全エントリから使用されているタグを集計
  /// 使用頻度順にソートして返す
  Future<List<String>> getFrequentTags(int dictionaryId, {int limit = 20}) async {
    final entries = await (select(dictionaryEntries)
          ..where((t) => t.dictionaryId.equals(dictionaryId)))
        .get();

    final tagCounts = <String, int>{};

    for (final entry in entries) {
      if (entry.tags == null || entry.tags!.isEmpty) continue;
      try {
        final tags = (jsonDecode(entry.tags!) as List).cast<String>();
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      } catch (_) {
        // JSONパースエラーは無視
      }
    }

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTags.take(limit).map((e) => e.key).toList();
  }

  /// 指定された辞書の全エントリから使用されているカテゴリを集計
  /// 使用頻度順にソートして返す
  Future<List<String>> getFrequentCategories(int dictionaryId, {int limit = 10}) async {
    final entries = await (select(dictionaryEntries)
          ..where((t) => t.dictionaryId.equals(dictionaryId)))
        .get();

    final categoryCounts = <String, int>{};

    for (final entry in entries) {
      if (entry.category == null || entry.category!.isEmpty) continue;
      categoryCounts[entry.category!] = (categoryCounts[entry.category!] ?? 0) + 1;
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(limit).map((e) => e.key).toList();
  }
}
