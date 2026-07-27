import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';

import '../../data/local/database.dart';

/// CSV/TXT export utility for archive data.
class DataExportService {
  static Future<File> exportDialoguesCsv() async {
    final db = AppDatabase();
    try {
      final dialogues = await db.philosophicalDialoguesDao.getAllDialogues();
      final lines = <String>[
        _csvRow([
          'dialogue_id',
          'dialogue_title',
          'dialogue_category',
          'dialogue_tags',
          'dialogue_created_at',
          'dialogue_updated_at',
          'message_id',
          'message_created_at',
          'role',
          'input_type',
          'persona',
          'content',
          'image_path',
        ]),
      ];

      for (final dialogue in dialogues) {
        final messages = await db.philosophicalDialoguesDao
            .getMessagesByDialogue(dialogue.id);
        if (messages.isEmpty) {
          lines.add(
            _csvRow([
              dialogue.id,
              dialogue.title,
              dialogue.category ?? '',
              _jsonArrayToPipeString(dialogue.tags),
              _iso(dialogue.createdAt),
              _iso(dialogue.updatedAt),
              '',
              '',
              '',
              '',
              '',
              '',
              '',
            ]),
          );
          continue;
        }
        for (final message in messages) {
          lines.add(
            _csvRow([
              dialogue.id,
              dialogue.title,
              dialogue.category ?? '',
              _jsonArrayToPipeString(dialogue.tags),
              _iso(dialogue.createdAt),
              _iso(dialogue.updatedAt),
              message.id,
              _iso(message.createdAt),
              message.role.name,
              message.inputType.name,
              message.persona ?? '',
              message.content,
              message.imagePath ?? '',
            ]),
          );
        }
      }

      final path = await _buildExportPath('dialogues', ext: 'csv');
      final file = File(path);
      return file.writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<File> exportDictionariesCsv() async {
    final db = AppDatabase();
    try {
      final dictionaries = await db.dictionariesDao.getAllDictionaries();
      final lines = <String>[
        _csvRow([
          'dictionary_id',
          'dictionary_name',
          'dictionary_category',
          'entry_id',
          'headword',
          'entry_category',
          'entry_tags',
          'entry_created_at',
          'entry_updated_at',
          'field_id',
          'field_key',
          'field_label',
          'field_type',
          'field_value',
        ]),
      ];

      for (final dict in dictionaries) {
        final fields = await db.dictionariesDao.getFields(dict.id);
        final fieldById = {for (final field in fields) field.id: field};
        final entries = await db.dictionariesDao.getEntries(dict.id);

        if (entries.isEmpty) {
          lines.add(
            _csvRow([
              dict.id,
              dict.name,
              dict.category ?? '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
            ]),
          );
          continue;
        }

        for (final entry in entries) {
          final values = await db.dictionariesDao.getEntryValues(entry.id);
          if (values.isEmpty) {
            lines.add(
              _csvRow([
                dict.id,
                dict.name,
                dict.category ?? '',
                entry.id,
                entry.headword,
                entry.category ?? '',
                _jsonArrayToPipeString(entry.tags),
                _iso(entry.createdAt),
                _iso(entry.updatedAt),
                '',
                '',
                '',
                '',
                '',
              ]),
            );
            continue;
          }

          for (final value in values) {
            final field = fieldById[value.fieldId];
            lines.add(
              _csvRow([
                dict.id,
                dict.name,
                dict.category ?? '',
                entry.id,
                entry.headword,
                entry.category ?? '',
                _jsonArrayToPipeString(entry.tags),
                _iso(entry.createdAt),
                _iso(entry.updatedAt),
                value.fieldId,
                field?.fieldKey ?? '',
                field?.label ?? '',
                field?.fieldType.name ?? '',
                value.value,
              ]),
            );
          }
        }
      }

      final path = await _buildExportPath('dictionaries', ext: 'csv');
      final file = File(path);
      return file.writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<File> exportConceptDictionariesCsv() async {
    final db = AppDatabase();
    try {
      final items = await (db.select(
        db.conceptDictionaries,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

      final lines = <String>[
        _csvRow([
          'id',
          'title',
          'body',
          'category',
          'tags',
          'memo',
          'reference_urls',
          'similar_concepts',
          'contrasting_concepts',
          'related_concepts',
          'cultural_background',
          'practical_advice',
          'case_studies',
          'gyaru_explanation',
          'child_explanation',
          'origin',
          'created_at',
          'updated_at',
        ]),
      ];

      for (final row in items) {
        lines.add(
          _csvRow([
            row.id,
            row.title,
            row.body,
            row.category ?? '',
            _jsonArrayToPipeString(row.tags),
            row.memo ?? '',
            _jsonArrayToPipeString(row.referenceUrls),
            _jsonArrayToPipeString(row.similarConcepts),
            _jsonArrayToPipeString(row.contrastingConcepts),
            _jsonArrayToPipeString(row.relatedConcepts),
            row.culturalBackground ?? '',
            row.practicalAdvice ?? '',
            row.caseStudies ?? '',
            row.gyaruExplanation ?? '',
            row.childExplanation ?? '',
            row.origin.name,
            _iso(row.createdAt),
            _iso(row.updatedAt),
          ]),
        );
      }

      final path = await _buildExportPath('concept_dictionaries', ext: 'csv');
      return File(path).writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<File> exportReadingArchiveCsv() async {
    final db = AppDatabase();
    try {
      final books = await db.booksDao.getAllBooks();
      final lines = <String>[
        _csvRow([
          'book_id',
          'book_title',
          'book_author',
          'book_genre',
          'book_publisher',
          'book_published_date',
          'book_isbn',
          'book_synopsis',
          'book_rating',
          'book_related_url',
          'book_review_summary',
          'book_created_at',
          'book_updated_at',
          'memo_id',
          'memo_type',
          'memo_excerpt_text',
          'memo_thought_text',
          'memo_section_title',
          'memo_page_number',
          'memo_created_at',
          'memo_updated_at',
          'entry_id',
          'entry_type',
          'entry_content',
          'entry_question',
          'entry_thinking_style',
          'entry_created_at',
        ]),
      ];

      for (final book in books) {
        final memos = await db.readingMemosDao.getMemosByBookId(book.id);
        if (memos.isEmpty) {
          lines.add(
            _csvRow([
              book.id,
              book.title,
              book.author,
              book.genre ?? '',
              book.publisher ?? '',
              book.publishedDate ?? '',
              book.isbn ?? '',
              book.synopsis ?? '',
              book.rating ?? '',
              book.relatedUrl ?? '',
              book.reviewSummary ?? '',
              _iso(book.createdAt),
              _iso(book.updatedAt),
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
            ]),
          );
          continue;
        }

        for (final memo in memos) {
          final memoEntries = await db.readingMemoEntriesDao.getEntriesByMemoId(
            memo.id,
          );
          if (memoEntries.isEmpty) {
            lines.add(
              _csvRow([
                book.id,
                book.title,
                book.author,
                book.genre ?? '',
                book.publisher ?? '',
                book.publishedDate ?? '',
                book.isbn ?? '',
                book.synopsis ?? '',
                book.rating ?? '',
                book.relatedUrl ?? '',
                book.reviewSummary ?? '',
                _iso(book.createdAt),
                _iso(book.updatedAt),
                memo.id,
                memo.type.name,
                memo.excerptText ?? '',
                memo.thoughtText,
                memo.sectionTitle ?? '',
                memo.pageNumber ?? '',
                _iso(memo.createdAt),
                memo.updatedAt == null ? '' : _iso(memo.updatedAt!),
                '',
                '',
                '',
                '',
                '',
                '',
              ]),
            );
            continue;
          }

          for (final entry in memoEntries) {
            lines.add(
              _csvRow([
                book.id,
                book.title,
                book.author,
                book.genre ?? '',
                book.publisher ?? '',
                book.publishedDate ?? '',
                book.isbn ?? '',
                book.synopsis ?? '',
                book.rating ?? '',
                book.relatedUrl ?? '',
                book.reviewSummary ?? '',
                _iso(book.createdAt),
                _iso(book.updatedAt),
                memo.id,
                memo.type.name,
                memo.excerptText ?? '',
                memo.thoughtText,
                memo.sectionTitle ?? '',
                memo.pageNumber ?? '',
                _iso(memo.createdAt),
                memo.updatedAt == null ? '' : _iso(memo.updatedAt!),
                entry.id,
                entry.entryType.name,
                entry.content,
                entry.question ?? '',
                entry.thinkingStyleName ?? '',
                _iso(entry.createdAt),
              ]),
            );
          }
        }
      }

      final path = await _buildExportPath('reading_archive', ext: 'csv');
      return File(path).writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<File> exportDailyMemosCsv() async {
    final db = AppDatabase();
    try {
      final memos = await db.dailyMemosDao.getAllDailyMemos();
      final lines = <String>[
        _csvRow([
          'memo_id',
          'title',
          'content',
          'category',
          'tags',
          'memo_created_at',
          'memo_updated_at',
          'entry_id',
          'entry_type',
          'entry_content',
          'entry_question',
          'entry_thinking_style',
          'entry_created_at',
        ]),
      ];

      for (final memo in memos) {
        final entries = await db.dailyMemoEntriesDao.getEntriesByMemoId(
          memo.id,
        );
        if (entries.isEmpty) {
          lines.add(
            _csvRow([
              memo.id,
              memo.title ?? '',
              memo.content,
              memo.category ?? '',
              _jsonArrayToPipeString(memo.tags),
              _iso(memo.createdAt),
              _iso(memo.updatedAt),
              '',
              '',
              '',
              '',
              '',
              '',
            ]),
          );
          continue;
        }

        for (final entry in entries) {
          lines.add(
            _csvRow([
              memo.id,
              memo.title ?? '',
              memo.content,
              memo.category ?? '',
              _jsonArrayToPipeString(memo.tags),
              _iso(memo.createdAt),
              _iso(memo.updatedAt),
              entry.id,
              entry.entryType.name,
              entry.content,
              entry.question ?? '',
              entry.thinkingStyleName ?? '',
              _iso(entry.createdAt),
            ]),
          );
        }
      }

      final path = await _buildExportPath('daily_memos', ext: 'csv');
      return File(path).writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<File> exportCodeEntriesCsv() async {
    final db = AppDatabase();
    try {
      final codeEntries = await db.codeEntriesDao.getAllCodeEntries();
      final lines = <String>[
        _csvRow([
          'code_entry_id',
          'title',
          'entry_type',
          'language',
          'libraries',
          'structure',
          'capabilities',
          'use_cases',
          'learning_points',
          'category',
          'tags',
          'created_at',
          'updated_at',
          'entry_id',
          'entry_entry_type',
          'entry_content',
          'entry_thinking_style_name',
          'entry_created_at',
          'code',
        ]),
      ];

      for (final codeEntry in codeEntries) {
        final entries = await db.codeEntryEntriesDao.getEntriesByCodeEntryId(
          codeEntry.id,
        );
        if (entries.isEmpty) {
          lines.add(
            _csvRow([
              codeEntry.id,
              codeEntry.title,
              codeEntry.entryType.name,
              codeEntry.language ?? '',
              _jsonArrayToPipeString(codeEntry.libraries),
              codeEntry.structure ?? '',
              codeEntry.capabilities ?? '',
              codeEntry.useCases ?? '',
              codeEntry.learningPoints ?? '',
              codeEntry.category ?? '',
              _jsonArrayToPipeString(codeEntry.tags),
              _iso(codeEntry.createdAt),
              _iso(codeEntry.updatedAt),
              '',
              '',
              '',
              '',
              '',
              codeEntry.code,
            ]),
          );
          continue;
        }

        for (final entry in entries) {
          lines.add(
            _csvRow([
              codeEntry.id,
              codeEntry.title,
              codeEntry.entryType.name,
              codeEntry.language ?? '',
              _jsonArrayToPipeString(codeEntry.libraries),
              codeEntry.structure ?? '',
              codeEntry.capabilities ?? '',
              codeEntry.useCases ?? '',
              codeEntry.learningPoints ?? '',
              codeEntry.category ?? '',
              _jsonArrayToPipeString(codeEntry.tags),
              _iso(codeEntry.createdAt),
              _iso(codeEntry.updatedAt),
              entry.id,
              entry.entryType.name,
              entry.content,
              entry.thinkingStyleName ?? '',
              _iso(entry.createdAt),
              codeEntry.code,
            ]),
          );
        }
      }

      final path = await _buildExportPath('code_archive', ext: 'csv');
      return File(path).writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static Future<List<File>> exportAllCsv() async {
    final dialogues = await exportDialoguesCsv();
    final dictionaries = await exportDictionariesCsv();
    final conceptDictionaries = await exportConceptDictionariesCsv();
    final readingArchive = await exportReadingArchiveCsv();
    final dailyMemos = await exportDailyMemosCsv();
    final codeArchive = await exportCodeEntriesCsv();
    return [
      dialogues,
      dictionaries,
      conceptDictionaries,
      readingArchive,
      dailyMemos,
      codeArchive,
    ];
  }

  static Future<File> exportAllText() async {
    final db = AppDatabase();
    try {
      final lines = <String>[
        'NOESIS Archive Export (TXT)',
        'generated_at: ${DateTime.now().toIso8601String()}',
        '',
      ];

      final dialogues = await db.philosophicalDialoguesDao.getAllDialogues();
      lines.add('===== 対話アーカイブ =====');
      for (final dialogue in dialogues) {
        lines.add('[対話] #${dialogue.id} ${dialogue.title}');
        if ((dialogue.summary ?? '').trim().isNotEmpty) {
          lines.add('要約: ${dialogue.summary!.trim()}');
        }
        final messages = await db.philosophicalDialoguesDao
            .getMessagesByDialogue(dialogue.id);
        for (final m in messages) {
          lines.add(
            '- (${_iso(m.createdAt)}) ${m.persona ?? m.role.name}: ${m.content}',
          );
        }
        lines.add('');
      }

      final dictionaries = await db.dictionariesDao.getAllDictionaries();
      lines.add('===== 辞書アーカイブ =====');
      for (final dict in dictionaries) {
        lines.add('[辞書] #${dict.id} ${dict.name}');
        final entries = await db.dictionariesDao.getEntries(dict.id);
        for (final entry in entries) {
          lines.add('- [${entry.headword}]');
          final values = await db.dictionariesDao.getEntryValues(entry.id);
          for (final value in values) {
            lines.add('  - ${value.value}');
          }
        }
        lines.add('');
      }

      final concepts = await (db.select(
        db.conceptDictionaries,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
      lines.add('===== 概念辞書アーカイブ =====');
      for (final concept in concepts) {
        lines.add('[概念] #${concept.id} ${concept.title}');
        lines.add(concept.body);
        lines.add('');
      }

      final books = await db.booksDao.getAllBooks();
      lines.add('===== 読書アーカイブ =====');
      for (final book in books) {
        lines.add('[本] #${book.id} ${book.title} / ${book.author}');
        final memos = await db.readingMemosDao.getMemosByBookId(book.id);
        for (final memo in memos) {
          lines.add(
            '- [メモ #${memo.id}] ${memo.thoughtText}${memo.excerptText == null || memo.excerptText!.isEmpty ? '' : ' / 抜粋: ${memo.excerptText}'}',
          );
        }
        lines.add('');
      }

      final dailyMemos = await db.dailyMemosDao.getAllDailyMemos();
      lines.add('===== 日常アーカイブ =====');
      for (final memo in dailyMemos) {
        lines.add('[日常] #${memo.id} ${memo.title ?? '(無題)'}');
        lines.add(memo.content);
        lines.add('');
      }

      final codeEntries = await db.codeEntriesDao.getAllCodeEntries();
      lines.add('===== ITコードアーカイブ =====');
      for (final entry in codeEntries) {
        lines.add('[コード] #${entry.id} ${entry.title}');
        lines.add(entry.code);
        lines.add('');
      }

      final path = await _buildExportPath('all_archives', ext: 'txt');
      return File(path).writeAsString(lines.join('\n'));
    } finally {
      await db.close();
    }
  }

  static String _csvRow(List<Object?> values) {
    return values.map(_csvCell).join(',');
  }

  static String _csvCell(Object? value) {
    final text = (value ?? '').toString();
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _iso(DateTime value) {
    return value.toIso8601String();
  }

  static String _jsonArrayToPipeString(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).join('|');
      }
    } catch (_) {
      // Keep original raw text when JSON parse fails.
    }
    return raw;
  }

  static Future<String> _buildExportPath(
    String prefix, {
    required String ext,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    return '${tempDir.path}/noesis_${prefix}_$timestamp.$ext';
  }
}
