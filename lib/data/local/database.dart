import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/utils/listening_audio_storage.dart';

import 'tables/ai_sessions_table.dart';
import 'tables/archive_entries_table.dart';
import 'tables/archive_targets_table.dart';
import 'tables/books_table.dart';
import 'tables/book_ai_entries_table.dart';
import 'tables/code_entries_table.dart';
import 'tables/code_entry_entries_table.dart';
import 'tables/concept_dictionaries_table.dart';
import 'tables/concept_memos_table.dart';
import 'tables/daily_memos_table.dart';
import 'tables/daily_memo_entries_table.dart';
import 'tables/dictionary_fields_table.dart';
import 'tables/dictionary_entry_values_table.dart';
import 'tables/dictionary_entries_table.dart';
import 'tables/dictionary_definitions_table.dart';
import 'tables/english_lexicons_table.dart';
import 'tables/entries_table.dart';
import 'tables/entry_appendices_table.dart';
import 'tables/person_profile_attributes_table.dart';
import 'tables/philosophical_concept_extractions_table.dart';
import 'tables/philosophical_dialogues_table.dart';
import 'tables/philosophical_messages_table.dart';
import 'tables/quotes_table.dart';
import 'tables/reading_memos_table.dart';
import 'tables/reading_memo_entries_table.dart';
import 'tables/reading_reflections_table.dart';
import 'tables/spot_links_table.dart';
import 'tables/spot_messages_table.dart';
import 'tables/spot_visits_table.dart';
import 'tables/spots_table.dart';
import 'tables/sources_table.dart';
import 'tables/tags_table.dart';
import 'tables/talking_topic_messages_table.dart';
import 'tables/talking_topic_sources_table.dart';
import 'tables/talking_topic_usages_table.dart';
import 'tables/talking_topics_table.dart';
import 'tables/podcast_episodes_table.dart';
import 'tables/episode_clips_table.dart';
import 'tables/episode_clip_entries_table.dart';
import 'tables/episode_ai_entries_table.dart';
import 'dao/entries_dao.dart';
import 'dao/archive_targets_dao.dart';
import 'dao/code_entries_dao.dart';
import 'dao/code_entry_entries_dao.dart';
import 'dao/concept_memos_dao.dart';
import 'dao/daily_memos_dao.dart';
import 'dao/daily_memo_entries_dao.dart';
import 'dao/dictionaries_dao.dart';
import 'dao/philosophical_dialogues_dao.dart';
import 'dao/quotes_dao.dart';
import 'dao/books_dao.dart';
import 'dao/book_ai_entries_dao.dart';
import 'dao/person_profile_attributes_dao.dart';
import 'dao/reading_memos_dao.dart';
import 'dao/reading_memo_entries_dao.dart';
import 'dao/spots_dao.dart';
import 'dao/talking_topics_dao.dart';
import 'dao/podcast_episodes_dao.dart';
import 'dao/episode_clips_dao.dart';
import 'dao/episode_clip_entries_dao.dart';
import 'dao/episode_ai_entries_dao.dart';

part 'database.g.dart';

class DatabaseRuntimeStatus {
  final bool isCompatible;
  final int userVersion;
  final String databasePath;
  final List<String> issues;

  const DatabaseRuntimeStatus({
    required this.isCompatible,
    required this.userVersion,
    required this.databasePath,
    required this.issues,
  });
}

@DriftDatabase(
  tables: [
    Entries,
    EnglishLexicons,
    EntryAppendices,
    PersonProfileAttributes,
    Books,
    BookAiEntries,
    ReadingMemos,
    ReadingMemoEntries,
    ReadingReflections,
    Spots,
    SpotVisits,
    SpotLinks,
    SpotMessages,
    CodeEntries,
    CodeEntryEntries,
    ConceptDictionaries,
    ConceptMemos,
    DailyMemos,
    DailyMemoEntries,
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
    ArchiveTargets,
    ArchiveEntries,
    PhilosophicalDialogues,
    PhilosophicalMessages,
    PhilosophicalConceptExtractions,
    TalkingTopics,
    TalkingTopicSources,
    TalkingTopicUsages,
    TalkingTopicMessages,
    PodcastEpisodes,
    EpisodeClips,
    EpisodeClipEntries,
    EpisodeAiEntries,
  ],
  daos: [
    EntriesDao,
    ArchiveTargetsDao,
    PersonProfileAttributesDao,
    CodeEntriesDao,
    CodeEntryEntriesDao,
    ConceptMemosDao,
    DailyMemosDao,
    DailyMemoEntriesDao,
    DictionariesDao,
    PhilosophicalDialoguesDao,
    QuotesDao,
    BooksDao,
    BookAiEntriesDao,
    ReadingMemosDao,
    ReadingMemoEntriesDao,
    SpotsDao,
    TalkingTopicsDao,
    PodcastEpisodesDao,
    EpisodeClipsDao,
    EpisodeClipEntriesDao,
    EpisodeAiEntriesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  Future<DatabaseRuntimeStatus> inspectRuntimeStatus() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final databasePath = p.join(dbFolder.path, 'noesis.db');

    final versionRow = await customSelect('PRAGMA user_version').getSingle();
    final userVersion = versionRow.read<int>('user_version');

    Future<bool> tableExists(String name) async {
      final row = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable<String>(name)],
      ).getSingleOrNull();
      return row != null;
    }

    Future<Set<String>> columnNamesOf(String tableName) async {
      final rows = await customSelect("PRAGMA table_info('$tableName')").get();
      return rows.map((row) => row.read<String>('name')).toSet();
    }

    final issues = <String>[];

    if (userVersion < 19) {
      issues.add(
        'DB schema version が古すぎます（現在: $userVersion / 必要: 19以上）',
      );
    }

    final hasBooks = await tableExists('books');
    if (!hasBooks) {
      issues.add('books テーブルが存在しません');
    } else {
      final columns = await columnNamesOf('books');
      if (!columns.contains('cover_image_path')) {
        issues.add('books.cover_image_path 列が存在しません');
      }
    }

    final hasPodcastEpisodes = await tableExists('podcast_episodes');
    if (!hasPodcastEpisodes) {
      issues.add('podcast_episodes テーブルが存在しません');
    }

    final hasEpisodeClips = await tableExists('episode_clips');
    if (!hasEpisodeClips) {
      issues.add('episode_clips テーブルが存在しません');
    } else {
      final columns = await columnNamesOf('episode_clips');
      if (!columns.contains('audio_file_path')) {
        issues.add('episode_clips.audio_file_path 列が存在しません');
      }
    }

    return DatabaseRuntimeStatus(
      isCompatible: issues.isEmpty,
      userVersion: userVersion,
      databasePath: databasePath,
      issues: issues,
    );
  }

  Future<void> _consolidateSystemDictionaries() async {
    const names = ['一般辞書', '英語辞書', 'IT用語辞書', '人物辞典'];

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

  static const String _personDictionaryName = '人物辞典';

  List<Map<String, Object>> _personDictionaryFieldTemplates() {
    return const [
      {
        'key': 'reading',
        'label': '読み方',
        'type': 0,
        'required': false,
        'order': 1,
      },
      {
        'key': 'definition',
        'label': '人物概要',
        'type': 1,
        'required': true,
        'order': 2,
      },
      {
        'key': 'aliases',
        'label': '別名・別表記',
        'type': 2,
        'required': false,
        'order': 3,
      },
      {
        'key': 'era',
        'label': '活躍した時代',
        'type': 0,
        'required': false,
        'order': 4,
      },
      {
        'key': 'birth_death',
        'label': '生没年',
        'type': 0,
        'required': false,
        'order': 5,
      },
      {
        'key': 'birth_place',
        'label': '出身地・出生地',
        'type': 0,
        'required': false,
        'order': 6,
      },
      {
        'key': 'nationality',
        'label': '国・地域',
        'type': 0,
        'required': false,
        'order': 7,
      },
      {
        'key': 'occupations',
        'label': '肩書き・役割',
        'type': 2,
        'required': false,
        'order': 8,
      },
      {
        'key': 'organizations',
        'label': '所属組織・陣営',
        'type': 2,
        'required': false,
        'order': 9,
      },
      {
        'key': 'achievements',
        'label': '代表的な業績・作品',
        'type': 1,
        'required': false,
        'order': 10,
      },
      {
        'key': 'thought',
        'label': '思想・立場',
        'type': 1,
        'required': false,
        'order': 11,
      },
      {
        'key': 'chronology',
        'label': '主要出来事・年表',
        'type': 1,
        'required': false,
        'order': 12,
      },
      {
        'key': 'relationships',
        'label': '関連人物',
        'type': 2,
        'required': false,
        'order': 13,
      },
      {
        'key': 'evaluation',
        'label': '人物像・評価',
        'type': 1,
        'required': false,
        'order': 14,
      },
      {
        'key': 'quotes',
        'label': '名言・発言',
        'type': 1,
        'required': false,
        'order': 15,
      },
      {
        'key': 'cultural_background',
        'label': '時代背景・社会背景',
        'type': 1,
        'required': false,
        'order': 16,
      },
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': 3,
        'required': false,
        'order': 17,
      },
      {
        'key': 'memo',
        'label': '補足メモ',
        'type': 1,
        'required': false,
        'order': 18,
      },
      {
        'key': 'trivia',
        'label': '人物エピソード',
        'type': 1,
        'required': false,
        'order': 19,
      },
      {
        'key': 'related',
        'label': '関連項目',
        'type': 2,
        'required': false,
        'order': 20,
      },
      {
        'key': 'academic_context',
        'label': '研究・受容上の位置づけ',
        'type': 1,
        'required': false,
        'order': 21,
      },
    ];
  }

  Future<void> _ensurePersonDictionaryDefinition() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final recommendedCategories = jsonEncode([
      '思想家',
      '作家',
      '科学者',
      '芸術家',
      '音楽家',
      '政治家',
      '実業家',
      '宗教家',
      '歴史人物',
      '俳優',
      'スポーツ選手',
    ]);
    final recommendedTags = jsonEncode([
      '日本',
      '海外',
      '近代',
      '現代',
      '文学',
      '哲学',
      '科学',
      '芸術',
      '政治',
      '歴史',
    ]);

    final existing = await customSelect(
      'SELECT id FROM dictionary_definitions WHERE name = ? ORDER BY id ASC LIMIT 1',
      variables: [Variable<String>(_personDictionaryName)],
    ).getSingleOrNull();

    if (existing == null) {
      await customStatement(
        '''
        INSERT INTO dictionary_definitions
          (name, description, is_system, is_work, category, reference_domain, recommended_tags, recommended_categories, created_at, updated_at)
        VALUES (?, ?, 1, 0, 'people', 0, ?, ?, ?, ?)
        ''',
        [
          _personDictionaryName,
          '著名人・歴史上の人物を整理するための辞典',
          recommendedTags,
          recommendedCategories,
          now,
          now,
        ],
      );
      return;
    }

    await customStatement(
      '''
      UPDATE dictionary_definitions
      SET description = ?,
          is_system = 1,
          is_work = 0,
          category = 'people',
          reference_domain = 0,
          recommended_tags = ?,
          recommended_categories = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      [
        '著名人・歴史上の人物を整理するための辞典',
        recommendedTags,
        recommendedCategories,
        now,
        existing.read<int>('id'),
      ],
    );
  }

  Future<void> _ensurePersonDictionaryFields() async {
    final dictionary = await customSelect(
      'SELECT id FROM dictionary_definitions WHERE name = ? ORDER BY id ASC LIMIT 1',
      variables: [Variable<String>(_personDictionaryName)],
    ).getSingleOrNull();
    if (dictionary == null) {
      return;
    }

    final dictionaryId = dictionary.read<int>('id');
    final existingRows = await customSelect(
      'SELECT id, field_key FROM dictionary_fields WHERE dictionary_id = ?',
      variables: [Variable<int>(dictionaryId)],
    ).get();
    final existingFieldIds = {
      for (final row in existingRows)
        row.read<String>('field_key'): row.read<int>('id'),
    };

    for (final template in _personDictionaryFieldTemplates()) {
      final fieldKey = template['key']! as String;
      final label = template['label']! as String;
      final type = template['type']! as int;
      final required = template['required']! as bool;
      final order = template['order']! as int;
      final existingId = existingFieldIds[fieldKey];

      if (existingId == null) {
        await customStatement(
          'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, 1, ?)',
          [dictionaryId, fieldKey, label, type, required ? 1 : 0, order],
        );
      } else {
        await customStatement(
          'UPDATE dictionary_fields SET label = ?, field_type = ?, is_required = ?, is_enabled = 1, sort_order = ? WHERE id = ?',
          [label, type, required ? 1 : 0, order, existingId],
        );
      }
    }
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
      final normalized = trimmed.contains('T')
          ? trimmed
          : trimmed.replaceFirst(' ', 'T');
      return DateTime.parse(normalized);
    }
    throw FormatException('Unsupported datetime value: $value');
  }

  @override
  int get schemaVersion => 21;

  Future<void> _normalizeDateTimeColumns() async {
    const tables = <String, List<String>>{
      'entries': ['created_at', 'updated_at'],
      'dictionary_definitions': ['created_at', 'updated_at'],
      'dictionary_entries': ['created_at', 'updated_at'],
      'dictionary_entry_values': ['created_at', 'updated_at'],
      'daily_memos': ['created_at', 'updated_at'],
      'daily_memo_entries': ['created_at'],
      'concept_memos': ['created_at', 'updated_at'],
      'concept_dictionaries': ['created_at', 'updated_at'],
      'books': ['created_at', 'updated_at'],
      'reading_memos': ['created_at'],
      'reading_memo_entries': ['created_at'],
      'reading_reflections': ['created_at'],
      'entry_appendices': ['created_at'],
      'philosophical_dialogues': ['created_at', 'updated_at'],
      'philosophical_messages': ['created_at'],
      'philosophical_concept_extractions': ['created_at'],
      'ai_sessions': ['created_at'],
      'code_entries': ['created_at', 'updated_at'],
      'code_entry_entries': ['created_at'],
      'archive_targets': ['created_at', 'updated_at'],
      'archive_entries': ['happened_at', 'created_at'],
      'person_profile_attributes': ['created_at', 'updated_at'],
      'spots': [
        'first_visited_at',
        'last_visited_at',
        'created_at',
        'updated_at',
      ],
      'spot_visits': ['visited_at', 'created_at'],
      'spot_links': ['created_at'],
      'spot_messages': ['created_at'],
      'talking_topics': ['created_at', 'updated_at'],
      'talking_topic_sources': ['created_at'],
      'talking_topic_usages': ['used_at', 'created_at'],
      'talking_topic_messages': ['created_at'],
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
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

    Future<void> addCol(String name, String typeSql) async {
      if (!columnNames.contains(name.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE dictionary_definitions ADD COLUMN $name $typeSql',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE dictionary_definitions ADD COLUMN $name failed (ignored): $e');
        }
      }
    }

    await addCol('recommended_tags', 'TEXT');
    await addCol('recommended_categories', 'TEXT');
    await addCol('reference_domain', 'INTEGER NOT NULL DEFAULT 0');
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
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

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
      if (!columnNames.contains(entry.key.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE concept_dictionaries ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE concept_dictionaries ADD COLUMN ${entry.key} failed (ignored): $e');
        }
      }
    }
  }

  Future<void> ensureBooksColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('books')],
    ).getSingleOrNull();
    if (exists == null) {
      return;
    }

    final columns = await customSelect("PRAGMA table_info('books')").get();
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

    final requiredColumns = <String, String>{
      'genre': 'TEXT',
      'publisher': 'TEXT',
      'published_date': 'TEXT',
      'isbn': 'TEXT',
      'synopsis': 'TEXT',
      'rating': 'TEXT',
      'related_url': 'TEXT',
      'review_summary': 'TEXT',
      'cover_image_path': 'TEXT',
      'created_at': 'INTEGER',
      'updated_at': 'INTEGER',
    };

    for (final entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE books ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE books ADD COLUMN ${entry.key} failed (ignored): $e');
        }
      }
    }
  }

  Future<void> ensureReadingMemosColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('reading_memos')],
    ).getSingleOrNull();
    if (exists == null) {
      return;
    }

    final columns = await customSelect(
      "PRAGMA table_info('reading_memos')",
    ).get();
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

    final requiredColumns = <String, String>{
      'section_title': 'TEXT',
      'page_number': 'TEXT',
      'updated_at': 'INTEGER',
      'type': 'INTEGER NOT NULL DEFAULT 0', // 0 = excerpt (デフォルト)
      'excerpt_text': 'TEXT',
      'thought_text': 'TEXT NOT NULL DEFAULT \'\'',
    };

    for (final entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE reading_memos ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE reading_memos ADD COLUMN ${entry.key} failed (ignored): $e');
        }
      }
    }
  }

  Future<void> ensurePodcastEpisodesColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('podcast_episodes')],
    ).getSingleOrNull();
    if (exists == null) return;

    final columns =
        await customSelect("PRAGMA table_info('podcast_episodes')").get();
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

    final requiredColumns = <String, String>{
      'genre': 'TEXT',
      'synopsis': 'TEXT',
      'rating': 'TEXT',
      'related_url': 'TEXT',
      'review_summary': 'TEXT',
    };

    for (final entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE podcast_episodes ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE podcast_episodes ADD COLUMN ${entry.key} failed (ignored): $e');
        }
      }
    }
  }

  Future<void> ensureEpisodeClipsColumns() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('episode_clips')],
    ).getSingleOrNull();
    if (exists == null) return;

    final columns =
        await customSelect("PRAGMA table_info('episode_clips')").get();
    final columnNames = columns
        .map((row) => (row.data['name'] ?? row.read<String>('name')).toString().toLowerCase())
        .toSet();

    final requiredColumns = <String, String>{
      'title': 'TEXT',
      'memo_type': 'INTEGER NOT NULL DEFAULT 0',
      'audio_file_path': 'TEXT',
      'duration_seconds': 'INTEGER',
      'transcript': 'TEXT',
    };

    for (final entry in requiredColumns.entries) {
      if (!columnNames.contains(entry.key.toLowerCase())) {
        try {
          await customStatement(
            'ALTER TABLE episode_clips ADD COLUMN ${entry.key} ${entry.value}',
          );
        } catch (e) {
          debugPrint('[DB] ALTER TABLE episode_clips ADD COLUMN ${entry.key} failed (ignored): $e');
        }
      }
    }
  }

  Future<void> _ensureReadingMemoEntriesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('reading_memo_entries')],
    ).getSingleOrNull();

    if (exists != null) {
      return; // テーブルが既に存在する
    }

    // テーブルを作成
    await customStatement('''
      CREATE TABLE reading_memo_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memo_id INTEGER NOT NULL,
        entry_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        question TEXT,
        thinking_style_name TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
  }

  Future<void> _ensureDailyMemoEntriesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('daily_memo_entries')],
    ).getSingleOrNull();

    if (exists != null) {
      return; // テーブルが既に存在する
    }

    // テーブルを作成
    await customStatement('''
      CREATE TABLE daily_memo_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memo_id INTEGER NOT NULL,
        entry_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        question TEXT,
        thinking_style_name TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
  }

  Future<void> _ensureEpisodeClipEntriesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('episode_clip_entries')],
    ).getSingleOrNull();

    if (exists != null) {
      return;
    }

    await customStatement('''
      CREATE TABLE episode_clip_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clip_id INTEGER NOT NULL,
        entry_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        question TEXT,
        thinking_style_name TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
  }

  Future<void> _ensureBookAiEntriesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('book_ai_entries')],
    ).getSingleOrNull();

    if (exists != null) return;

    await customStatement('''
      CREATE TABLE book_ai_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        entry_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        question TEXT,
        thinking_style_name TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
  }

  Future<void> _ensureEpisodeAiEntriesTable() async {
    final exists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('episode_ai_entries')],
    ).getSingleOrNull();

    if (exists != null) return;

    await customStatement('''
      CREATE TABLE episode_ai_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        episode_id INTEGER NOT NULL,
        entry_type INTEGER NOT NULL,
        content TEXT NOT NULL,
        question TEXT,
        thinking_style_name TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');
  }

  /// ITコード学習の新しいカラムを追加
  Future<void> _ensureCodeEntriesColumns() async {
    // 既存のテーブル構造を確認
    final tableInfo = await customSelect(
      "PRAGMA table_info(code_entries)",
    ).get();

    final existingColumns = tableInfo
        .map((row) => row.data['name'] as String)
        .toSet();

    // 追加が必要なカラムのリスト
    final newColumns = {
      'synonymous_codes': 'TEXT',
      'antonymous_codes': 'TEXT',
      'related_codes': 'TEXT',
      'examples': 'TEXT',
      'cautions': 'TEXT',
      'trivia': 'TEXT',
      'tips': 'TEXT',
      'common_mistakes': 'TEXT',
      'gyaru_explanation': 'TEXT',
      'kindergarten_explanation': 'TEXT',
      'learning_level': 'INTEGER',
    };

    // 存在しないカラムを追加
    for (final entry in newColumns.entries) {
      if (!existingColumns.contains(entry.key)) {
        await customStatement(
          'ALTER TABLE code_entries ADD COLUMN ${entry.key} ${entry.value}',
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
        'key': 'reading',
        'label': '読み方',
        'type': 0,
        'required': false,
        'order': 1,
      },
      {
        'key': 'definition',
        'label': '説明・定義',
        'type': 1,
        'required': true,
        'order': 2,
      },
      {'key': 'memo', 'label': 'メモ', 'type': 1, 'required': false, 'order': 3},
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': 3,
        'required': false,
        'order': 4,
      },
      {
        'key': 'synonyms',
        'label': '類義語',
        'type': 2,
        'required': false,
        'order': 5,
      },
      {
        'key': 'antonyms',
        'label': '対義語',
        'type': 2,
        'required': false,
        'order': 6,
      },
      {
        'key': 'related',
        'label': '関連語',
        'type': 2,
        'required': false,
        'order': 7,
      },
      {
        'key': 'examples',
        'label': '例文',
        'type': 2,
        'required': false,
        'order': 8,
      },
      {
        'key': 'etymology',
        'label': '語源',
        'type': 1,
        'required': false,
        'order': 9,
      },
      {
        'key': 'usage_note',
        'label': '使用上の注意',
        'type': 1,
        'required': false,
        'order': 10,
      },
    ];

    const extendedFieldTemplates = [
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
        'type': 2,
        'required': false,
        'order': 16,
      },
      {
        'key': 'contrasts',
        'label': '対比される概念',
        'type': 2,
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
      {
        'key': 'part_of_speech',
        'label': '品詞',
        'type': 2,
        'required': false,
        'order': 25,
      },
      {
        'key': 'verb_forms',
        'label': '動詞の活用',
        'type': 2,
        'required': false,
        'order': 26,
      },
      {
        'key': 'noun_usage',
        'label': '名詞としての用法',
        'type': 1,
        'required': false,
        'order': 27,
      },
      {
        'key': 'verb_usage',
        'label': '動詞としての用法',
        'type': 1,
        'required': false,
        'order': 28,
      },
      {
        'key': 'adjective_usage',
        'label': '形容詞としての用法',
        'type': 1,
        'required': false,
        'order': 29,
      },
      {
        'key': 'adverb_usage',
        'label': '副詞としての用法',
        'type': 1,
        'required': false,
        'order': 30,
      },
    ];

    return [...baseFieldTemplates, ...extendedFieldTemplates];
  }

  Future<void> _ensureDictionaryFieldsPopulated() async {
    final dictRows = await customSelect(
      'SELECT id, name, category FROM dictionary_definitions',
    ).get();
    if (dictRows.isEmpty) {
      return;
    }

    const alwaysEnabledKeys = {'reading'};
    final Map<String, Set<String>> recommendedFields = {
      '一般辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'etymology',
        'usage_note',
        'reference_urls',
        'cultural_background',
        'trivia',
        'emotional_tone',
        'common_mistakes',
        'semantic_shift',
        'quotes',
        'derivatives',
      },
      '英語辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'etymology',
        'usage_note',
        'reference_urls',
        'cultural_background',
        'emotional_tone',
        'common_mistakes',
        'tips',
        'derivatives',
        'contrasts',
        'part_of_speech',
        'verb_forms',
        'noun_usage',
        'verb_usage',
        'adjective_usage',
        'adverb_usage',
      },
      'IT用語辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'usage_note',
        'reference_urls',
        'tips',
        'common_mistakes',
        'case_studies',
        'contrasts',
        'academic_context',
      },
    };
    final templates = _allDictionaryFieldTemplates();
    for (final row in dictRows) {
      final dictId = row.read<int>('id');
      final dictName = row.read<String>('name');
      final dictCategory = row.read<String?>('category');
      if (dictName == _personDictionaryName || dictCategory == 'people') {
        await _ensurePersonDictionaryFields();
        continue;
      }
      final existingRows = await customSelect(
        'SELECT field_key FROM dictionary_fields WHERE dictionary_id = ?',
        variables: [Variable<int>(dictId)],
      ).get();
      final existingKeys = existingRows
          .map((r) => r.read<String>('field_key'))
          .toSet();
      final enabledKeys =
          recommendedFields[dictName] ??
          (dictCategory == 'english'
              ? (recommendedFields['英語辞書'] ?? <String>{})
              : <String>{});

      for (final template in templates) {
        final key = template['key'] as String;
        if (existingKeys.contains(key)) {
          continue;
        }
        final isEnabled =
            (template['required'] as bool) ||
            alwaysEnabledKeys.contains(key) ||
            enabledKeys.contains(key);
        await customStatement(
          'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [
            dictId,
            key,
            template['label'],
            template['type'],
            (template['required'] as bool) ? 1 : 0,
            isEnabled ? 1 : 0,
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

    final sourceFields = await (select(
      dictionaryFields,
    )..where((t) => t.dictionaryId.equals(sourceId))).get();
    final targetFields = await (select(
      dictionaryFields,
    )..where((t) => t.dictionaryId.equals(targetId))).get();

    final targetFieldMap = {
      for (final field in targetFields) field.fieldKey: field.id,
    };
    final maxSortOrder = targetFields.isEmpty
        ? 0
        : targetFields.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b);
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
      await customStatement('DELETE FROM dictionary_definitions WHERE id = ?', [
        sourceId,
      ]);
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
      await customStatement('DELETE FROM dictionary_definitions WHERE id = ?', [
        dictionaryId,
      ]);
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
      Future<void> safeAddColumn(TableInfo table, GeneratedColumn column) async {
        try {
          await m.addColumn(table, column);
        } catch (e) {
          debugPrint(
            '[DB Migration] Add column ${column.name} to ${table.actualTableName} ignored: $e',
          );
        }
      }

      if (from == 1) {
        await safeAddColumn(conceptDictionaries, conceptDictionaries.origin);
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
                toUnixSeconds(_coerceDateTime(row.read<Object?>('created_at'))),
                toUnixSeconds(_coerceDateTime(row.read<Object?>('updated_at'))),
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
                [
                  entryId,
                  definitionFieldId,
                  row.read<String>('body'),
                  nowUnix,
                  nowUnix,
                ],
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
              toUnixSeconds(_coerceDateTime(row.read<Object?>('created_at'))),
              toUnixSeconds(_coerceDateTime(row.read<Object?>('updated_at'))),
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
              [
                entryId,
                definitionFieldId,
                row.read<String>('body'),
                nowUnix,
                nowUnix,
              ],
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
              {'key': 'definition', 'value': row.read<String>('definition_ja')},
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
        await safeAddColumn(dictionaryEntries, dictionaryEntries.category);
        await safeAddColumn(dictionaryEntries, dictionaryEntries.tags);
      }

      if (from < 6) {
        // Add category and tags columns to concept_dictionaries
        await safeAddColumn(conceptDictionaries, conceptDictionaries.category);
        await safeAddColumn(conceptDictionaries, conceptDictionaries.tags);

        // Add category and tags columns to daily_memos
        await safeAddColumn(dailyMemos, dailyMemos.category);
        await safeAddColumn(dailyMemos, dailyMemos.tags);

        // Add category and tags columns to philosophical_dialogues
        await safeAddColumn(
          philosophicalDialogues,
          philosophicalDialogues.category,
        );
        await safeAddColumn(philosophicalDialogues, philosophicalDialogues.tags);
      }

      if (from < 7) {
        await safeAddColumn(
          dictionaryDefinitions,
          dictionaryDefinitions.recommendedTags,
        );
        await safeAddColumn(
          dictionaryDefinitions,
          dictionaryDefinitions.recommendedCategories,
        );
        await _normalizeDateTimeColumns();
      }

      if (from < 8) {
        await _normalizeDateTimeColumns();
      }

      if (from < 9) {
        await safeAddColumn(
          conceptDictionaries,
          conceptDictionaries.gyaruExplanation,
        );
        await safeAddColumn(
          conceptDictionaries,
          conceptDictionaries.childExplanation,
        );
      }

      if (from < 10) {
        // Add new columns to quotes table for Quote Capture feature
        await safeAddColumn(quotes, quotes.sectionTitle);
        await safeAddColumn(quotes, quotes.sourceImagePath);
        await safeAddColumn(quotes, quotes.createdAt);
        await safeAddColumn(quotes, quotes.updatedAt);
      }

      if (from < 12) {
        await m.createTable(archiveTargets);
        await m.createTable(archiveEntries);
      }

      if (from < 13) {
        await m.createTable(personProfileAttributes);
        await safeAddColumn(archiveEntries, archiveEntries.dataType);
        await safeAddColumn(archiveEntries, archiveEntries.confidenceScore);
        await safeAddColumn(archiveEntries, archiveEntries.source);
        await safeAddColumn(archiveEntries, archiveEntries.updatedAt);
      }

      if (from < 14) {
        await m.createTable(talkingTopics);
        await m.createTable(talkingTopicSources);
        await m.createTable(talkingTopicUsages);
        await m.createTable(talkingTopicMessages);
      }

      if (from < 15) {
        await safeAddColumn(talkingTopics, talkingTopics.referenceUrls);
      }

      if (from < 16) {
        await m.createTable(spots);
        await m.createTable(spotVisits);
        await m.createTable(spotLinks);
        await m.createTable(spotMessages);
      }

      if (from < 17) {
        await safeAddColumn(spots, spots.latitude);
        await safeAddColumn(spots, spots.longitude);
        await safeAddColumn(spots, spots.placeId);
        await safeAddColumn(spots, spots.geocodeSource);
        await safeAddColumn(spots, spots.mapLabel);
        await safeAddColumn(spots, spots.isMapVisible);
        await safeAddColumn(spots, spots.mapPinColor);
      }

      if (from < 18) {
        await safeAddColumn(spots, spots.photoPath);
        await safeAddColumn(spotVisits, spotVisits.photoPath);
      }

      if (from < 19) {
        await m.createTable(podcastEpisodes);
        await m.createTable(episodeClips);
      }

      if (from < 20) {
        await m.createTable(episodeClipEntries);
      }

      if (from < 21) {
        await m.createTable(bookAiEntries);
        await m.createTable(episodeAiEntries);
      }
    },
    beforeOpen: (details) async {
      try {
        await ensureBooksColumns();
      } catch (e) {
        debugPrint('[DB] ensureBooksColumns failed: $e');
      }
      try {
        await ensureReadingMemosColumns();
      } catch (e) {
        debugPrint('[DB] ensureReadingMemosColumns failed: $e');
      }
      try {
        await ensureConceptDictionaryColumns();
      } catch (e) {
        debugPrint('[DB] ensureConceptDictionaryColumns failed: $e');
      }
      try {
        await _ensureReadingMemoEntriesTable();
      } catch (e) {
        debugPrint('[DB] _ensureReadingMemoEntriesTable failed: $e');
      }
      try {
        await _ensureDailyMemoEntriesTable();
      } catch (e) {
        debugPrint('[DB] _ensureDailyMemoEntriesTable failed: $e');
      }
      try {
        await _ensureCodeEntriesTables();
      } catch (e) {
        debugPrint('[DB] _ensureCodeEntriesTables failed: $e');
      }
      try {
        await ensurePodcastEpisodesColumns();
      } catch (e) {
        debugPrint('[DB] ensurePodcastEpisodesColumns failed: $e');
      }
      try {
        await ensureEpisodeClipsColumns();
      } catch (e) {
        debugPrint('[DB] ensureEpisodeClipsColumns failed: $e');
      }
      try {
        await _ensureEpisodeClipEntriesTable();
      } catch (e) {
        debugPrint('[DB] _ensureEpisodeClipEntriesTable failed: $e');
      }
      try {
        await _ensureBookAiEntriesTable();
      } catch (e) {
        debugPrint('[DB] _ensureBookAiEntriesTable failed: $e');
      }
      try {
        await _ensureEpisodeAiEntriesTable();
      } catch (e) {
        debugPrint('[DB] _ensureEpisodeAiEntriesTable failed: $e');
      }
      try {
        await _rescueExternalListeningAudio();
      } catch (e) {
        debugPrint('[DB] _rescueExternalListeningAudio failed: $e');
      }
    },
  );

  Future<void> _rescueExternalListeningAudio() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(docsDir.path, 'listening_audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    Future<String> copyIfNeeded(String originalPath, String prefix) async {
      final source = File(originalPath);
      if (!await source.exists()) {
        return originalPath;
      }
      if (originalPath.startsWith(audioDir.path)) {
        return originalPath;
      }
      final extension = p.extension(originalPath).isEmpty
          ? '.m4a'
          : p.extension(originalPath);
      final targetPath = p.join(
        audioDir.path,
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await source.copy(targetPath);
      return targetPath;
    }

    final clipRows = await customSelect(
      'SELECT id, audio_file_path FROM episode_clips WHERE audio_file_path IS NOT NULL',
    ).get();
    for (final row in clipRows) {
      final id = row.read<int>('id');
      final audioPath = row.read<String>('audio_file_path');
      if (!ListeningAudioStorage.isRescuableExternalPath(audioPath)) {
        continue;
      }
      final rescuedPath = await copyIfNeeded(audioPath, 'clip_$id');
      if (rescuedPath != audioPath) {
        await customStatement(
          'UPDATE episode_clips SET audio_file_path = ?, updated_at = ? WHERE id = ?',
          [rescuedPath, DateTime.now().millisecondsSinceEpoch, id],
        );
      }
    }

    final episodeRows = await customSelect(
      'SELECT id, audio_file_path FROM podcast_episodes WHERE audio_file_path IS NOT NULL',
    ).get();
    for (final row in episodeRows) {
      final id = row.read<int>('id');
      final audioPath = row.read<String>('audio_file_path');
      if (!ListeningAudioStorage.isRescuableExternalPath(audioPath)) {
        continue;
      }
      final rescuedPath = await copyIfNeeded(audioPath, 'episode_$id');
      if (rescuedPath != audioPath) {
        await customStatement(
          'UPDATE podcast_episodes SET audio_file_path = ?, updated_at = ? WHERE id = ?',
          [rescuedPath, DateTime.now().millisecondsSinceEpoch, id],
        );
      }
    }
  }

  Future<void> _ensureCodeEntriesTables() async {
    // Check if code_entries table exists
    final codeEntriesExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('code_entries')],
    ).getSingleOrNull();

    if (codeEntriesExists == null) {
      // Create code_entries table
      await customStatement('''
        CREATE TABLE code_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          code TEXT NOT NULL,
          entry_type INTEGER NOT NULL,
          language TEXT,
          libraries TEXT,
          structure TEXT,
          capabilities TEXT,
          use_cases TEXT,
          learning_points TEXT,
          tags TEXT,
          category TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
        )
      ''');
    }

    // Check if code_entry_entries table exists
    final codeEntryEntriesExists = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>('code_entry_entries')],
    ).getSingleOrNull();

    if (codeEntryEntriesExists == null) {
      // Create code_entry_entries table
      await customStatement('''
        CREATE TABLE code_entry_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code_entry_id INTEGER NOT NULL,
          entry_type INTEGER NOT NULL,
          content TEXT NOT NULL,
          thinking_style_name TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
        )
      ''');
    }

    // Ensure new columns exist in code_entries table
    await _ensureCodeEntriesColumns();
  }

  Future<void> ensureDictionaryRecovery() async {
    try {
      debugPrint(
        '[DB] ensureDictionaryRecovery: Starting dictionary recovery check',
      );

      final countRow = await customSelect(
        'SELECT COUNT(*) AS cnt FROM dictionary_definitions',
      ).getSingle();

      final count = countRow.read<int>('cnt');
      debugPrint('[DB] ensureDictionaryRecovery: Found $count dictionaries');

      if (count > 0) {
        await _ensureDictionaryDefinitionColumns();
        await _ensurePersonDictionaryDefinition();
        await _ensureDictionaryFieldsPopulated();
        await _consolidateSystemDictionaries();
        debugPrint(
          '[DB] ensureDictionaryRecovery: Dictionaries exist, no recovery needed',
        );
        return;
      }

      debugPrint(
        '[DB] ensureDictionaryRecovery: No dictionaries found, starting recovery...',
      );
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR in ensureDictionaryRecovery (count check): $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    try {
      debugPrint(
        '[DB] ensureDictionaryRecovery: Inserting default dictionaries...',
      );
      final now = DateTime.now();
      final nowUnix = now.millisecondsSinceEpoch;

      await customStatement(
        '''
        INSERT INTO dictionary_definitions
          (name, description, is_system, is_work, category, created_at, updated_at)
        VALUES
          ('一般辞書', '基本となる辞書', 1, 0, 'general', ?, ?),
          ('英語辞書', '英語表現の辞書', 1, 0, 'english', ?, ?),
          ('IT用語辞書', '技術用語の辞書', 1, 0, 'technology', ?, ?),
          ('人物辞典', '著名人・歴史上の人物を整理するための辞典', 1, 0, 'people', ?, ?)
        ''',
        [
          nowUnix,
          nowUnix,
          nowUnix,
          nowUnix,
          nowUnix,
          nowUnix,
          nowUnix,
          nowUnix,
        ],
      );
      debugPrint(
        '[DB] ensureDictionaryRecovery: Default dictionaries inserted',
      );
      await _ensurePersonDictionaryDefinition();
    } catch (e, stackTrace) {
      debugPrint('[DB] ERROR inserting default dictionaries: $e');
      debugPrint('[DB] Stack trace: $stackTrace');
      rethrow;
    }

    List<QueryRow> dictRows;
    try {
      debugPrint(
        '[DB] ensureDictionaryRecovery: Querying created dictionaries...',
      );
      dictRows = await customSelect(
        'SELECT id, name FROM dictionary_definitions',
      ).get();
      debugPrint(
        '[DB] ensureDictionaryRecovery: Found ${dictRows.length} dictionaries',
      );
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
        'key': 'reading',
        'label': '読み方',
        'type': 0,
        'required': false,
        'order': 1,
      },
      {
        'key': 'definition',
        'label': '説明・定義',
        'type': 1,
        'required': true,
        'order': 2,
      },
      {'key': 'memo', 'label': 'メモ', 'type': 1, 'required': false, 'order': 3},
      {
        'key': 'synonyms',
        'label': '類義語',
        'type': 2,
        'required': false,
        'order': 5,
      },
      {
        'key': 'antonyms',
        'label': '対義語',
        'type': 2,
        'required': false,
        'order': 6,
      },
      {
        'key': 'related',
        'label': '関連語',
        'type': 2,
        'required': false,
        'order': 7,
      },
      {
        'key': 'examples',
        'label': '例文',
        'type': 2,
        'required': false,
        'order': 8,
      },
      {
        'key': 'etymology',
        'label': '語源・背景',
        'type': 1,
        'required': false,
        'order': 9,
      },
      {
        'key': 'usage_note',
        'label': '使用上の注意',
        'type': 1,
        'required': false,
        'order': 10,
      },
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': 3,
        'required': false,
        'order': 4,
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
      {
        'key': 'part_of_speech',
        'label': '品詞',
        'type': 2,
        'required': false,
        'order': 25,
      },
      {
        'key': 'verb_forms',
        'label': '動詞の活用',
        'type': 2,
        'required': false,
        'order': 26,
      },
      {
        'key': 'noun_usage',
        'label': '名詞としての用法',
        'type': 1,
        'required': false,
        'order': 27,
      },
      {
        'key': 'verb_usage',
        'label': '動詞としての用法',
        'type': 1,
        'required': false,
        'order': 28,
      },
      {
        'key': 'adjective_usage',
        'label': '形容詞としての用法',
        'type': 1,
        'required': false,
        'order': 29,
      },
      {
        'key': 'adverb_usage',
        'label': '副詞としての用法',
        'type': 1,
        'required': false,
        'order': 30,
      },
    ];

    // 辞書タイプごとの推奨フィールド設定
    final Map<String, Set<String>> recommendedFields = {
      '一般辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'etymology',
        'usage_note',
        'reference_urls',
        'cultural_background',
        'trivia',
        'emotional_tone',
        'common_mistakes',
        'semantic_shift',
        'quotes',
        'derivatives',
      },
      '英語辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'etymology',
        'usage_note',
        'reference_urls',
        'cultural_background',
        'emotional_tone',
        'common_mistakes',
        'tips',
        'derivatives',
        'contrasts',
        'part_of_speech',
        'verb_forms',
        'noun_usage',
        'verb_usage',
        'adjective_usage',
        'adverb_usage',
      },
      'IT用語辞書': {
        'headword',
        'reading',
        'definition',
        'memo',
        'synonyms',
        'antonyms',
        'related',
        'examples',
        'usage_note',
        'reference_urls',
        'tips',
        'common_mistakes',
        'case_studies',
        'contrasts',
        'academic_context',
      },
    };

    try {
      debugPrint(
        '[DB] ensureDictionaryRecovery: Inserting fields for ${dictRows.length} dictionaries...',
      );
      for (final row in dictRows) {
        final dictId = row.read<int>('id');
        final dictName = row.read<String>('name');
        debugPrint(
          '[DB] ensureDictionaryRecovery: Inserting fields for dictionary $dictId ($dictName)',
        );

        // この辞書の推奨フィールド
        if (dictName == _personDictionaryName) {
          for (final template in _personDictionaryFieldTemplates()) {
            await customStatement(
              'INSERT INTO dictionary_fields (dictionary_id, field_key, label, field_type, is_required, is_enabled, sort_order) VALUES (?, ?, ?, ?, ?, 1, ?)',
              [
                dictId,
                template['key'],
                template['label'],
                template['type'],
                (template['required'] as bool) ? 1 : 0,
                template['order'],
              ],
            );
          }
          continue;
        }

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
    int toUnixSeconds(DateTime value) => value.toUtc().millisecondsSinceEpoch;

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
          toUnixSeconds(_coerceDateTime(row.read<Object?>('created_at'))),
          toUnixSeconds(_coerceDateTime(row.read<Object?>('updated_at'))),
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
          [
            entryId,
            definitionFieldId,
            row.read<String>('body'),
            nowUnix,
            nowUnix,
          ],
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
