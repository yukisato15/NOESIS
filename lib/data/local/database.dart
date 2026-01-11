import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/ai_sessions_table.dart';
import 'tables/books_table.dart';
import 'tables/concept_dictionaries_table.dart';
import 'tables/concept_memos_table.dart';
import 'tables/daily_memos_table.dart';
import 'tables/dictionary_fields_table.dart';
import 'tables/dictionary_entry_values_table.dart';
import 'tables/dictionary_entries_table.dart';
import 'tables/dictionary_definitions_table.dart';
import 'tables/english_lexicons_table.dart';
import 'tables/entries_table.dart';
import 'tables/entry_appendices_table.dart';
import 'tables/philosophical_concept_extractions_table.dart';
import 'tables/philosophical_dialogues_table.dart';
import 'tables/philosophical_messages_table.dart';
import 'tables/quotes_table.dart';
import 'tables/reading_memos_table.dart';
import 'tables/reading_reflections_table.dart';
import 'tables/sources_table.dart';
import 'tables/tags_table.dart';
import 'dao/entries_dao.dart';
import 'dao/concept_memos_dao.dart';
import 'dao/daily_memos_dao.dart';
import 'dao/dictionaries_dao.dart';
import 'dao/philosophical_dialogues_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Entries,
    EnglishLexicons,
    EntryAppendices,
    Books,
    ReadingMemos,
    ReadingReflections,
    ConceptDictionaries,
    ConceptMemos,
    DailyMemos,
    DictionaryDefinitions,
    DictionaryFields,
    DictionaryEntries,
    DictionaryEntryValues,
    Tags,
    EntryTags,
    Quotes,
    Sources,
    EntrySources,
    AISessions,
    PhilosophicalDialogues,
    PhilosophicalMessages,
    PhilosophicalConceptExtractions,
  ],
  daos: [
    EntriesDao,
    ConceptMemosDao,
    DailyMemosDao,
    DictionariesDao,
    PhilosophicalDialoguesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  Future<void> _consolidateSystemDictionaries() async {
    const names = ['一般辞書', '英語辞書', 'IT用語辞書'];

    await transaction(() async {
      for (final name in names) {
        final rows = await customSelect(
          'SELECT id, is_system FROM dictionary_definitions WHERE name = ? ORDER BY id ASC',
          variables: [Variable<String>(name)],
        ).get();

        if (rows.length <= 1) {
          continue;
        }

        int canonicalId = rows.first.read<int>('id');
        for (final row in rows) {
          if (row.read<int>('is_system') == 1) {
            canonicalId = row.read<int>('id');
            break;
          }
        }

        await customStatement(
          'UPDATE dictionary_definitions SET is_system = 1, is_work = 0 WHERE id = ?',
          [canonicalId],
        );

        final duplicateIds = rows
            .map((row) => row.read<int>('id'))
            .where((id) => id != canonicalId)
            .toList();

        for (final dupId in duplicateIds) {
          await _mergeDictionariesInternal(
            sourceId: dupId,
            targetId: canonicalId,
            deleteSource: true,
          );
        }
      }

      final englishTarget = await customSelect(
        'SELECT id FROM dictionary_definitions WHERE name = ? ORDER BY id ASC LIMIT 1',
        variables: [Variable<String>('英語辞書')],
      ).getSingleOrNull();
      if (englishTarget != null) {
        final englishTargetId = englishTarget.read<int>('id');
        final englishAliasRows = await customSelect(
          'SELECT id FROM dictionary_definitions WHERE name = ?',
          variables: [Variable<String>('英語用辞書')],
        ).get();
        for (final row in englishAliasRows) {
          await _mergeDictionariesInternal(
            sourceId: row.read<int>('id'),
            targetId: englishTargetId,
            deleteSource: true,
          );
        }
      }
    });
  }

  DateTime _coerceDateTime(Object? value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      final millis = value >= 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    if (value is double) {
      final raw = value.round();
      final millis = raw >= 1000000000000 ? raw : raw * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return DateTime.now();
      }
      final normalized =
          trimmed.contains('T') ? trimmed : trimmed.replaceFirst(' ', 'T');
      return DateTime.parse(normalized);
    }
    throw FormatException('Unsupported datetime value: $value');
  }

  @override
  int get schemaVersion => 9;

  Future<void> _normalizeDateTimeColumns() async {
    const tables = <String, List<String>>{
      'entries': ['created_at', 'updated_at'],
      'dictionary_definitions': ['created_at', 'updated_at'],
      'dictionary_entries': ['created_at', 'updated_at'],
      'dictionary_entry_values': ['created_at', 'updated_at'],
      'daily_memos': ['created_at', 'updated_at'],
      'concept_memos': ['created_at', 'updated_at'],
      'concept_dictionaries': ['created_at', 'updated_at'],
      'books': ['created_at', 'updated_at'],
      'reading_memos': ['created_at'],
      'reading_reflections': ['created_at'],
      'entry_appendices': ['created_at'],
      'philosophical_dialogues': ['created_at', 'updated_at'],
      'philosophical_messages': ['created_at'],
      'philosophical_concept_extractions': ['created_at'],
      'ai_sessions': ['created_at'],
    };

    for (final entry in tables.entries) {
      final table = entry.key;
      final exists = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable<String>(table)],
      ).getSingleOrNull();
      if (exists == null) {
        continue;
      }
      for (final column in entry.value) {
        await customStatement(
          "UPDATE $table SET $column = strftime('%s', $column) * 1000 WHERE typeof($column) = 'text'",
        );
        await customStatement(
          "UPDATE $table SET $column = $column * 1000 WHERE typeof($column) = 'integer' AND $column < 1000000000000",
        );
        await customStatement(
          "UPDATE $table SET $column = CAST($column * 1000 AS INTEGER) WHERE typeof($column) = 'real' AND $column < 1000000000000",
        );
      }
    }
  }

  Future<void> _ensureDictionaryDefinitionColumns() async {
    final columns = await customSelect(
      "PRAGMA table_info('dictionary_definitions')",
    ).get();
    final columnNames = columns.map((row) => row.read<String>('name')).toSet();

    if (!columnNames.contains('recommended_tags')) {
      await customStatement(
        'ALTER TABLE dictionary_definitions ADD COLUMN recommended_tags TEXT',
      );
    }
    if (!columnNames.contains('recommended_categories')) {
      await customStatement(
        'ALTER TABLE dictionary_definitions ADD COLUMN recommended_categories TEXT',
      );
    }
  }

  Future<void> ensureConceptDictionaryColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('concept_dictionaries')],
    ).getSingleOrNull();
    if (exists == null) {
      return;
    }

    final columns = await customSelect(
      "PRAGMA table_info('concept_dictionaries')",
    ).get();
    final columnNames = columns.map((row) => row.read<String>('name')).toSet();

    final requiredColumns = <String, String>{
      'category': 'TEXT',
      'tags': 'TEXT',
      'memo': 'TEXT',
      'reference_urls': 'TEXT',
      'similar_concepts': 'TEXT',
      'contrasting_concepts': 'TEXT',
      'related_concepts': 'TEXT',
      'cultural_background': 'TEXT',
      'practical_advice': 'TEXT',
      'case_studies': 'TEXT',
      'gyaru_explanation': 'TEXT',
      'child_explanation': 'TEXT',
      'origin': 'INTEGER NOT NULL DEFAULT 0',
      'created_at': 'INTEGER',
      'updated_at': 'INTEGER',
    };

    for (final entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key)) {
        await customStatement(
          'ALTER TABLE concept_dictionaries ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  List<Map<String, Object>> _allDictionaryFieldTemplates() {
    const baseFieldTemplates = [
      {
        'key': 'headword',
        'label': '見出し語',
        'type': 0,
        'required': true,
        'order': 0,
      },
      {
        'key': 'definition',
        'label': '説明・定義',
        'type': 1,
        'required': true,
        'order': 1,
      },
      {
        'key': 'memo',
        'label': 'メモ',
        'type': 1,
        'required': false,
        'order': 2,
      },
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': 3,
        'required': false,
        'order': 3,
      },
      {
        'key': 'synonyms',
        'label': '類義語',
        'type': 2,
        'required': false,
        'order': 4,
      },
      {
        'key': 'antonyms',
        'label': '対義語',
        'type': 2,
        'required': false,
        'order': 5,
      },
      {
        'key': 'related',
        'label': '関連語',
        'type': 2,
        'required': false,
        'order': 6,
      },
      {
        'key': 'examples',
        'label': '例文',
        'type': 2,
        'required': false,
        'order': 7,
      },
      {
        'key': 'etymology',
        'label': '語源',
        'type': 1,
        'required': false,
        'order': 8,
      },
      {
        'key': 'usage_note',
        'label': '使用上の注意',
        'type': 1,
        'required': false,
        'order': 9,
      },
    ];

    const extendedFieldTemplates = [
      {
        'key': 'cultural_background',
        'label': '文化的・歴史的背景',
        'type': 1,
        'required': false,
        'order': 10,
      },
      {
        'key': 'trivia',
        'label': '面白エピソード・トリビア',
        'type': 1,
        'required': false,
        'order': 11,
      },
      {
        'key': 'tips',
        'label': 'ワンポイントアドバイス',
        'type': 1,
        'required': false,
        'order': 12,
      },
      {
        'key': 'common_mistakes',
        'label': 'よくある誤用・間違い',
        'type': 1,
        'required': false,
        'order': 13,
      },
      {
        'key': 'emotional_tone',
        'label': '感情・ニュアンス',
        'type': 1,
        'required': false,
        'order': 14,
      },
      {
        'key': 'quotes',
        'label': '関連する名言・引用',
        'type': 2,
        'required': false,
        'order': 15,
      },
      {
        'key': 'contrasts',
        'label': '対比される概念',
        'type': 2,
        'required': false,
        'order': 16,
      },
      {
        'key': 'case_studies',
        'label': '実践例・ケーススタディ',
        'type': 1,
        'required': false,
        'order': 17,
      },
      {
        'key': 'derivatives',
        'label': '派生語・慣用句',
        'type': 2,
        'required': false,
        'order': 18,
      },
      {
        'key': 'pop_culture',
        'label': 'メディア・ポップカルチャー例',
        'type': 1,
        'required': false,
        'order': 19,
      },
      {
        'key': 'academic_context',
        'label': '学問分野での位置づけ',
        'type': 1,
        'required': false,
        'order': 20,
      },
      {
        'key': 'semantic_shift',
        'label': '意味の変遷',
        'type': 1,
        'required': false,
        'order': 21,
      },
      {
        'key': 'gyaru_explanation',
        'label': 'ギャルによる説明',
        'type': 1,
        'required': false,
        'order': 22,
      },
      {
        'key': 'child_explanation',
        'label': '幼稚園児でも理解できるよう説明',
        'type': 1,
        'required': false,
        'order': 23,
      },
    ];

    return [...baseFieldTemplates, ...extendedFieldTemplates];
  }

  Future<void> _ensureDictionaryFieldsPopulated() async {
    final dictRows = await customSelect(
      'SELECT id, name FROM dictionary_definitions',
    ).get();
    if (dictRows.isEmpty) {
      return;
    }

    final templates = _allDictionaryFieldTemplates();
    for (final row in dictRows) {
      final dictId = row.read<int>('id');
      final existingRows = await customSelect(
        'SELECT field_key FROM dictionary_fields WHERE dictionary_id = ?',
        variables: [Variable<int>(dictId)],
      ).get();
      final existingKeys =
          existingRows.map((r) => r.read<String>('field_key')).toSet();

      for (final template in templates) {
        final key = template['key'] as String;
        if (existingKeys.contains(key)) {
          continue;
        }
        await customStatement(
          'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            dictId,
            key,
            template['label'],
            template['type'],
            (template['required'] as bool) ? 1 : 0,
            (template['required'] as bool) ? 1 : 0,
            template['order'],
          ],
        );
      }
    }
  }

  String _formatTimestamp(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${time.year}'
        '${twoDigits(time.month)}'
        '${twoDigits(time.day)}_'
        '${twoDigits(time.hour)}'
        '${twoDigits(time.minute)}'
        '${twoDigits(time.second)}';
  }

  Future<void> _mergeDictionariesInternal({
    required int sourceId,
    required int targetId,
    bool deleteSource = true,
  }) async {
    if (sourceId == targetId) {
      return;
    }

    final sourceFields = await (select(dictionaryFields)
          ..where((t) => t.dictionaryId.equals(sourceId)))
        .get();
    final targetFields = await (select(dictionaryFields)
          ..where((t) => t.dictionaryId.equals(targetId)))
        .get();

    final targetFieldMap = {
      for (final field in targetFields) field.fieldKey: field.id,
    };
    final maxSortOrder = targetFields.isEmpty
        ? 0
        : targetFields.map((f) => f.sortOrder).reduce(
              (a, b) => a > b ? a : b,
            );
    var nextSortOrder = maxSortOrder + 1;

    for (final field in sourceFields) {
      if (targetFieldMap.containsKey(field.fieldKey)) {
        continue;
      }
      final newId = await into(dictionaryFields).insert(
        DictionaryFieldsCompanion.insert(
          dictionaryId: targetId,
          fieldKey: field.fieldKey,
          label: field.label,
          fieldType: field.fieldType,
          isRequired: Value(field.isRequired),
          isEnabled: Value(field.isEnabled),
          sortOrder: Value(nextSortOrder),
        ),
      );
      targetFieldMap[field.fieldKey] = newId;
      nextSortOrder += 1;
    }

    for (final field in sourceFields) {
      final targetFieldId = targetFieldMap[field.fieldKey];
      if (targetFieldId == null) {
        continue;
      }
      await customStatement(
        '''
        UPDATE dictionary_entry_values
        SET field_id = ?
        WHERE field_id = ?
          AND entry_id IN (
            SELECT id FROM dictionary_entries WHERE dictionary_id = ?
          )
        ''',
        [targetFieldId, field.id, sourceId],
      );
    }

    final nowUnix = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      '''
      UPDATE dictionary_entries
      SET dictionary_id = ?, updated_at = ?
      WHERE dictionary_id = ?
      ''',
      [targetId, nowUnix, sourceId],
    );

    if (deleteSource) {
      await customStatement(
        'DELETE FROM dictionary_fields WHERE dictionary_id = ?',
        [sourceId],
      );
      await customStatement(
        'DELETE FROM dictionary_definitions WHERE id = ?',
        [sourceId],
      );
    }
  }

  Future<void> mergeDictionaries({
    required int sourceId,
    required int targetId,
    bool deleteSource = true,
  }) async {
    await transaction(() async {
      await _mergeDictionariesInternal(
        sourceId: sourceId,
        targetId: targetId,
        deleteSource: deleteSource,
      );
    });
  }

  Future<void> deleteDictionaryCascade(int dictionaryId) async {
    await transaction(() async {
      await customStatement(
        '''
        DELETE FROM dictionary_entry_values
        WHERE entry_id IN (
          SELECT id FROM dictionary_entries WHERE dictionary_id = ?
        )
        ''',
        [dictionaryId],
      );
      await customStatement(
        'DELETE FROM dictionary_entries WHERE dictionary_id = ?',
        [dictionaryId],
      );
      await customStatement(
        'DELETE FROM dictionary_fields WHERE dictionary_id = ?',
        [dictionaryId],
      );
      await customStatement(
        'DELETE FROM dictionary_definitions WHERE id = ?',
        [dictionaryId],
      );
    });
  }

  Future<String> backupDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final source = File(p.join(dbFolder.path, 'noesis.db'));
    final backupsDir = Directory(p.join(dbFolder.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final timestamp = _formatTimestamp(DateTime.now());
    final backupPath = p.join(backupsDir.path, 'noesis_$timestamp.db');
    await source.copy(backupPath);
    return backupPath;
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();

      // FTS5テーブル作成
      await customStatement('''
            CREATE VIRTUAL TABLE entry_fts USING fts5(
              title, body, content='entries', content_rowid='id'
            );
          ''');

      await customStatement('''
            CREATE VIRTUAL TABLE quote_fts USING fts5(
              quote_text, content='quotes', content_rowid='id'
            );
          ''');

      // トリガー（FTS自動同期）
      await customStatement('''
            CREATE TRIGGER entry_ai AFTER INSERT ON entries BEGIN
              INSERT INTO entry_fts(rowid, title, body)
              VALUES (new.id, new.title, new.body);
            END;
          ''');

      await customStatement('''
            CREATE TRIGGER entry_au AFTER UPDATE ON entries BEGIN
              DELETE FROM entry_fts WHERE rowid = old.id;
              INSERT INTO entry_fts(rowid, title, body)
              VALUES (new.id, new.title, new.body);
            END;
          ''');

      await customStatement('''
            CREATE TRIGGER entry_ad AFTER DELETE ON entries BEGIN
              DELETE FROM entry_fts WHERE rowid = old.id;
            END;
          ''');

      await customStatement('''
            CREATE TRIGGER quote_ai AFTER INSERT ON quotes BEGIN
              INSERT INTO quote_fts(rowid, quote_text)
              VALUES (new.id, new.quote_text);
            END;
          ''');

      await customStatement('''
            CREATE TRIGGER quote_au AFTER UPDATE ON quotes BEGIN
              DELETE FROM quote_fts WHERE rowid = old.id;
              INSERT INTO quote_fts(rowid, quote_text)
              VALUES (new.id, new.quote_text);
            END;
          ''');

      await customStatement('''
            CREATE TRIGGER quote_ad AFTER DELETE ON quotes BEGIN
              DELETE FROM quote_fts WHERE rowid = old.id;
            END;
          ''');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.addColumn(conceptDictionaries, conceptDictionaries.origin);
        await m.createTable(philosophicalDialogues);
        await m.createTable(philosophicalMessages);
        await m.createTable(philosophicalConceptExtractions);
      }

      if (from < 3) {
        await m.createTable(dictionaryDefinitions);
        await m.createTable(dictionaryFields);
        await m.createTable(dictionaryEntries);
        await m.createTable(dictionaryEntryValues);

        final now = DateTime.now();
        final nowUnix = now.millisecondsSinceEpoch;

        await customStatement(
          '''
              INSERT INTO dictionary_definitions
                (name, description, is_system, is_work, category, created_at, updated_at)
              VALUES
                ('一般辞書', '基本となる辞書', 1, 0, 'general', ?, ?),
                ('英語辞書', '英語表現の辞書', 1, 0, 'english', ?, ?)
            ''',
          [nowUnix, nowUnix, nowUnix, nowUnix],
        );

        final techCount = await customSelect(
          'SELECT COUNT(*) AS cnt FROM entries WHERE type = 0 AND domain = 1',
        ).getSingle();

        if (techCount.read<int>('cnt') > 0) {
          await customStatement(
            '''
                INSERT INTO dictionary_definitions
                  (name, description, is_system, is_work, category, created_at, updated_at)
                VALUES
                  ('IT用語辞書', '既存データから移行', 0, 0, 'technology', ?, ?)
              ''',
            [nowUnix, nowUnix],
          );
        }

        final dictRows = await customSelect(
          'SELECT id, name FROM dictionary_definitions',
        ).get();

        int? generalId;
        int? englishId;
        int? techId;

        for (final row in dictRows) {
          final name = row.read<String>('name');
          if (name == '一般辞書') {
            generalId = row.read<int>('id');
          } else if (name == '英語辞書') {
            englishId = row.read<int>('id');
          } else if (name == 'IT用語辞書') {
            techId = row.read<int>('id');
          }
        }

        final fieldTemplates = [
          {
            'key': 'headword',
            'label': '見出し語',
            'type': 0,
            'required': true,
            'enabled': true,
            'order': 0,
          },
          {
            'key': 'definition',
            'label': '説明・定義',
            'type': 1,
            'required': true,
            'enabled': true,
            'order': 1,
          },
          {
            'key': 'memo',
            'label': 'メモ',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 2,
          },
          {
            'key': 'reference_urls',
            'label': '参考URL',
            'type': 3,
            'required': false,
            'enabled': true,
            'order': 3,
          },
          {
            'key': 'synonyms',
            'label': '類義語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 4,
          },
          {
            'key': 'antonyms',
            'label': '対義語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 5,
          },
          {
            'key': 'related',
            'label': '関連語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 6,
          },
          {
            'key': 'examples',
            'label': '例文',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 7,
          },
          {
            'key': 'etymology',
            'label': '語源',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 8,
          },
          {
            'key': 'usage_note',
            'label': '使用上の注意',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 9,
          },
        ];

        for (final dictId in [generalId, englishId, techId]) {
          if (dictId == null) {
            continue;
          }
          for (final template in fieldTemplates) {
            await customStatement(
              'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
              [
                dictId,
                template['key'],
                template['label'],
                template['type'],
                (template['required'] as bool) ? 1 : 0,
                (template['enabled'] as bool) ? 1 : 0,
                template['order'],
              ],
            );
          }
        }

        if (generalId != null || englishId != null || techId != null) {
          final entries = await customSelect(
            'SELECT id, title, body, domain, created_at, updated_at FROM entries WHERE type = 0',
          ).get();
          int toUnixSeconds(DateTime value) =>
              value.toUtc().millisecondsSinceEpoch;

          for (final row in entries) {
            final entryId = row.read<int>('id');
            final domain = row.read<int>('domain');
            int? dictId;
            if (domain == 2) {
              dictId = englishId ?? generalId;
            } else if (domain == 1) {
              dictId = techId ?? generalId;
            } else {
              dictId = generalId;
            }
            if (dictId == null) {
              continue;
            }

            await customStatement(
              'INSERT INTO dictionary_entries (id, dictionary_id, headword, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
              [
                entryId,
                dictId,
                row.read<String>('title'),
                toUnixSeconds(
                  _coerceDateTime(row.read<Object?>('created_at')),
                ),
                toUnixSeconds(
                  _coerceDateTime(row.read<Object?>('updated_at')),
                ),
              ],
            );
          }

          final fieldRows = await customSelect(
            'SELECT id, dictionary_id, field_key FROM dictionary_fields',
          ).get();

          final fieldMap = <int, Map<String, int>>{};
          for (final row in fieldRows) {
            final dictId = row.read<int>('dictionary_id');
            fieldMap.putIfAbsent(dictId, () => {});
            fieldMap[dictId]![row.read<String>('field_key')] = row.read<int>(
              'id',
            );
          }

          for (final row in entries) {
            final entryId = row.read<int>('id');
            final domain = row.read<int>('domain');
            int? dictId;
            if (domain == 2) {
              dictId = englishId ?? generalId;
            } else if (domain == 1) {
              dictId = techId ?? generalId;
            } else {
              dictId = generalId;
            }
            if (dictId == null) {
              continue;
            }
            final fieldIds = fieldMap[dictId] ?? {};
            final definitionFieldId = fieldIds['definition'];
            if (definitionFieldId != null) {
              await customStatement(
                'INSERT OR REPLACE INTO dictionary_entry_values (entry_id, field_id, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
                [entryId, definitionFieldId, row.read<String>('body'), nowUnix, nowUnix],
              );
            }
          }

          final englishRows = await customSelect(
            'SELECT entry_id, definition_ja, synonyms_json, antonyms_json, related_terms_json, examples_json, etymology, usage_note FROM english_lexicons',
          ).get();

          if (englishId != null) {
            final fieldIds = fieldMap[englishId] ?? {};
            for (final row in englishRows) {
              final entryId = row.read<int>('entry_id');
              final pairs = [
                {
                  'key': 'definition',
                  'value': row.read<String>('definition_ja'),
                },
                {'key': 'synonyms', 'value': row.read<String>('synonyms_json')},
                {'key': 'antonyms', 'value': row.read<String>('antonyms_json')},
                {
                  'key': 'related',
                  'value': row.read<String>('related_terms_json'),
                },
                {'key': 'examples', 'value': row.read<String>('examples_json')},
                {'key': 'etymology', 'value': row.read<String>('etymology')},
                {'key': 'usage_note', 'value': row.read<String>('usage_note')},
              ];

              for (final pair in pairs) {
                final fieldId = fieldIds[pair['key']];
                final value = (pair['value'] ?? '').toString();
                if (fieldId != null && value.trim().isNotEmpty) {
                  await customStatement(
                    'INSERT OR REPLACE INTO dictionary_entry_values (entry_id, field_id, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
                    [entryId, fieldId, value, nowUnix, nowUnix],
                  );
                }
              }
            }
          }
        }
      }

      if (from < 4) {
        final now = DateTime.now();
        final nowUnix = now.millisecondsSinceEpoch;

        final systemDefinitions = [
          {'name': '一般辞書', 'category': 'general'},
          {'name': '英語辞書', 'category': 'english'},
          {'name': 'IT用語辞書', 'category': 'technology'},
        ];

        for (final def in systemDefinitions) {
          final existing = await customSelect(
            'SELECT id FROM dictionary_definitions WHERE name = ? LIMIT 1',
            variables: [Variable<String>(def['name'] as String)],
          ).getSingleOrNull();
          if (existing == null) {
            await customStatement(
              'INSERT INTO dictionary_definitions (name, description, is_system, is_work, category, created_at, updated_at) VALUES (?, ?, 1, 0, ?, ?, ?)',
              [def['name'], '基本辞書', def['category'], nowUnix, nowUnix],
            );
          } else {
            await customStatement(
              'UPDATE dictionary_definitions SET is_system = 1, is_work = 0 WHERE name = ?',
              [def['name']],
            );
          }
        }

        final dictRows = await customSelect(
          'SELECT id, name FROM dictionary_definitions',
        ).get();

        final fieldTemplates = [
          {
            'key': 'headword',
            'label': '見出し語',
            'type': 0,
            'required': true,
            'enabled': true,
            'order': 0,
          },
          {
            'key': 'definition',
            'label': '説明・定義',
            'type': 1,
            'required': true,
            'enabled': true,
            'order': 1,
          },
          {
            'key': 'memo',
            'label': 'メモ',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 2,
          },
          {
            'key': 'reference_urls',
            'label': '参考URL',
            'type': 3,
            'required': false,
            'enabled': true,
            'order': 3,
          },
          {
            'key': 'synonyms',
            'label': '類義語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 4,
          },
          {
            'key': 'antonyms',
            'label': '対義語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 5,
          },
          {
            'key': 'related',
            'label': '関連語',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 6,
          },
          {
            'key': 'examples',
            'label': '例文',
            'type': 2,
            'required': false,
            'enabled': true,
            'order': 7,
          },
          {
            'key': 'etymology',
            'label': '語源',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 8,
          },
          {
            'key': 'usage_note',
            'label': '使用上の注意',
            'type': 1,
            'required': false,
            'enabled': true,
            'order': 9,
          },
        ];

        for (final row in dictRows) {
          final dictId = row.read<int>('id');
          final countRow = await customSelect(
            'SELECT COUNT(*) AS cnt FROM dictionary_fields WHERE dictionary_id = ?',
            variables: [Variable<int>(dictId)],
          ).getSingle();
          if (countRow.read<int>('cnt') == 0) {
            for (final template in fieldTemplates) {
              await customStatement(
                'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [
                  dictId,
                  template['key'],
                  template['label'],
                  template['type'],
                  (template['required'] as bool) ? 1 : 0,
                  (template['enabled'] as bool) ? 1 : 0,
                  template['order'],
                ],
              );
            }
          }
        }

        final entries = await customSelect(
          'SELECT id, title, body, domain, created_at, updated_at FROM entries WHERE type = 0',
        ).get();
        int toUnixSeconds(DateTime value) =>
            value.toUtc().millisecondsSinceEpoch;

        int? generalId;
        int? englishId;
        int? techId;
        for (final row in dictRows) {
          final name = row.read<String>('name');
          if (name == '一般辞書') {
            generalId = row.read<int>('id');
          } else if (name == '英語辞書') {
            englishId = row.read<int>('id');
          } else if (name == 'IT用語辞書') {
            techId = row.read<int>('id');
          }
        }

        for (final row in entries) {
          final entryId = row.read<int>('id');
          final domain = row.read<int>('domain');
          int? dictId;
          if (domain == 2) {
            dictId = englishId ?? generalId;
          } else if (domain == 1) {
            dictId = techId ?? generalId;
          } else {
            dictId = generalId;
          }
          if (dictId == null) {
            continue;
          }
          await customStatement(
            'INSERT OR IGNORE INTO dictionary_entries (id, dictionary_id, headword, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
            [
              entryId,
              dictId,
              row.read<String>('title'),
              toUnixSeconds(
                _coerceDateTime(row.read<Object?>('created_at')),
              ),
              toUnixSeconds(
                _coerceDateTime(row.read<Object?>('updated_at')),
              ),
            ],
          );
        }

        final fieldRows = await customSelect(
          'SELECT id, dictionary_id, field_key FROM dictionary_fields',
        ).get();
        final fieldMap = <int, Map<String, int>>{};
        for (final row in fieldRows) {
          final dictId = row.read<int>('dictionary_id');
          fieldMap.putIfAbsent(dictId, () => {});
          fieldMap[dictId]![row.read<String>('field_key')] = row.read<int>(
            'id',
          );
        }

        for (final row in entries) {
          final entryId = row.read<int>('id');
          final domain = row.read<int>('domain');
          int? dictId;
          if (domain == 2) {
            dictId = englishId ?? generalId;
          } else if (domain == 1) {
            dictId = techId ?? generalId;
          } else {
            dictId = generalId;
          }
          if (dictId == null) {
            continue;
          }
          final fieldIds = fieldMap[dictId] ?? {};
          final definitionFieldId = fieldIds['definition'];
          if (definitionFieldId != null) {
            await customStatement(
              'INSERT OR REPLACE INTO dictionary_entry_values (entry_id, field_id, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
              [entryId, definitionFieldId, row.read<String>('body'), nowUnix, nowUnix],
            );
          }
        }

        final englishRows = await customSelect(
          'SELECT entry_id, definition_ja, synonyms_json, antonyms_json, related_terms_json, examples_json, etymology, usage_note FROM english_lexicons',
        ).get();
        if (englishId != null) {
          final fieldIds = fieldMap[englishId] ?? {};
          for (final row in englishRows) {
            final entryId = row.read<int>('entry_id');
            final pairs = [
              {
                'key': 'definition',
                'value': row.read<String>('definition_ja'),
              },
              {'key': 'synonyms', 'value': row.read<String>('synonyms_json')},
              {'key': 'antonyms', 'value': row.read<String>('antonyms_json')},
              {
                'key': 'related',
                'value': row.read<String>('related_terms_json'),
              },
              {'key': 'examples', 'value': row.read<String>('examples_json')},
              {'key': 'etymology', 'value': row.read<String>('etymology')},
              {'key': 'usage_note', 'value': row.read<String>('usage_note')},
            ];

            for (final pair in pairs) {
              final fieldId = fieldIds[pair['key']];
              final value = (pair['value'] ?? '').toString();
              if (fieldId != null && value.trim().isNotEmpty) {
                await customStatement(
                  'INSERT OR REPLACE INTO dictionary_entry_values (entry_id, field_id, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
                  [entryId, fieldId, value, nowUnix, nowUnix],
                );
              }
            }
          }
        }
      }

      if (from < 5) {
        // Add category and tags columns to dictionary_entries
        await m.addColumn(dictionaryEntries, dictionaryEntries.category);
        await m.addColumn(dictionaryEntries, dictionaryEntries.tags);
      }

      if (from < 6) {
        // Add category and tags columns to concept_dictionaries
        await m.addColumn(conceptDictionaries, conceptDictionaries.category);
        await m.addColumn(conceptDictionaries, conceptDictionaries.tags);

        // Add category and tags columns to daily_memos
        await m.addColumn(dailyMemos, dailyMemos.category);
        await m.addColumn(dailyMemos, dailyMemos.tags);

        // Add category and tags columns to philosophical_dialogues
        await m.addColumn(philosophicalDialogues, philosophicalDialogues.category);
        await m.addColumn(philosophicalDialogues, philosophicalDialogues.tags);
      }

      if (from < 7) {
        await m.addColumn(
          dictionaryDefinitions,
          dictionaryDefinitions.recommendedTags,
        );
        await m.addColumn(
          dictionaryDefinitions,
          dictionaryDefinitions.recommendedCategories,
        );
        await _normalizeDateTimeColumns();
      }

      if (from < 8) {
        await _normalizeDateTimeColumns();
      }

      if (from < 9) {
        await m.addColumn(conceptDictionaries, conceptDictionaries.gyaruExplanation);
        await m.addColumn(conceptDictionaries, conceptDictionaries.childExplanation);
      }
    },
  );

  Future<void> ensureDictionaryRecovery() async {
    try {
      debugPrint('[DB] ensureDictionaryRecovery: Starting dictionary recovery check');

      final countRow = await customSelect(
        'SELECT COUNT(*) AS cnt FROM dictionary_definitions',
      ).getSingle();

      final count = countRow.read<int>('cnt');
      debugPrint('[DB] ensureDictionaryRecovery: Found $count dictionaries');

      if (count > 0) {
        await _ensureDictionaryDefinitionColumns();
        await _ensureDictionaryFieldsPopulated();
        await _consolidateSystemDictionaries();
        debugPrint('[DB] ensureDictionaryRecovery: Dictionaries exist, no recovery needed');
        return;
      }

      debugPrint('[DB] ensureDictionaryRecovery: No dictionaries found, starting recovery...');
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR in ensureDictionaryRecovery (count check): $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    try {
      debugPrint('[DB] ensureDictionaryRecovery: Inserting default dictionaries...');
      final now = DateTime.now();
    final nowUnix = now.millisecondsSinceEpoch;

      await customStatement(
        '''
        INSERT INTO dictionary_definitions
          (name, description, is_system, is_work, category, created_at, updated_at)
        VALUES
          ('一般辞書', '基本となる辞書', 1, 0, 'general', ?, ?),
          ('英語辞書', '英語表現の辞書', 1, 0, 'english', ?, ?),
          ('IT用語辞書', '技術用語の辞書', 1, 0, 'technology', ?, ?)
        ''',
        [nowUnix, nowUnix, nowUnix, nowUnix, nowUnix, nowUnix],
      );
      debugPrint('[DB] ensureDictionaryRecovery: Default dictionaries inserted');
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR inserting default dictionaries: $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    List<QueryRow> dictRows;
    try {
      debugPrint('[DB] ensureDictionaryRecovery: Querying created dictionaries...');
      dictRows = await customSelect(
        'SELECT id, name FROM dictionary_definitions',
      ).get();
      debugPrint('[DB] ensureDictionaryRecovery: Found ${dictRows.length} dictionaries');
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR querying dictionaries: $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    // 全辞書共通の基本フィールド
    final baseFieldTemplates = [
      {
        'key': 'headword',
        'label': '見出し語',
        'type': 0,
        'required': true,
        'order': 0,
      },
      {
        'key': 'definition',
        'label': '説明・定義',
        'type': 1,
        'required': true,
        'order': 1,
      },
      {
        'key': 'memo',
        'label': 'メモ',
        'type': 1,
        'required': false,
        'order': 2,
      },
      {
        'key': 'synonyms',
        'label': '類義語',
        'type': 2,
        'required': false,
        'order': 4,
      },
      {
        'key': 'antonyms',
        'label': '対義語',
        'type': 2,
        'required': false,
        'order': 5,
      },
      {
        'key': 'related',
        'label': '関連語',
        'type': 2,
        'required': false,
        'order': 6,
      },
      {
        'key': 'examples',
        'label': '例文',
        'type': 2,
        'required': false,
        'order': 7,
      },
      {
        'key': 'etymology',
        'label': '語源・背景',
        'type': 1,
        'required': false,
        'order': 8,
      },
      {
        'key': 'usage_note',
        'label': '使用上の注意',
        'type': 1,
        'required': false,
        'order': 9,
      },
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': 3,
        'required': false,
        'order': 10,
      },
    ];

    // 追加フィールド（辞書タイプによって有効/無効を切り替え）
    final extendedFieldTemplates = [
      {
        'key': 'cultural_background',
        'label': '文化的・歴史的背景',
        'type': 1,
        'required': false,
        'order': 11,
      },
      {
        'key': 'trivia',
        'label': '面白エピソード・トリビア',
        'type': 1,
        'required': false,
        'order': 12,
      },
      {
        'key': 'tips',
        'label': 'ワンポイントアドバイス',
        'type': 1,
        'required': false,
        'order': 13,
      },
      {
        'key': 'common_mistakes',
        'label': 'よくある誤用・間違い',
        'type': 1,
        'required': false,
        'order': 14,
      },
      {
        'key': 'emotional_tone',
        'label': '感情・ニュアンス',
        'type': 1,
        'required': false,
        'order': 15,
      },
      {
        'key': 'quotes',
        'label': '関連する名言・引用',
        'type': 1,
        'required': false,
        'order': 16,
      },
      {
        'key': 'contrasts',
        'label': '対比される概念',
        'type': 1,
        'required': false,
        'order': 17,
      },
      {
        'key': 'case_studies',
        'label': '実践例・ケーススタディ',
        'type': 1,
        'required': false,
        'order': 18,
      },
      {
        'key': 'derivatives',
        'label': '派生語・慣用句',
        'type': 2,
        'required': false,
        'order': 19,
      },
      {
        'key': 'pop_culture',
        'label': 'メディア・ポップカルチャー例',
        'type': 1,
        'required': false,
        'order': 20,
      },
      {
        'key': 'academic_context',
        'label': '学問分野での位置づけ',
        'type': 1,
        'required': false,
        'order': 21,
      },
      {
        'key': 'semantic_shift',
        'label': '意味の変遷',
        'type': 1,
        'required': false,
        'order': 22,
      },
      {
        'key': 'gyaru_explanation',
        'label': 'ギャルによる説明',
        'type': 1,
        'required': false,
        'order': 23,
      },
      {
        'key': 'child_explanation',
        'label': '幼稚園児でも理解できるよう説明',
        'type': 1,
        'required': false,
        'order': 24,
      },
    ];

    // 辞書タイプごとの推奨フィールド設定
    final Map<String, Set<String>> recommendedFields = {
      '一般辞書': {
        'headword', 'definition', 'memo', 'synonyms', 'antonyms', 'related',
        'examples', 'etymology', 'usage_note', 'reference_urls',
        'cultural_background', 'trivia', 'emotional_tone', 'common_mistakes',
        'semantic_shift', 'quotes', 'derivatives',
      },
      '英語辞書': {
        'headword', 'definition', 'memo', 'synonyms', 'antonyms', 'related',
        'examples', 'etymology', 'usage_note', 'reference_urls',
        'cultural_background', 'emotional_tone', 'common_mistakes', 'tips',
        'derivatives', 'contrasts',
      },
      'IT用語辞書': {
        'headword', 'definition', 'memo', 'synonyms', 'antonyms', 'related',
        'examples', 'usage_note', 'reference_urls',
        'tips', 'common_mistakes', 'case_studies', 'contrasts',
        'academic_context',
      },
    };

    try {
      debugPrint('[DB] ensureDictionaryRecovery: Inserting fields for ${dictRows.length} dictionaries...');
      for (final row in dictRows) {
        final dictId = row.read<int>('id');
        final dictName = row.read<String>('name');
        debugPrint('[DB] ensureDictionaryRecovery: Inserting fields for dictionary $dictId ($dictName)');

        // この辞書の推奨フィールド
        final enabledKeys = recommendedFields[dictName] ?? <String>{};

        // 全フィールドを結合
        final allFields = [...baseFieldTemplates, ...extendedFieldTemplates];

        for (final template in allFields) {
          final fieldKey = template['key'] as String;
          final isEnabled = enabledKeys.contains(fieldKey);

          await customStatement(
            'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              dictId,
              fieldKey,
              template['label'],
              template['type'],
              (template['required'] as bool) ? 1 : 0,
              isEnabled ? 1 : 0,
              template['order'],
            ],
          );
        }
      }
      debugPrint('[DB] ensureDictionaryRecovery: All fields inserted');
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR inserting fields: $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    final entries = await customSelect(
      'SELECT id, title, body, domain, created_at, updated_at FROM entries WHERE type = 0',
    ).get();
    int toUnixSeconds(DateTime value) =>
        value.toUtc().millisecondsSinceEpoch;

    final nowUnix = DateTime.now().millisecondsSinceEpoch;

    int? generalId;
    int? englishId;
    int? techId;
    for (final row in dictRows) {
      final name = row.read<String>('name');
      if (name == '一般辞書') {
        generalId = row.read<int>('id');
      } else if (name == '英語辞書') {
        englishId = row.read<int>('id');
      } else if (name == 'IT用語辞書') {
        techId = row.read<int>('id');
      }
    }

    for (final row in entries) {
      final entryId = row.read<int>('id');
      final domain = row.read<int>('domain');
      int? dictId;
      if (domain == 2) {
        dictId = englishId ?? generalId;
      } else if (domain == 1) {
        dictId = techId ?? generalId;
      } else {
        dictId = generalId;
      }
      if (dictId == null) {
        continue;
      }
      await customStatement(
        'INSERT OR IGNORE INTO dictionary_entries (id, dictionary_id, headword, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
        [
          entryId,
          dictId,
          row.read<String>('title'),
          toUnixSeconds(
            _coerceDateTime(row.read<Object?>('created_at')),
          ),
          toUnixSeconds(
            _coerceDateTime(row.read<Object?>('updated_at')),
          ),
        ],
      );
    }

    final fieldRows = await customSelect(
      'SELECT id, dictionary_id, field_key FROM dictionary_fields',
    ).get();
    final fieldMap = <int, Map<String, int>>{};
    for (final row in fieldRows) {
      final dictId = row.read<int>('dictionary_id');
      fieldMap.putIfAbsent(dictId, () => {});
      fieldMap[dictId]![row.read<String>('field_key')] = row.read<int>('id');
    }

    for (final row in entries) {
      final entryId = row.read<int>('id');
      final domain = row.read<int>('domain');
      int? dictId;
      if (domain == 2) {
        dictId = englishId ?? generalId;
      } else if (domain == 1) {
        dictId = techId ?? generalId;
      } else {
        dictId = generalId;
      }
      if (dictId == null) {
        continue;
      }
      final fieldIds = fieldMap[dictId] ?? {};
      final definitionFieldId = fieldIds['definition'];
      if (definitionFieldId != null) {
        await customStatement(
          'INSERT OR REPLACE INTO dictionary_entry_values (entry_id, field_id, value, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
          [entryId, definitionFieldId, row.read<String>('body'), nowUnix, nowUnix],
        );
      }
    }

    debugPrint('[DB] ensureDictionaryRecovery: Recovery complete!');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'noesis.db'));
    return NativeDatabase(file);
  });
}
