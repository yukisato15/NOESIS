import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../core/ai/ai_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/talking_topic_sources_table.dart';
import '../../data/local/tables/talking_topics_table.dart';
import '../shared/surface_field.dart';

class TalkingTopicEditScreen extends StatefulWidget {
  final int? topicId;
  final InitialTalkingTopicDraft? initialDraft;

  const TalkingTopicEditScreen({super.key, this.topicId, this.initialDraft});

  @override
  State<TalkingTopicEditScreen> createState() => _TalkingTopicEditScreenState();
}

class _TalkingTopicEditScreenState extends State<TalkingTopicEditScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hookController = TextEditingController();
  final TextEditingController _corePointController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _twistController = TextEditingController();
  final TextEditingController _useCaseController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _bestForController = TextEditingController();
  final TextEditingController _avoidForController = TextEditingController();
  final TextEditingController _delivery30sController = TextEditingController();
  final TextEditingController _delivery1mController = TextEditingController();
  final TextEditingController _delivery3mController = TextEditingController();
  final TextEditingController _deliveryCasualController =
      TextEditingController();
  final TextEditingController _deliveryIntellectualController =
      TextEditingController();
  final TextEditingController _deliveryHumorousController =
      TextEditingController();
  final TextEditingController _followUpQuestionController =
      TextEditingController();
  final TextEditingController _escapeLineController = TextEditingController();
  final TextEditingController _sourceNoteController = TextEditingController();
  final TextEditingController _referenceUrlsController =
      TextEditingController();
  final TextEditingController _rawMemoController = TextEditingController();

  TalkingTopic? _topic;
  TalkingTopicTone _tone = TalkingTopicTone.balanced;
  TalkingTopicDifficulty _difficulty = TalkingTopicDifficulty.medium;
  double _credibilityScore = 60;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPolishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _titleController.dispose();
    _hookController.dispose();
    _corePointController.dispose();
    _bodyController.dispose();
    _twistController.dispose();
    _useCaseController.dispose();
    _genreController.dispose();
    _tagsController.dispose();
    _bestForController.dispose();
    _avoidForController.dispose();
    _delivery30sController.dispose();
    _delivery1mController.dispose();
    _delivery3mController.dispose();
    _deliveryCasualController.dispose();
    _deliveryIntellectualController.dispose();
    _deliveryHumorousController.dispose();
    _followUpQuestionController.dispose();
    _escapeLineController.dispose();
    _sourceNoteController.dispose();
    _referenceUrlsController.dispose();
    _rawMemoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.topicId != null) {
      final topic = await _db.talkingTopicsDao.getTopicById(widget.topicId!);
      if (topic != null) {
        _topic = topic;
        _titleController.text = topic.title;
        _hookController.text = topic.hook ?? '';
        _corePointController.text = topic.corePoint ?? '';
        _bodyController.text = topic.body ?? '';
        _twistController.text = topic.twist ?? '';
        _useCaseController.text = topic.useCase ?? '';
        _genreController.text = topic.genre ?? '';
        _tagsController.text = _decodeTags(topic.tags).join(', ');
        _bestForController.text = topic.bestFor ?? '';
        _avoidForController.text = topic.avoidFor ?? '';
        _delivery30sController.text = topic.delivery30s ?? '';
        _delivery1mController.text = topic.delivery1m ?? '';
        _delivery3mController.text = topic.delivery3m ?? '';
        _deliveryCasualController.text = topic.deliveryCasual ?? '';
        _deliveryIntellectualController.text = topic.deliveryIntellectual ?? '';
        _deliveryHumorousController.text = topic.deliveryHumorous ?? '';
        _followUpQuestionController.text = topic.followUpQuestion ?? '';
        _escapeLineController.text = topic.escapeLine ?? '';
        _sourceNoteController.text = topic.sourceNote ?? '';
        _referenceUrlsController.text = _decodeListField(topic.referenceUrls);
        _tone = topic.tone;
        _difficulty = topic.difficulty;
        _credibilityScore = topic.credibilityScore.toDouble();
      }
    } else if (widget.initialDraft != null) {
      final draft = widget.initialDraft!;
      _titleController.text = draft.title;
      _hookController.text = draft.hook ?? '';
      _corePointController.text = draft.corePoint ?? '';
      _bodyController.text = draft.body ?? '';
      _twistController.text = draft.twist ?? '';
      _useCaseController.text = draft.useCase ?? '';
      _genreController.text = draft.genre ?? '';
      _tagsController.text = draft.tags.join(', ');
      _bestForController.text = draft.bestFor ?? '';
      _avoidForController.text = draft.avoidFor ?? '';
      _delivery30sController.text = draft.delivery30s ?? '';
      _delivery1mController.text = draft.delivery1m ?? '';
      _deliveryCasualController.text = draft.deliveryCasual ?? '';
      _followUpQuestionController.text = draft.followUpQuestion ?? '';
      _escapeLineController.text = draft.escapeLine ?? '';
      _sourceNoteController.text = draft.sourceNote ?? '';
      _referenceUrlsController.text = draft.referenceUrls.join('\n');
      _credibilityScore = draft.credibilityScore.toDouble();
      _rawMemoController.text = draft.rawSource ?? '';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .replaceAll('、', ',')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _decodeListField(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).join('\n');
      }
    } catch (_) {}
    return raw;
  }

  String? _encodeListField(String raw) {
    final items = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return items.isEmpty ? null : jsonEncode(items);
  }

  Future<void> _polishWithAI() async {
    final rawMemo = _rawMemoController.text.trim();
    if (rawMemo.isEmpty && _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('元メモか本文を入力してください')));
      return;
    }
    if (!AIClient.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI設定が未構成です')));
      return;
    }
    setState(() => _isPolishing = true);
    try {
      final prompt =
          '''
あなたは「会話で使える小ネタ・雑学」を整える編集者です。
以下のラフメモを、人に話しやすい話材に整えてください。

ラフメモ:
${rawMemo.isEmpty ? _bodyController.text.trim() : rawMemo}

条件:
- 単なる要約ではなく、会話で使いやすい形にする
- 誇張しすぎない
- 面白さのフックと驚きポイントを作る
- 日本語で自然に

出力項目:
- title
- hook
- core_point
- body
- twist
- use_case
- genre
- tags
- best_for
- avoid_for
- delivery_30s
- delivery_1m
- delivery_casual
- delivery_intellectual
- follow_up_question
- escape_line
- ai_summary
- ai_angle
- ai_polish_note
- credibility_score
''';
      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
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
            'delivery_intellectual': {'type': 'string'},
            'follow_up_question': {'type': 'string'},
            'escape_line': {'type': 'string'},
            'ai_summary': {'type': 'string'},
            'ai_angle': {'type': 'string'},
            'ai_polish_note': {'type': 'string'},
            'credibility_score': {'type': 'integer'},
          },
          'required': ['title', 'body'],
        },
      );
      _titleController.text = (result['title'] ?? '').toString();
      _hookController.text = (result['hook'] ?? '').toString();
      _corePointController.text = (result['core_point'] ?? '').toString();
      _bodyController.text = (result['body'] ?? '').toString();
      _twistController.text = (result['twist'] ?? '').toString();
      _useCaseController.text = (result['use_case'] ?? '').toString();
      _genreController.text = (result['genre'] ?? '').toString();
      final tags = (result['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      _tagsController.text = tags.join(', ');
      _bestForController.text = (result['best_for'] ?? '').toString();
      _avoidForController.text = (result['avoid_for'] ?? '').toString();
      _delivery30sController.text = (result['delivery_30s'] ?? '').toString();
      _delivery1mController.text = (result['delivery_1m'] ?? '').toString();
      _deliveryCasualController.text = (result['delivery_casual'] ?? '')
          .toString();
      _deliveryIntellectualController.text =
          (result['delivery_intellectual'] ?? '').toString();
      _followUpQuestionController.text = (result['follow_up_question'] ?? '')
          .toString();
      _escapeLineController.text = (result['escape_line'] ?? '').toString();
      final score = result['credibility_score'];
      if (score is int) {
        _credibilityScore = score.clamp(0, 100).toDouble();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('AIで整えました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI整形に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPolishing = false);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }
    setState(() => _isSaving = true);
    final tags = _parseTags(_tagsController.text);
    final now = DateTime.now();
    try {
      int topicId;
      if (_topic == null) {
        topicId = await _db.talkingTopicsDao.insertTopic(
          TalkingTopicsCompanion.insert(
            title: title,
            hook: drift.Value(_nullOrText(_hookController.text)),
            corePoint: drift.Value(_nullOrText(_corePointController.text)),
            body: drift.Value(_nullOrText(_bodyController.text)),
            twist: drift.Value(_nullOrText(_twistController.text)),
            useCase: drift.Value(_nullOrText(_useCaseController.text)),
            genre: drift.Value(_nullOrText(_genreController.text)),
            tags: drift.Value(tags.isEmpty ? null : jsonEncode(tags)),
            tone: drift.Value(_tone),
            difficulty: drift.Value(_difficulty),
            bestFor: drift.Value(_nullOrText(_bestForController.text)),
            avoidFor: drift.Value(_nullOrText(_avoidForController.text)),
            delivery30s: drift.Value(_nullOrText(_delivery30sController.text)),
            delivery1m: drift.Value(_nullOrText(_delivery1mController.text)),
            delivery3m: drift.Value(_nullOrText(_delivery3mController.text)),
            deliveryCasual: drift.Value(
              _nullOrText(_deliveryCasualController.text),
            ),
            deliveryIntellectual: drift.Value(
              _nullOrText(_deliveryIntellectualController.text),
            ),
            deliveryHumorous: drift.Value(
              _nullOrText(_deliveryHumorousController.text),
            ),
            followUpQuestion: drift.Value(
              _nullOrText(_followUpQuestionController.text),
            ),
            escapeLine: drift.Value(_nullOrText(_escapeLineController.text)),
            credibilityScore: drift.Value(_credibilityScore.round()),
            sourceNote: drift.Value(_nullOrText(_sourceNoteController.text)),
            referenceUrls: drift.Value(
              _encodeListField(_referenceUrlsController.text),
            ),
            createdAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
      } else {
        final updated = _topic!.copyWith(
          title: title,
          hook: drift.Value(_nullOrText(_hookController.text)),
          corePoint: drift.Value(_nullOrText(_corePointController.text)),
          body: drift.Value(_nullOrText(_bodyController.text)),
          twist: drift.Value(_nullOrText(_twistController.text)),
          useCase: drift.Value(_nullOrText(_useCaseController.text)),
          genre: drift.Value(_nullOrText(_genreController.text)),
          tags: drift.Value(tags.isEmpty ? null : jsonEncode(tags)),
          tone: _tone,
          difficulty: _difficulty,
          bestFor: drift.Value(_nullOrText(_bestForController.text)),
          avoidFor: drift.Value(_nullOrText(_avoidForController.text)),
          delivery30s: drift.Value(_nullOrText(_delivery30sController.text)),
          delivery1m: drift.Value(_nullOrText(_delivery1mController.text)),
          delivery3m: drift.Value(_nullOrText(_delivery3mController.text)),
          deliveryCasual: drift.Value(
            _nullOrText(_deliveryCasualController.text),
          ),
          deliveryIntellectual: drift.Value(
            _nullOrText(_deliveryIntellectualController.text),
          ),
          deliveryHumorous: drift.Value(
            _nullOrText(_deliveryHumorousController.text),
          ),
          followUpQuestion: drift.Value(
            _nullOrText(_followUpQuestionController.text),
          ),
          escapeLine: drift.Value(_nullOrText(_escapeLineController.text)),
          credibilityScore: _credibilityScore.round(),
          sourceNote: drift.Value(_nullOrText(_sourceNoteController.text)),
          referenceUrls: drift.Value(
            _encodeListField(_referenceUrlsController.text),
          ),
          updatedAt: now,
        );
        await _db.talkingTopicsDao.updateTopic(updated);
        topicId = updated.id;
      }
      if (widget.initialDraft != null) {
        await _db.talkingTopicsDao.deleteSourcesForTopic(topicId);
        for (final source in widget.initialDraft!.sources) {
          await _db.talkingTopicsDao.insertSource(
            TalkingTopicSourcesCompanion.insert(
              topicId: topicId,
              sourceArchiveType: source.type,
              sourceEntryId: drift.Value(source.entryId),
              sourceTitle: drift.Value(source.title),
              sourceExcerpt: drift.Value(source.excerpt),
            ),
          );
        }
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _nullOrText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicId == null ? '話材を追加' : '話材を編集'),
        actions: [
          IconButton(
            onPressed: _isPolishing ? null : _polishWithAI,
            icon: _isPolishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
          ),
          IconButton(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '元メモ・素材',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: 'ラフメモ',
                  hintText: '雑なメモ、引用、体験談の種など',
                  controller: _rawMemoController,
                  maxLines: 5,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isPolishing ? null : _polishWithAI,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.talkingTopic,
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_isPolishing ? '整形中...' : 'AIで話材に整える'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceField(label: 'タイトル', controller: _titleController),
          const SizedBox(height: 16),
          SurfaceField(
            label: '一言フック',
            controller: _hookController,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '核心',
            controller: _corePointController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '詳細説明',
            controller: _bodyController,
            maxLines: 6,
            alignLabelWithHint: true,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'オチ・驚きポイント',
            controller: _twistController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '使いどころ',
            controller: _useCaseController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SurfaceField(
                  label: 'ジャンル',
                  controller: _genreController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SurfaceField(label: 'タグ', controller: _tagsController),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '話し方の設計',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '30秒版',
                  controller: _delivery30sController,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '1分版',
                  controller: _delivery1mController,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '3分版',
                  controller: _delivery3mController,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: 'カジュアル版',
                  controller: _deliveryCasualController,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '知的版',
                  controller: _deliveryIntellectualController,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: 'ユーモア版',
                  controller: _deliveryHumorousController,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '相手に返す質問',
                  controller: _followUpQuestionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '滑った時の逃がし方',
                  controller: _escapeLineController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '向いている相手・場面',
            controller: _bestForController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '向かない相手・場面',
            controller: _avoidForController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '出典・メモ',
            controller: _sourceNoteController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '参考URL',
            hintText: '1行に1URL',
            controller: _referenceUrlsController,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '話材の性格',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('トーン'),
                const SizedBox(height: 8),
                SegmentedButton<TalkingTopicTone>(
                  segments: const [
                    ButtonSegment(
                      value: TalkingTopicTone.light,
                      label: Text('軽い'),
                    ),
                    ButtonSegment(
                      value: TalkingTopicTone.balanced,
                      label: Text('中間'),
                    ),
                    ButtonSegment(
                      value: TalkingTopicTone.intellectual,
                      label: Text('知的'),
                    ),
                    ButtonSegment(
                      value: TalkingTopicTone.funny,
                      label: Text('面白め'),
                    ),
                  ],
                  selected: {_tone},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _tone = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                Text('深さ'),
                const SizedBox(height: 8),
                SegmentedButton<TalkingTopicDifficulty>(
                  segments: const [
                    ButtonSegment(
                      value: TalkingTopicDifficulty.easy,
                      label: Text('軽い'),
                    ),
                    ButtonSegment(
                      value: TalkingTopicDifficulty.medium,
                      label: Text('普通'),
                    ),
                    ButtonSegment(
                      value: TalkingTopicDifficulty.deep,
                      label: Text('深い'),
                    ),
                  ],
                  selected: {_difficulty},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _difficulty = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                Text('信頼度 ${_credibilityScore.round()}'),
                Slider(
                  value: _credibilityScore,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (value) =>
                      setState(() => _credibilityScore = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InitialTalkingTopicDraft {
  final String title;
  final String? hook;
  final String? corePoint;
  final String? body;
  final String? twist;
  final String? useCase;
  final String? genre;
  final List<String> tags;
  final String? bestFor;
  final String? avoidFor;
  final String? delivery30s;
  final String? delivery1m;
  final String? deliveryCasual;
  final String? followUpQuestion;
  final String? escapeLine;
  final String? sourceNote;
  final List<String> referenceUrls;
  final int credibilityScore;
  final String? rawSource;
  final List<InitialTalkingTopicSource> sources;

  const InitialTalkingTopicDraft({
    required this.title,
    this.hook,
    this.corePoint,
    this.body,
    this.twist,
    this.useCase,
    this.genre,
    this.tags = const [],
    this.bestFor,
    this.avoidFor,
    this.delivery30s,
    this.delivery1m,
    this.deliveryCasual,
    this.followUpQuestion,
    this.escapeLine,
    this.sourceNote,
    this.referenceUrls = const [],
    this.credibilityScore = 60,
    this.rawSource,
    this.sources = const [],
  });
}

class InitialTalkingTopicSource {
  final TalkingTopicSourceArchiveType type;
  final int? entryId;
  final String? title;
  final String? excerpt;

  const InitialTalkingTopicSource({
    required this.type,
    this.entryId,
    this.title,
    this.excerpt,
  });
}
