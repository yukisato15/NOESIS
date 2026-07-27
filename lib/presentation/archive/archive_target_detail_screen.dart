import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/person/person_question_guides.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/question_repository.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/archive_entries_table.dart';
import '../../data/local/tables/archive_targets_table.dart';
import '../../data/local/tables/person_profile_attributes_table.dart';
import '../shared/surface_field.dart';

class ArchiveTargetDetailScreen extends StatefulWidget {
  final int targetId;

  const ArchiveTargetDetailScreen({super.key, required this.targetId});

  @override
  State<ArchiveTargetDetailScreen> createState() =>
      _ArchiveTargetDetailScreenState();
}

class _ArchiveTargetDetailScreenState extends State<ArchiveTargetDetailScreen> {
  final AppDatabase _db = AppDatabase();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _firstMetAtController = TextEditingController();
  final TextEditingController _firstMetPlaceController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mapUrlController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();
  final TextEditingController _analysisSummaryController =
      TextEditingController();
  final TextEditingController _analysisTraitsController =
      TextEditingController();
  final TextEditingController _mbtiGuessController = TextEditingController();
  final TextEditingController _mbtiNoteController = TextEditingController();

  ArchiveTarget? _target;
  List<ArchiveEntry> _entries = [];
  List<PersonProfileAttribute> _personAttributes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAnalyzing = false;
  bool _isAutofilling = false;
  bool _isExtractingAttributes = false;
  bool _isProcessingIntake = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _nameController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _summaryController.dispose();
    _firstMetAtController.dispose();
    _firstMetPlaceController.dispose();
    _addressController.dispose();
    _mapUrlController.dispose();
    _sourceUrlController.dispose();
    _analysisSummaryController.dispose();
    _analysisTraitsController.dispose();
    _mbtiGuessController.dispose();
    _mbtiNoteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final target = await _db.archiveTargetsDao.getTargetById(widget.targetId);
    final entries = await _db.archiveTargetsDao.getEntriesByTarget(
      widget.targetId,
    );
    final attributes = await _db.personProfileAttributesDao
        .getAttributesByTarget(widget.targetId);
    if (!mounted || target == null) {
      return;
    }
    _target = target;
    _entries = entries;
    _personAttributes = attributes;
    _nameController.text = target.name;
    _categoryController.text = target.category ?? '';
    _tagsController.text = _decodeTags(target.tags).join(', ');
    _summaryController.text = target.summary ?? '';
    _firstMetAtController.text = target.firstMetAt ?? '';
    _firstMetPlaceController.text = target.firstMetPlace ?? '';
    _addressController.text = target.address ?? '';
    _mapUrlController.text = target.mapUrl ?? '';
    _sourceUrlController.text = target.sourceUrl ?? '';
    _analysisSummaryController.text = target.analysisSummary ?? '';
    _analysisTraitsController.text = target.analysisTraits ?? '';
    _mbtiGuessController.text = target.mbtiGuess ?? '';
    _mbtiNoteController.text = target.mbtiNote ?? '';
    setState(() {
      _isLoading = false;
    });
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

  Map<String, dynamic> _decodeExtraJson() {
    final target = _target;
    if (target == null || target.extraJson.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return Map<String, dynamic>.from(
        jsonDecode(target.extraJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<String> _followUpQuestions() {
    final extra = _decodeExtraJson();
    final raw = extra['person_follow_up_questions'];
    if (raw is! List) {
      return const [];
    }
    return raw.map((item) => item.toString()).toList();
  }

  List<PersonQuestionTactic>? _cachedQuestionTactics(
    PersonAttributeDefinition definition,
  ) {
    final extra = _decodeExtraJson();
    final raw = extra['person_question_tactics'];
    if (raw is! Map) {
      return null;
    }
    final key = PersonQuestionGuides.attributeKey(
      definition.category,
      definition.name,
    );
    final items = raw[key];
    if (items is! List) {
      return null;
    }
    return items
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final strategyName = (map['question_type'] ?? '').toString();
          final strategy = QuestionStrategy.values.firstWhere(
            (value) => value.apiName == strategyName,
            orElse: () => QuestionStrategy.direct,
          );
          return PersonQuestionTactic(
            attribute: definition.name,
            category: definition.category,
            questionType: strategy,
            questionText: (map['question_text'] ?? '').toString(),
            purpose: (map['purpose'] ?? definition.description).toString(),
          );
        })
        .where((item) => item.questionText.trim().isNotEmpty)
        .toList();
  }

  Future<void> _updateExtraJson(Map<String, dynamic> nextExtra) async {
    final target = _target;
    if (target == null) {
      return;
    }
    final updated = target.copyWith(
      extraJson: jsonEncode(nextExtra),
      updatedAt: DateTime.now(),
    );
    await _db.archiveTargetsDao.updateTarget(updated);
    _target = updated;
  }

  String _buildQuestionGenerationPrompt(PersonAttributeDefinition definition) {
    return '''
You are a behavioral interview designer and human-understanding system architect.

You are generating a conversational question database for a knowledge system called "Noesis".

The goal of Noesis is NOT interrogation, profiling, persuasion, or manipulation.
The goal is: natural human understanding through everyday conversation.

Questions must feel like:
- small talk
- casual curiosity
- story sharing
- experience exchange

Questions must NEVER feel like:
- surveys
- psychological tests
- interrogations
- personality diagnostics

CRITICAL QUESTION DESIGN PRINCIPLES
- sound like natural Japanese conversation
- avoid psychological terminology
- avoid diagnostic wording
- avoid repetitive structures
- use everyday life topics
- often reference experiences, preferences, culture, memories
- sometimes allow inference rather than direct asking
- sensitive topics must be asked indirectly

QUESTION STRATEGIES
For this attribute, generate EXACTLY 16 questions:
- DIRECT x2
- INDIRECT x2
- ASSUMPTION x2
- COMPARISON x2
- PAST x2
- SITUATIONAL x2
- OBSERVATION x2
- HYPOTHETICAL x2

OUTPUT JSON ONLY.

Target category: ${definition.category}
Target attribute: ${definition.name}
Attribute description: ${definition.description}
Input kind: ${_inputKindLabel(definition)}
Sensitive topic: ${definition.intrusive ? 'yes' : 'no'}
Options: ${definition.options.isEmpty ? 'free text' : definition.options.join(', ')}
Hints: ${definition.questionSeeds.join(' / ')}
Openers: ${definition.conversationOpeners.join(' / ')}
Observation clues: ${definition.observationClues.join(' / ')}

Return:
{
  "items": [
    {
      "category": "${definition.category}",
      "attribute": "${definition.name}",
      "question_type": "DIRECT",
      "question_text": "質問文",
      "purpose": "推定したいこと"
    }
  ]
}
''';
  }

  Future<List<PersonQuestionTactic>> _loadQuestionTactics(
    PersonAttributeDefinition definition,
  ) async {
    final csvQuestions = await QuestionRepository.instance
        .getQuestionsForAttribute(definition.name);
    if (csvQuestions.isNotEmpty) {
      return csvQuestions.map((item) {
        final strategy = QuestionStrategy.values.firstWhere(
          (value) => value.apiName == item.questionType,
          orElse: () => QuestionStrategy.direct,
        );
        return PersonQuestionTactic(
          attribute: item.attribute,
          category: item.category,
          questionType: strategy,
          questionText: item.questionText,
          purpose: item.purpose,
        );
      }).toList();
    }

    final cached = _cachedQuestionTactics(definition);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    if (!AIClient.isConfigured) {
      return PersonQuestionGuides.tacticsForDefinition(
        definition,
        definition.intrusive
            ? RelationshipLevel.level3
            : RelationshipLevel.level2,
      );
    }

    try {
      final result = await AIClient.instance.generateStructured(
        prompt: _buildQuestionGenerationPrompt(definition),
        jsonSchema: {
          'type': 'object',
          'properties': {
            'items': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'category': {'type': 'string'},
                  'attribute': {'type': 'string'},
                  'question_type': {'type': 'string'},
                  'question_text': {'type': 'string'},
                  'purpose': {'type': 'string'},
                },
                'required': [
                  'category',
                  'attribute',
                  'question_type',
                  'question_text',
                  'purpose',
                ],
              },
            },
          },
          'required': ['items'],
        },
      );
      final items = (result['items'] as List<dynamic>? ?? const []);
      final tactics = items
          .map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final strategyName = (map['question_type'] ?? '').toString();
            final strategy = QuestionStrategy.values.firstWhere(
              (value) => value.apiName == strategyName,
              orElse: () => QuestionStrategy.direct,
            );
            return PersonQuestionTactic(
              attribute: definition.name,
              category: definition.category,
              questionType: strategy,
              questionText: (map['question_text'] ?? '').toString(),
              purpose: (map['purpose'] ?? definition.description).toString(),
            );
          })
          .where((item) => item.questionText.trim().isNotEmpty)
          .toList();

      if (tactics.isNotEmpty) {
        final extra = _decodeExtraJson();
        final cache = Map<String, dynamic>.from(
          (extra['person_question_tactics'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{},
        );
        cache[PersonQuestionGuides.attributeKey(
          definition.category,
          definition.name,
        )] = tactics
            .map(
              (tactic) => {
                'question_type': tactic.questionType.apiName,
                'question_text': tactic.questionText,
                'purpose': tactic.purpose,
              },
            )
            .toList();
        extra['person_question_tactics'] = cache;
        await _updateExtraJson(extra);
      }

      return tactics.isNotEmpty
          ? tactics
          : PersonQuestionGuides.tacticsForDefinition(
              definition,
              definition.intrusive
                  ? RelationshipLevel.level3
                  : RelationshipLevel.level2,
            );
    } catch (_) {
      return PersonQuestionGuides.tacticsForDefinition(
        definition,
        definition.intrusive
            ? RelationshipLevel.level3
            : RelationshipLevel.level2,
      );
    }
  }

  bool get _isPersonLike {
    final target = _target;
    if (target == null) {
      return false;
    }
    return target.targetType == ArchiveTargetType.person ||
        target.targetType == ArchiveTargetType.publicFigure;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save({bool showMessage = true}) async {
    final target = _target;
    if (target == null) {
      return;
    }
    setState(() => _isSaving = true);
    final updated = target.copyWith(
      name: _nameController.text.trim(),
      category: Value(_nullable(_categoryController.text)),
      tags: Value(
        _parseTags(_tagsController.text).isEmpty
            ? null
            : jsonEncode(_parseTags(_tagsController.text)),
      ),
      summary: Value(_nullable(_summaryController.text)),
      firstMetAt: Value(_nullable(_firstMetAtController.text)),
      firstMetPlace: Value(_nullable(_firstMetPlaceController.text)),
      address: Value(_nullable(_addressController.text)),
      mapUrl: Value(_nullable(_mapUrlController.text)),
      sourceUrl: Value(_nullable(_sourceUrlController.text)),
      analysisSummary: Value(_nullable(_analysisSummaryController.text)),
      analysisTraits: Value(_nullable(_analysisTraitsController.text)),
      mbtiGuess: Value(_nullable(_mbtiGuessController.text)),
      mbtiNote: Value(_nullable(_mbtiNoteController.text)),
      updatedAt: DateTime.now(),
    );
    await _db.archiveTargetsDao.updateTarget(updated);
    _target = updated;
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  Future<void> _deleteTarget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('対象を削除しますか？'),
        content: const Text('紐づく記録も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _db.archiveTargetsDao.deleteTarget(widget.targetId);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _autofillPublicFigure() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _isAutofilling = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは人物アーカイブ編集者です。
以下の著名人・歴史上の人物について、人物理解の材料になる情報を日本語で整理してください。

名前: $name

出力はJSON形式で、以下のキーを含めてください。
- category: 分野やジャンル
- tags: 関連タグの配列（3-6件）
- summary: 人物像、業績、時代背景を短く整理した文章
- source_url: 参考URLを1件
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'category': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'summary': {'type': 'string'},
            'source_url': {'type': 'string'},
          },
          'required': ['category', 'tags', 'summary', 'source_url'],
        },
        mode: SearchClient.canUseWebSearch
            ? AIMode.withSearch
            : AIMode.standard,
      );
      _categoryController.text = (result['category'] ?? '').toString();
      final tags = (result['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      _tagsController.text = tags.join(', ');
      _summaryController.text = (result['summary'] ?? '').toString();
      _sourceUrlController.text = (result['source_url'] ?? '').toString();
      await _save(showMessage: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('自動補完に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() => _isAutofilling = false);
      }
    }
  }

  Future<void> _analyzeTarget() async {
    final target = _target;
    if (target == null) {
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final attributeText = _personAttributes
          .map(
            (attribute) => [
              'カテゴリ: ${attribute.category}',
              '属性: ${attribute.attributeName}',
              '値: ${attribute.attributeValue}',
              'データ種別: ${attribute.dataType.label}',
              '確信度: ${attribute.confidenceScore}',
              '出典: ${attribute.source}',
              if ((attribute.note ?? '').isNotEmpty) '注記: ${attribute.note}',
            ].join('\n'),
          )
          .join('\n\n');
      final entriesText = _entries
          .map((entry) {
            final happenedAt = entry.happenedAt == null
                ? ''
                : DateFormat('yyyy/MM/dd').format(entry.happenedAt!);
            return [
              if ((entry.title ?? '').isNotEmpty) 'タイトル: ${entry.title}',
              '種別: ${entry.entryType.label}',
              if (happenedAt.isNotEmpty) '日付: $happenedAt',
              if ((entry.location ?? '').isNotEmpty) '場所: ${entry.location}',
              '内容: ${entry.content}',
            ].join('\n');
          })
          .join('\n\n');
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは観察記録の分析者です。
以下の対象について、記録から傾向を整理してください。
MBTIは断定ではなく、あくまで傾向として扱ってください。

対象タイプ: ${target.targetType.label}
名前: ${_nameController.text.trim()}
カテゴリ: ${_categoryController.text.trim()}
概要:
${_summaryController.text.trim()}

構造化属性:
${attributeText.isEmpty ? 'まだ構造化属性はありません。' : attributeText}

記録:
${entriesText.isEmpty ? 'まだ記録がありません。既存の概要だけから慎重に整理してください。' : entriesText}

出力はJSON形式で、以下のキーを含めてください。
- analysis_summary: 対象理解の要約
- analysis_traits: 傾向を箇条書き風にまとめた文章
- mbti_guess: MBTIに似た傾向があれば1つ。ただし断定禁止。なければ空文字
- mbti_note: 推定理由と限界
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'analysis_summary': {'type': 'string'},
            'analysis_traits': {'type': 'string'},
            'mbti_guess': {'type': 'string'},
            'mbti_note': {'type': 'string'},
          },
          'required': [
            'analysis_summary',
            'analysis_traits',
            'mbti_guess',
            'mbti_note',
          ],
        },
      );
      _analysisSummaryController.text = (result['analysis_summary'] ?? '')
          .toString();
      _analysisTraitsController.text = (result['analysis_traits'] ?? '')
          .toString();
      _mbtiGuessController.text = (result['mbti_guess'] ?? '').toString();
      _mbtiNoteController.text = (result['mbti_note'] ?? '').toString();
      await _save(showMessage: false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分析結果を更新しました')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('分析に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _openUrl(String rawUrl) async {
    final url = Uri.tryParse(rawUrl.trim());
    if (url == null) {
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _showQuestionGuideSheet() async {
    if (!_isPersonLike) {
      return;
    }
    var level = RelationshipLevel.level2;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final suggestions = PersonQuestionGuides.suggestQuestions(
              knownAttributeKeys: _personAttributes
                  .map(
                    (attribute) => PersonQuestionGuides.attributeKey(
                      attribute.category,
                      attribute.attributeName,
                    ),
                  )
                  .toSet(),
              level: level,
            );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '質問ガイド',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<RelationshipLevel>(
                      segments: RelationshipLevel.values
                          .map(
                            (value) => ButtonSegment(
                              value: value,
                              label: Text(value.label.split(' ').first),
                            ),
                          )
                          .toList(),
                      selected: {level},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) {
                        setSheetState(() => level = selection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: suggestions.map((question) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(question.questionText),
                            subtitle: Text(
                              '${question.category} / ${question.questionType.label}',
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyAiPersonSnapshot(
    Map<String, dynamic> result, {
    required PersonDataType dataType,
    required String source,
  }) async {
    final target = _target;
    if (target == null) {
      return;
    }

    final category = (result['category'] ?? '').toString().trim();
    final tags = (result['tags'] as List<dynamic>? ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final summary = (result['summary'] ?? '').toString().trim();
    final followUps =
        (result['follow_up_questions'] as List<dynamic>? ?? const [])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

    if (category.isNotEmpty) {
      _categoryController.text = category;
    }
    if (tags.isNotEmpty) {
      _tagsController.text = tags.join(', ');
    }
    if (summary.isNotEmpty) {
      _summaryController.text = summary;
    }

    final extra = _decodeExtraJson();
    extra['person_follow_up_questions'] = followUps;
    await _updateExtraJson(extra);

    final attributes = (result['attributes'] as List<dynamic>? ?? const []);
    for (final item in attributes) {
      final map = Map<String, dynamic>.from(item as Map);
      final definition = PersonQuestionGuides.definitionByKey(
        map['category'].toString(),
        map['attribute_name'].toString(),
      );
      if (definition == null) {
        continue;
      }
      await _db.personProfileAttributesDao.upsertAttributeForType(
        targetId: widget.targetId,
        category: definition.category,
        attributeName: definition.name,
        attributeValue: map['attribute_value'].toString(),
        dataType: dataType,
        confidenceScore:
            (map['confidence_score'] as num?)?.toInt().clamp(0, 100) ?? 60,
        source: source,
        note: _nullable((map['note'] ?? '').toString()),
      );
    }
    await _save(showMessage: false);
    await _load();
  }

  Future<void> _processObservationIntake({
    required String text,
    required PersonDataType dataType,
    String? followUpAnswers,
  }) async {
    setState(() => _isProcessingIntake = true);
    try {
      final allowedDefinitions = PersonQuestionGuides.definitions
          .map((definition) => '${definition.category} / ${definition.name}')
          .join('\n');
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは人物理解アシスタントです。
次の観察記述や会話メモから、人物プロフィールを整理してください。

ルール:
- 断定しすぎない
- センシティブ推定は避ける
- attribute_name は下の定義にあるものだけを使う
- tags は3-8件
- summary は人物像が短く分かる2-4文
- 足りない情報については、自然な聞き方の follow_up_questions を3-5件返す

対象: ${_nameController.text.trim()}
利用可能属性:
$allowedDefinitions

観察入力:
$text

${followUpAnswers == null || followUpAnswers.trim().isEmpty ? '' : '追加入力:\n$followUpAnswers\n'}

JSONで返してください:
{
  "category": "人物カテゴリ",
  "tags": ["タグ"],
  "summary": "概要",
  "attributes": [
    {
      "category": "ライフスタイル",
      "attribute_name": "趣味",
      "attribute_value": "カフェ巡り",
      "confidence_score": 72,
      "note": "休日の話題から"
    }
  ],
  "follow_up_questions": ["自然な質問文"]
}
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'category': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'summary': {'type': 'string'},
            'attributes': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'category': {'type': 'string'},
                  'attribute_name': {'type': 'string'},
                  'attribute_value': {'type': 'string'},
                  'confidence_score': {'type': 'integer'},
                  'note': {'type': 'string'},
                },
                'required': [
                  'category',
                  'attribute_name',
                  'attribute_value',
                  'confidence_score',
                  'note',
                ],
              },
            },
            'follow_up_questions': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': [
            'category',
            'tags',
            'summary',
            'attributes',
            'follow_up_questions',
          ],
        },
      );
      await _applyAiPersonSnapshot(
        result,
        dataType: dataType,
        source: followUpAnswers == null || followUpAnswers.trim().isEmpty
            ? '観察インプット'
            : '観察インプット+追加入力',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AIが人物情報を更新しました')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI整理に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() => _isProcessingIntake = false);
      }
    }
  }

  Future<void> _showObservationIntakeSheet() async {
    if (!_isPersonLike) {
      return;
    }
    final intakeController = TextEditingController();
    final followUpController = TextEditingController();
    var dataType = PersonDataType.observation;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final questions = _followUpQuestions();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '観察インプット',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '見聞きした行動、会話、印象をまとめて入れると、AIがタグ・概要・属性を更新し、足りない情報は追加質問として返します。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<PersonDataType>(
                        segments: const [
                          ButtonSegment(
                            value: PersonDataType.observation,
                            label: Text('観察'),
                          ),
                          ButtonSegment(
                            value: PersonDataType.userInterpretation,
                            label: Text('解釈'),
                          ),
                        ],
                        selected: {dataType},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setSheetState(() => dataType = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '観察インプット',
                        controller: intakeController,
                        maxLines: 8,
                        alignLabelWithHint: true,
                        hintText:
                            '例: 3/10にカフェで会話。仕事は忙しいが楽しそうに話していた。Xをよく見ているらしい。映画の話になると急に詳しい。',
                      ),
                      if (questions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'AIからの追加質問',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        for (final question in questions) ...[
                          Text('・$question'),
                          const SizedBox(height: 6),
                        ],
                        const SizedBox(height: 12),
                        SurfaceField(
                          label: '追加質問への回答',
                          controller: followUpController,
                          maxLines: 6,
                          alignLabelWithHint: true,
                          hintText: '質問ごとに分けても、まとめて書いても大丈夫です。',
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessingIntake
                              ? null
                              : () async {
                                  final text = intakeController.text.trim();
                                  final answers = followUpController.text
                                      .trim();
                                  if (text.isEmpty && answers.isEmpty) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  await _processObservationIntake(
                                    text: text.isEmpty ? '追加質問への回答のみ' : text,
                                    dataType: dataType,
                                    followUpAnswers: answers,
                                  );
                                },
                          child: Text(_isProcessingIntake ? '処理中' : 'AIで反映する'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _personAttributeKey(PersonProfileAttribute attribute) {
    return PersonQuestionGuides.attributeKey(
      attribute.category,
      attribute.attributeName,
    );
  }

  List<PersonProfileAttribute> _attributesForDefinition(
    PersonAttributeDefinition definition,
  ) {
    return _personAttributes
        .where(
          (attribute) =>
              attribute.category == definition.category &&
              attribute.attributeName == definition.name,
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  PersonProfileAttribute? _latestAttributeForType(
    PersonAttributeDefinition definition,
    PersonDataType dataType,
  ) {
    final matches = _attributesForDefinition(
      definition,
    ).where((attribute) => attribute.dataType == dataType);
    if (matches.isEmpty) {
      return null;
    }
    return matches.first;
  }

  String _sourceDisplayLabel(String source) {
    switch (source.trim()) {
      case 'manual':
      case '自分の記録':
        return '自分の記録';
      case 'interaction_logs':
        return '会話ログ分析';
      default:
        return source;
    }
  }

  String _inputKindLabel(PersonAttributeDefinition definition) {
    switch (definition.inputKind) {
      case PersonInputKind.scale:
        return '尺度入力';
      case PersonInputKind.category:
        return 'カテゴリ選択';
      case PersonInputKind.freeText:
        return '自由記述';
    }
  }

  Future<void> _showAttributeHelpSheet(
    PersonAttributeDefinition definition,
  ) async {
    final theme = Theme.of(context);
    final tactics = await _loadQuestionTactics(definition);
    final grouped = <QuestionStrategy, List<PersonQuestionTactic>>{};
    for (final tactic in tactics) {
      grouped.putIfAbsent(tactic.questionType, () => []).add(tactic);
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  '${definition.category} / ${definition.name} の質問戦術',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                for (final strategy in QuestionStrategy.values) ...[
                  Text(
                    strategy.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final tactic in grouped[strategy] ?? const []) ...[
                    Text('・${tactic.questionText}'),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditPersonAttributeSheet(
    PersonAttributeDefinition definition, {
    PersonDataType initialType = PersonDataType.fact,
  }) async {
    if (!_isPersonLike) {
      return;
    }
    var dataType = initialType;
    var selectedOption = '';
    final freeTextController = TextEditingController();
    final sourceController = TextEditingController(text: '自分の記録');
    final noteController = TextEditingController();
    final confidenceController = TextEditingController(text: '70');

    bool usesOtherText() => !definition.freeTextOnly && selectedOption == 'その他';

    void syncFromExisting(PersonDataType type) {
      final existing = _latestAttributeForType(definition, type);
      if (existing == null) {
        selectedOption = definition.options.contains('不明')
            ? '不明'
            : (definition.options.isNotEmpty ? definition.options.first : '');
        freeTextController.text = '';
        sourceController.text = '自分の記録';
        noteController.text = '';
        confidenceController.text = type == PersonDataType.aiHypothesis
            ? '60'
            : '70';
        return;
      }
      if (definition.freeTextOnly) {
        selectedOption = '';
        freeTextController.text = existing.attributeValue;
        noteController.text = existing.note ?? '';
      } else if (definition.options.contains(existing.attributeValue)) {
        selectedOption = existing.attributeValue;
        freeTextController.text = existing.note ?? '';
        noteController.text = '';
      } else if (definition.options.contains('その他')) {
        selectedOption = 'その他';
        freeTextController.text = existing.attributeValue;
        noteController.text = existing.note ?? '';
      } else {
        selectedOption = definition.options.contains('不明')
            ? '不明'
            : (definition.options.isNotEmpty ? definition.options.first : '');
        freeTextController.text = existing.attributeValue;
        noteController.text = existing.note ?? '';
      }
      sourceController.text = _sourceDisplayLabel(existing.source);
      confidenceController.text = existing.confidenceScore.toString();
      noteController.text = definition.options.contains(existing.attributeValue)
          ? (existing.note ?? '')
          : '';
    }

    syncFromExisting(dataType);

    Future<void> saveAttribute() async {
      final freeText = freeTextController.text.trim();
      final source = sourceController.text.trim();
      final requiresFreeText = definition.freeTextOnly;
      if (source.isEmpty) {
        return;
      }
      if (requiresFreeText && freeText.isEmpty) {
        return;
      }
      if (!requiresFreeText && selectedOption.isEmpty) {
        return;
      }
      if (usesOtherText() && freeText.isEmpty) {
        return;
      }
      final confidence =
          int.tryParse(confidenceController.text.trim())?.clamp(0, 100) ?? 50;
      final note = _nullable(noteController.text);
      final value = requiresFreeText
          ? freeText
          : (usesOtherText() ? freeText : selectedOption);
      final storedNote = requiresFreeText
          ? note
          : (usesOtherText() ? note : _nullable(freeText));
      await _db.personProfileAttributesDao.upsertAttributeForType(
        targetId: widget.targetId,
        category: definition.category,
        attributeName: definition.name,
        attributeValue: value,
        dataType: dataType,
        confidenceScore: confidence,
        source: source,
        note: storedNote,
      );
      await _db.archiveTargetsDao.touchTarget(widget.targetId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await _load();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${definition.category} / ${definition.name}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'この項目の説明',
                            onPressed: () =>
                                _showAttributeHelpSheet(definition),
                            icon: const Icon(Icons.help_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        definition.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '入力形式: ${_inputKindLabel(definition)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<PersonDataType>(
                        segments: PersonDataType.values
                            .map(
                              (value) => ButtonSegment(
                                value: value,
                                label: Text(value.shortLabel),
                              ),
                            )
                            .toList(),
                        selected: {dataType},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setSheetState(() {
                            dataType = selection.first;
                            syncFromExisting(dataType);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!definition.freeTextOnly) ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedOption.isEmpty
                              ? null
                              : selectedOption,
                          decoration: const InputDecoration(
                            labelText: '選択値',
                            border: OutlineInputBorder(),
                          ),
                          items: definition.options
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setSheetState(() => selectedOption = value);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      SurfaceField(
                        label: definition.freeTextOnly
                            ? '入力値'
                            : (usesOtherText() ? 'その他の具体値' : '補足'),
                        controller: freeTextController,
                        maxLines: 3,
                        alignLabelWithHint: true,
                        hintText: definition.freeTextOnly
                            ? 'この属性の内容を入力'
                            : (usesOtherText()
                                  ? '「その他」の具体的な内容を入力'
                                  : '選択値だけでは足りない補足を入力'),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: definition.observationClues
                            .map((clue) => Chip(label: Text(clue)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '確信度 (0-100)',
                        controller: confidenceController,
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '出典・根拠',
                        controller: sourceController,
                        hintText: '例: 自分の記録 / 本人発言 / SNS / 書籍',
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '補足メモ',
                        controller: noteController,
                        maxLines: 3,
                        alignLabelWithHint: true,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saveAttribute,
                          child: const Text('保存する'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deletePersonAttribute(int attributeId) async {
    await _db.personProfileAttributesDao.deleteAttribute(attributeId);
    await _db.archiveTargetsDao.touchTarget(widget.targetId);
    await _load();
  }

  Future<void> _extractAttributesFromInteractions() async {
    if (!_isPersonLike) {
      return;
    }
    final interactionEntries = _entries
        .where(
          (entry) =>
              entry.entryType == ArchiveEntryType.interaction ||
              entry.entryType == ArchiveEntryType.observation,
        )
        .toList();
    if (interactionEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('解析できるやりとり・観察記録がありません')));
      return;
    }
    setState(() => _isExtractingAttributes = true);
    try {
      final allowedDefinitions = PersonQuestionGuides.definitions
          .map((definition) => '${definition.category} / ${definition.name}')
          .join('\n');
      final conversationText = interactionEntries
          .map((entry) {
            return [
              '種別: ${entry.entryType.label}',
              'データ種別: ${entry.dataType.label}',
              '確信度: ${entry.confidenceScore}',
              '出典: ${entry.source}',
              if ((entry.title ?? '').isNotEmpty) 'タイトル: ${entry.title}',
              '内容: ${entry.content}',
            ].join('\n');
          })
          .join('\n\n');
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは人物理解アシスタントです。
以下の会話・観察ログから、その人物について明示的に言えることだけを整理してください。

ルール:
- 出力は人物理解の補助用で、すべて AI_HYPOTHESIS として扱う
- 断定しない
- センシティブな推定はしない
- 下の属性定義にない attribute_name は使わない
- attribute_value は選択肢を優先し、必要なら短い自由記述にする

対象: ${_nameController.text.trim()}
利用可能な属性定義:
$allowedDefinitions

ログ:
$conversationText

出力形式:
{
  "attributes": [
    {
      "category": "思考スタイル",
      "attribute_name": "意思決定スタイル",
      "attribute_value": "比較してから決める傾向がある",
      "confidence_score": 62,
      "source": "interaction_logs",
      "note": "複数の発言で比較検討が見られた"
    }
  ]
}
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'attributes': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'category': {'type': 'string'},
                  'attribute_name': {'type': 'string'},
                  'attribute_value': {'type': 'string'},
                  'confidence_score': {'type': 'integer'},
                  'source': {'type': 'string'},
                  'note': {'type': 'string'},
                },
                'required': [
                  'category',
                  'attribute_name',
                  'attribute_value',
                  'confidence_score',
                  'source',
                  'note',
                ],
              },
            },
          },
          'required': ['attributes'],
        },
      );
      final items = (result['attributes'] as List<dynamic>? ?? const []);
      for (final item in items) {
        final map = Map<String, dynamic>.from(item as Map);
        final category = map['category'].toString();
        final attributeName = map['attribute_name'].toString();
        final definition = PersonQuestionGuides.definitionByKey(
          category,
          attributeName,
        );
        if (definition == null) {
          continue;
        }
        await _db.personProfileAttributesDao.upsertAttributeForType(
          targetId: widget.targetId,
          category: definition.category,
          attributeName: definition.name,
          attributeValue: map['attribute_value'].toString(),
          dataType: PersonDataType.aiHypothesis,
          confidenceScore:
              (map['confidence_score'] as num?)?.toInt().clamp(0, 100) ?? 50,
          source: map['source'].toString(),
          note: map['note'].toString(),
        );
      }
      await _db.archiveTargetsDao.touchTarget(widget.targetId);
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${items.length}件のAI仮説を追加しました')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('会話解析に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() => _isExtractingAttributes = false);
      }
    }
  }

  Future<void> _showAddEntrySheet() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final happenedAtController = TextEditingController();
    final locationController = TextEditingController();
    final sourceController = TextEditingController(text: '自分の記録');
    final confidenceController = TextEditingController(text: '70');
    var selectedType = ArchiveEntryType.note;
    var dataType = PersonDataType.observation;

    Future<void> saveEntry(StateSetter setSheetState) async {
      if (contentController.text.trim().isEmpty) {
        return;
      }
      final confidence =
          int.tryParse(confidenceController.text.trim())?.clamp(0, 100) ?? 50;
      await _db.archiveTargetsDao.insertEntry(
        ArchiveEntriesCompanion.insert(
          targetId: widget.targetId,
          entryType: selectedType,
          title: Value(_nullable(titleController.text)),
          content: contentController.text.trim(),
          happenedAt: Value(
            happenedAtController.text.trim().isEmpty
                ? null
                : DateFormat(
                    'yyyy/MM/dd',
                  ).parse(happenedAtController.text.trim()),
          ),
          location: Value(_nullable(locationController.text)),
          dataType: Value(dataType),
          confidenceScore: Value(confidence),
          source: Value(sourceController.text.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _db.archiveTargetsDao.touchTarget(widget.targetId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await _load();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '記録を追加',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ArchiveEntryType>(
                        segments: ArchiveEntryType.values
                            .map(
                              (type) => ButtonSegment(
                                value: type,
                                label: Text(type.label),
                              ),
                            )
                            .toList(),
                        selected: {selectedType},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setSheetState(() => selectedType = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(label: 'タイトル', controller: titleController),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '内容',
                        controller: contentController,
                        maxLines: 5,
                        alignLabelWithHint: true,
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '日付',
                        controller: happenedAtController,
                        readOnly: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(now.year + 10),
                            );
                            if (picked != null) {
                              happenedAtController.text =
                                  '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(label: '場所', controller: locationController),
                      const SizedBox(height: 16),
                      SegmentedButton<PersonDataType>(
                        segments: PersonDataType.values
                            .map(
                              (value) => ButtonSegment(
                                value: value,
                                label: Text(value.label.split('_').first),
                              ),
                            )
                            .toList(),
                        selected: {dataType},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setSheetState(() => dataType = selection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '確信度 (0-100)',
                        controller: confidenceController,
                      ),
                      const SizedBox(height: 16),
                      SurfaceField(
                        label: '出典・根拠',
                        controller: sourceController,
                        hintText: '例: 自分の記録 / 会話 / SNS / 書籍',
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => saveEntry(setSheetState),
                          child: const Text('追加する'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEntry(int entryId) async {
    await _db.archiveTargetsDao.deleteEntry(entryId);
    await _load();
  }

  Widget _buildAttributeRecordChip(
    BuildContext context,
    PersonProfileAttribute attribute,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.archive, 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  attribute.dataType.shortLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.archive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deletePersonAttribute(attribute.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(attribute.attributeValue),
          const SizedBox(height: 6),
          Text(
            '確信度 ${attribute.confidenceScore} / 出典 ${_sourceDisplayLabel(attribute.source)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          if ((attribute.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(attribute.note!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonDefinitionRow(
    BuildContext context,
    PersonAttributeDefinition definition,
  ) {
    final theme = Theme.of(context);
    final records = _attributesForDefinition(definition);
    final latestFact = _latestAttributeForType(definition, PersonDataType.fact);
    final latestObservation = _latestAttributeForType(
      definition,
      PersonDataType.observation,
    );
    final latestInterpretation = _latestAttributeForType(
      definition,
      PersonDataType.userInterpretation,
    );
    final latestAi = _latestAttributeForType(
      definition,
      PersonDataType.aiHypothesis,
    );
    final visibleRecords = [
      latestFact,
      latestObservation,
      latestInterpretation,
      latestAi,
    ].whereType<PersonProfileAttribute>().toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          definition.name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (definition.intrusive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '関係性配慮',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      definition.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _showEditPersonAttributeSheet(definition),
                child: Text(records.isEmpty ? '入力' : '編集'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            definition.freeTextOnly
                ? '入力形式: 自由記述'
                : '入力形式: ${_inputKindLabel(definition)} / 選択肢: ${definition.options.join(' / ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          if (visibleRecords.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '未入力',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
          for (final record in visibleRecords)
            _buildAttributeRecordChip(context, record),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final theme = Theme.of(context);
    final knownAttributeKeys = _personAttributes
        .map(_personAttributeKey)
        .toSet();
    final completedAttributeCount = knownAttributeKeys.length;
    final totalAttributeCount = PersonQuestionGuides.definitions.length;
    final definitionsByCategory =
        PersonQuestionGuides.definitionMapByCategory();
    final followUpQuestions = _followUpQuestions();

    if (_isLoading || target == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(target.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isSaving ? null : _save,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTarget,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntrySheet,
        backgroundColor: AppPalette.archive,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('記録を追加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.soften(AppPalette.archive, 0.82),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        target.targetType.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppPalette.archive,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (target.targetType == ArchiveTargetType.publicFigure)
                      TextButton.icon(
                        onPressed: _isAutofilling
                            ? null
                            : _autofillPublicFigure,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(_isAutofilling ? '補完中' : 'AI補完'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SurfaceField(
                  label: _isPersonLike ? '表示名・通称' : '名前',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                SurfaceField(label: 'カテゴリ', controller: _categoryController),
                const SizedBox(height: 16),
                SurfaceField(label: 'タグ', controller: _tagsController),
                const SizedBox(height: 16),
                SurfaceField(
                  label: '概要',
                  controller: _summaryController,
                  maxLines: 5,
                  alignLabelWithHint: true,
                ),
                if (target.targetType == ArchiveTargetType.person ||
                    target.targetType == ArchiveTargetType.publicFigure) ...[
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: '出会った日・初めて知った日',
                    controller: _firstMetAtController,
                    readOnly: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () => _pickDate(_firstMetAtController),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: '出会った場所・接点',
                    controller: _firstMetPlaceController,
                  ),
                ],
                if (target.targetType == ArchiveTargetType.place) ...[
                  const SizedBox(height: 16),
                  SurfaceField(label: '住所', controller: _addressController),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: 'Google Maps URL',
                    controller: _mapUrlController,
                    suffixIcon: _mapUrlController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => _openUrl(_mapUrlController.text),
                          ),
                  ),
                ],
                if (target.targetType == ArchiveTargetType.publicFigure) ...[
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: '参考URL',
                    controller: _sourceUrlController,
                    suffixIcon: _sourceUrlController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () =>
                                _openUrl(_sourceUrlController.text),
                          ),
                  ),
                ],
              ],
            ),
          ),
          if (_isPersonLike) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '人物理解',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showQuestionGuideSheet,
                        icon: const Icon(Icons.question_answer_outlined),
                        label: const Text('質問ガイド'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '事実、観察、ユーザー解釈、AI仮説を分けて扱います。AI出力は上書きせず、必ず仮説として残します。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isProcessingIntake
                            ? null
                            : _showObservationIntakeSheet,
                        icon: const Icon(Icons.auto_fix_high_outlined),
                        label: Text(_isProcessingIntake ? '処理中' : '観察インプット'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isExtractingAttributes
                            ? null
                            : _extractAttributesFromInteractions,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          _isExtractingAttributes ? '解析中' : '会話から仮説抽出',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '入力済み $completedAttributeCount / $totalAttributeCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (followUpQuestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'AIからの追加質問',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final question in followUpQuestions.take(4)) ...[
                      Text('・$question'),
                      const SizedBox(height: 6),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '人物プロファイル',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final category in PersonQuestionGuides.categoryOrder) ...[
              if ((definitionsByCategory[category] ?? const []).isNotEmpty)
                SurfaceCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          category,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${(definitionsByCategory[category] ?? const []).where((definition) => knownAttributeKeys.contains(PersonQuestionGuides.attributeKey(definition.category, definition.name))).length}'
                          ' / ${(definitionsByCategory[category] ?? const []).length} 入力済み',
                        ),
                        children: [
                          const SizedBox(height: 4),
                          for (final definition
                              in definitionsByCategory[category] ??
                                  const []) ...[
                            _buildPersonDefinitionRow(context, definition),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '分析',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeTarget,
                      icon: const Icon(Icons.insights_outlined),
                      label: Text(_isAnalyzing ? '分析中' : '分析する'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '要約',
                  controller: _analysisSummaryController,
                  maxLines: 4,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 16),
                SurfaceField(
                  label: '傾向',
                  controller: _analysisTraitsController,
                  maxLines: 5,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 16),
                SurfaceField(
                  label: 'MBTI傾向',
                  controller: _mbtiGuessController,
                  hintText: '例: INFP傾向',
                ),
                const SizedBox(height: 16),
                SurfaceField(
                  label: 'MBTIメモ',
                  controller: _mbtiNoteController,
                  maxLines: 4,
                  alignLabelWithHint: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isPersonLike ? '会話・観察ログ' : '記録',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_entries.isEmpty)
            SurfaceCard(
              child: Text(
                'まだ記録がありません。やりとり、観察、訪問メモを追加できます。',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          for (final entry in _entries) ...[
            SurfaceCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.entryType.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppPalette.archive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.soften(AppPalette.archive, 0.86),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          entry.dataType.shortLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppPalette.archive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(entry.id),
                      ),
                    ],
                  ),
                  if ((entry.title ?? '').isNotEmpty) ...[
                    Text(
                      entry.title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(entry.content),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (entry.happenedAt != null)
                        Text(
                          DateFormat('yyyy/MM/dd').format(entry.happenedAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      if ((entry.location ?? '').isNotEmpty)
                        Text(
                          entry.location!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      Text(
                        '確信度 ${entry.confidenceScore} / 出典 ${_sourceDisplayLabel(entry.source)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
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
