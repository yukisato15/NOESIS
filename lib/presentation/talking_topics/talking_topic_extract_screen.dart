import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/ai/ai_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/talking_topic_sources_table.dart';
import 'talking_topic_edit_screen.dart';

class TalkingTopicExtractScreen extends StatefulWidget {
  const TalkingTopicExtractScreen({super.key});

  @override
  State<TalkingTopicExtractScreen> createState() =>
      _TalkingTopicExtractScreenState();
}

class _TalkingTopicExtractScreenState extends State<TalkingTopicExtractScreen> {
  final AppDatabase _db = AppDatabase();
  final Set<TalkingTopicSourceArchiveType> _selectedTypes = {
    TalkingTopicSourceArchiveType.dictionary,
    TalkingTopicSourceArchiveType.reading,
    TalkingTopicSourceArchiveType.concept,
    TalkingTopicSourceArchiveType.dialogue,
    TalkingTopicSourceArchiveType.daily,
  };
  List<_ExtractionSource> _sources = [];
  bool _isLoading = true;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    final sources = <_ExtractionSource>[];

    final dictEntries =
        await (_db.select(_db.dictionaryEntries)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(12))
            .get();
    for (final entry in dictEntries) {
      final values = await _db.dictionariesDao.getEntryValues(entry.id);
      final fields = await _db.dictionariesDao.getFields(entry.dictionaryId);
      final definitionMatches = fields.where((f) => f.fieldKey == 'definition');
      final definitionField = definitionMatches.isEmpty
          ? null
          : definitionMatches.first;
      final definition = definitionField == null
          ? ''
          : (() {
              final matches = values.where(
                (v) => v.fieldId == definitionField.id,
              );
              if (matches.isEmpty) {
                return '';
              }
              return matches.first.value;
            })();
      sources.add(
        _ExtractionSource(
          type: TalkingTopicSourceArchiveType.dictionary,
          entryId: entry.id,
          title: entry.headword,
          excerpt: definition,
        ),
      );
    }

    final readingMemos =
        await (_db.select(_db.readingMemos)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(12))
            .get();
    for (final memo in readingMemos) {
      sources.add(
        _ExtractionSource(
          type: TalkingTopicSourceArchiveType.reading,
          entryId: memo.id,
          title: memo.sectionTitle ?? '読書メモ',
          excerpt: '${memo.excerptText ?? ''}\n${memo.thoughtText}'.trim(),
        ),
      );
    }

    final conceptMemos =
        await (_db.select(_db.conceptMemos)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(12))
            .get();
    for (final memo in conceptMemos) {
      sources.add(
        _ExtractionSource(
          type: TalkingTopicSourceArchiveType.concept,
          entryId: memo.id,
          title: memo.title ?? '概念メモ',
          excerpt: memo.content,
        ),
      );
    }

    final dialogues =
        await (_db.select(_db.philosophicalDialogues)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(12))
            .get();
    for (final dialogue in dialogues) {
      sources.add(
        _ExtractionSource(
          type: TalkingTopicSourceArchiveType.dialogue,
          entryId: dialogue.id,
          title: dialogue.title,
          excerpt: dialogue.summary ?? '',
        ),
      );
    }

    final dailyMemos =
        await (_db.select(_db.dailyMemos)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(12))
            .get();
    for (final memo in dailyMemos) {
      sources.add(
        _ExtractionSource(
          type: TalkingTopicSourceArchiveType.daily,
          entryId: memo.id,
          title: memo.title ?? '日常メモ',
          excerpt: memo.content,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _sources = sources;
      _isLoading = false;
    });
  }

  Future<void> _extractFromSource(_ExtractionSource source) async {
    if (!AIClient.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI設定が未構成です')));
      return;
    }
    setState(() => _isExtracting = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは「人との会話で使える小ネタ・雑学」を抽出する編集者です。
以下の素材から、会話で使いやすい話材を1件作ってください。

抽出元: ${source.type.label}
タイトル: ${source.title}
本文:
${source.excerpt}

条件:
- ただの要約ではなく、人に話したくなる切り口を作る
- 大げさにしない
- 短くても使える導入を作る
- 日本語で自然に
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'hook': {'type': 'string'},
            'core_point': {'type': 'string'},
            'body': {'type': 'string'},
            'twist': {'type': 'string'},
            'use_case': {'type': 'string'},
            'genre': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'best_for': {'type': 'string'},
            'avoid_for': {'type': 'string'},
            'delivery_30s': {'type': 'string'},
            'delivery_1m': {'type': 'string'},
            'delivery_casual': {'type': 'string'},
            'follow_up_question': {'type': 'string'},
            'escape_line': {'type': 'string'},
            'source_note': {'type': 'string'},
            'credibility_score': {'type': 'integer'},
          },
          'required': ['title', 'body'],
        },
      );
      if (!mounted) {
        return;
      }
      final draft = InitialTalkingTopicDraft(
        title: (result['title'] ?? source.title).toString(),
        hook: (result['hook'] ?? '').toString(),
        corePoint: (result['core_point'] ?? '').toString(),
        body: (result['body'] ?? '').toString(),
        twist: (result['twist'] ?? '').toString(),
        useCase: (result['use_case'] ?? '').toString(),
        genre: (result['genre'] ?? '').toString(),
        tags: (result['tags'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        bestFor: (result['best_for'] ?? '').toString(),
        avoidFor: (result['avoid_for'] ?? '').toString(),
        delivery30s: (result['delivery_30s'] ?? '').toString(),
        delivery1m: (result['delivery_1m'] ?? '').toString(),
        deliveryCasual: (result['delivery_casual'] ?? '').toString(),
        followUpQuestion: (result['follow_up_question'] ?? '').toString(),
        escapeLine: (result['escape_line'] ?? '').toString(),
        sourceNote: (result['source_note'] ?? '').toString(),
        referenceUrls: const [],
        credibilityScore: ((result['credibility_score'] as int?) ?? 60),
        rawSource: source.excerpt,
        sources: [
          InitialTalkingTopicSource(
            type: source.type,
            entryId: source.entryId,
            title: source.title,
            excerpt: source.excerpt,
          ),
        ],
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TalkingTopicEditScreen(initialDraft: draft),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExtracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleSources = _sources
        .where((source) => _selectedTypes.contains(source.type))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('他アーカイブから抽出')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TalkingTopicSourceArchiveType.values
                      .where(
                        (type) => type != TalkingTopicSourceArchiveType.manual,
                      )
                      .map(
                        (type) => FilterChip(
                          label: Text(type.label),
                          selected: _selectedTypes.contains(type),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTypes.add(type);
                              } else {
                                _selectedTypes.remove(type);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                for (final source in visibleSources) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.soften(
                              AppPalette.talkingTopic,
                              0.84,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(source.type.label),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          source.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          source.excerpt,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _isExtracting
                              ? null
                              : () => _extractFromSource(source),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPalette.talkingTopic,
                          ),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(_isExtracting ? '抽出中...' : 'この素材から話材化'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ExtractionSource {
  final TalkingTopicSourceArchiveType type;
  final int entryId;
  final String title;
  final String excerpt;

  const _ExtractionSource({
    required this.type,
    required this.entryId,
    required this.title,
    required this.excerpt,
  });
}
