import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/concept_dictionaries_table.dart';
import '../shared/surface_field.dart';
import '../shared/text_action_sheet.dart';

class ConceptDictionaryDetailScreen extends StatefulWidget {
  final int conceptId;

  const ConceptDictionaryDetailScreen({super.key, required this.conceptId});

  @override
  State<ConceptDictionaryDetailScreen> createState() =>
      _ConceptDictionaryDetailScreenState();
}

class _ConceptDictionaryDetailScreenState
    extends State<ConceptDictionaryDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _referenceUrlsController =
      TextEditingController();
  final TextEditingController _similarConceptsController =
      TextEditingController();
  final TextEditingController _contrastingConceptsController =
      TextEditingController();
  final TextEditingController _relatedConceptsController =
      TextEditingController();
  final TextEditingController _culturalBackgroundController =
      TextEditingController();
  final TextEditingController _practicalAdviceController =
      TextEditingController();
  final TextEditingController _caseStudiesController = TextEditingController();
  final TextEditingController _gyaruExplanationController =
      TextEditingController();
  final TextEditingController _childExplanationController =
      TextEditingController();

  ConceptDictionary? _concept;
  bool _isSaving = false;
  bool _isRefining = false;

  // AIモード選択
  AIMode _selectedMode = AIMode.standard;
  int _remainingSearches = 100;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSearchUsage();
  }

  Future<void> _loadSearchUsage() async {
    if (!SearchClient.canUseWebSearch) {
      if (mounted) {
        setState(() {
          _remainingSearches = 0;
        });
      }
      return;
    }
    final remaining = await SearchClient.instance.getRemainingGoogleSearches();
    if (mounted) {
      setState(() {
        _remainingSearches = remaining;
      });
    }
  }

  @override
  void dispose() {
    _db.close();
    _titleController.dispose();
    _bodyController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _memoController.dispose();
    _referenceUrlsController.dispose();
    _similarConceptsController.dispose();
    _contrastingConceptsController.dispose();
    _relatedConceptsController.dispose();
    _culturalBackgroundController.dispose();
    _practicalAdviceController.dispose();
    _caseStudiesController.dispose();
    _gyaruExplanationController.dispose();
    _childExplanationController.dispose();
    super.dispose();
  }

  String _originLabel(ConceptOrigin origin) {
    switch (origin) {
      case ConceptOrigin.direct:
        return '直接入力';
      case ConceptOrigin.dialogue:
        return '対話から登録';
    }
  }

  Map<String, dynamic> _conceptSchema() {
    return {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'description': {'type': 'string'},
        'background': {'type': 'string'},
        'structure': {'type': 'string'},
      },
      'required': ['title', 'description', 'background', 'structure'],
    };
  }

  String _buildBody(Map<String, dynamic> json) {
    final description = (json['description'] ?? '').toString().trim();
    final background = (json['background'] ?? '').toString().trim();
    final structure = (json['structure'] ?? '').toString().trim();

    return [
      '説明\n$description',
      '背景\n$background',
      '構造的整理\n$structure',
    ].join('\n\n');
  }

  String? _jsonToList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final list = (jsonDecode(jsonStr) as List).cast<String>();
      return list.join('\n');
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final concept = await (_db.select(
      _db.conceptDictionaries,
    )..where((t) => t.id.equals(widget.conceptId))).getSingle();

    if (!mounted) {
      return;
    }

    setState(() {
      _concept = concept;
      _titleController.text = concept.title;
      _bodyController.text = concept.body;
      _categoryController.text = concept.category ?? '';

      // タグをカンマ区切りに変換
      if (concept.tags != null && concept.tags!.isNotEmpty) {
        try {
          final tags = (jsonDecode(concept.tags!) as List).cast<String>();
          _tagsController.text = tags.join(', ');
        } catch (_) {
          _tagsController.text = '';
        }
      }

      _memoController.text = concept.memo ?? '';
      _referenceUrlsController.text = _jsonToList(concept.referenceUrls) ?? '';
      _similarConceptsController.text =
          _jsonToList(concept.similarConcepts) ?? '';
      _contrastingConceptsController.text =
          _jsonToList(concept.contrastingConcepts) ?? '';
      _relatedConceptsController.text =
          _jsonToList(concept.relatedConcepts) ?? '';
      _culturalBackgroundController.text = concept.culturalBackground ?? '';
      _practicalAdviceController.text = concept.practicalAdvice ?? '';
      _caseStudiesController.text = concept.caseStudies ?? '';
      _gyaruExplanationController.text = concept.gyaruExplanation ?? '';
      _childExplanationController.text = concept.childExplanation ?? '';
    });
  }

  String? _listToJson(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final items = text
        .split('\n')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (items.isEmpty) return null;
    return jsonEncode(items);
  }

  Future<void> _save() async {
    if (_concept == null) {
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('概念名と内容を入力してください。')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // タグをJSON配列に変換
    String? tagsJson;
    final tagsText = _tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      final tagsList = tagsText
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tagsList.isNotEmpty) {
        tagsJson = jsonEncode(tagsList);
      }
    }

    final updated = _concept!.copyWith(
      title: title,
      body: body,
      category: Value(
        _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
      ),
      tags: Value(tagsJson),
      memo: Value(
        _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
      ),
      referenceUrls: Value(_listToJson(_referenceUrlsController)),
      similarConcepts: Value(_listToJson(_similarConceptsController)),
      contrastingConcepts: Value(_listToJson(_contrastingConceptsController)),
      relatedConcepts: Value(_listToJson(_relatedConceptsController)),
      culturalBackground: Value(
        _culturalBackgroundController.text.trim().isEmpty
            ? null
            : _culturalBackgroundController.text.trim(),
      ),
      practicalAdvice: Value(
        _practicalAdviceController.text.trim().isEmpty
            ? null
            : _practicalAdviceController.text.trim(),
      ),
      caseStudies: Value(
        _caseStudiesController.text.trim().isEmpty
            ? null
            : _caseStudiesController.text.trim(),
      ),
      gyaruExplanation: Value(
        _gyaruExplanationController.text.trim().isEmpty
            ? null
            : _gyaruExplanationController.text.trim(),
      ),
      childExplanation: Value(
        _childExplanationController.text.trim().isEmpty
            ? null
            : _childExplanationController.text.trim(),
      ),
      updatedAt: DateTime.now(),
    );

    await _db.update(_db.conceptDictionaries).replace(updated);

    if (mounted) {
      setState(() {
        _concept = updated;
        _isSaving = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('概念辞書を削除しますか？'),
          content: const Text('この項目を削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await (_db.delete(
      _db.conceptDictionaries,
    )..where((t) => t.id.equals(widget.conceptId))).go();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _aiRefine() async {
    if (_concept == null) {
      return;
    }

    final instructionController = TextEditingController();
    final instruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('AI修正'),
          content: TextField(
            controller: instructionController,
            decoration: const InputDecoration(
              labelText: '修正指示',
              hintText: '例: ここはもっと具体例を入れて',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(instructionController.text.trim());
              },
              child: const Text('修正する'),
            ),
          ],
        );
      },
    );

    instructionController.dispose();

    if (instruction == null || instruction.isEmpty) {
      return;
    }

    setState(() {
      _isRefining = true;
    });

    try {
      final prompt =
          '''
以下の概念辞書の内容を、ユーザーの指示に従って修正してください。

# 概念名
${_titleController.text.trim()}

# 現在の内容
${_bodyController.text.trim()}

# ユーザーの指示
$instruction

出力はJSON形式で、以下のキーを必ず含めてください。
- title: 概念名（要約してよい）
- description: 概念の説明（日本語・明瞭）
- background: 背景や文脈（歴史・対比・由来を含める）
- structure: 概念の構造的整理（対比や区別、関係性を示す）
''';

      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: _conceptSchema(),
        mode: _selectedMode,
      );

      // 検索使用後、残り回数を更新
      if (_selectedMode == AIMode.withSearch) {
        await _loadSearchUsage();
      }

      final title = (json['title'] ?? _titleController.text).toString();
      final body = _buildBody(json);

      if (mounted) {
        setState(() {
          _titleController.text = title;
          _bodyController.text = body;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI修正に失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefining = false;
        });
      }
    }
  }

  Widget _buildAIModeSelector() {
    final availableModes = AIMode.values
        .where(
          (mode) => mode != AIMode.withSearch || SearchClient.canUseWebSearch,
        )
        .toList();
    return SegmentedButton<AIMode>(
      segments: availableModes
          .map((mode) => ButtonSegment(value: mode, label: Text(mode.label)))
          .toList(),
      selected: {_selectedMode},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      onSelectionChanged: (selection) {
        setState(() {
          _selectedMode = selection.first;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('概念辞書'),
        actions: [
          IconButton(
            icon: _isRefining
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            tooltip: 'AI修正',
            onPressed: _isRefining ? null : _aiRefine,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: '保存',
            onPressed: _isSaving ? null : _save,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            onPressed: _delete,
          ),
        ],
      ),
      body: _concept == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    '登録経路: ${_originLabel(_concept!.origin)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '概念名',
                    controller: _titleController,
                    onLongPress: () =>
                        showTextActionSheet(context, _titleController.text),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AIモード',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildAIModeSelector(),
                        const SizedBox(height: 8),
                        Text(
                          _selectedMode.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        if (_selectedMode == AIMode.withSearch) ...[
                          const SizedBox(height: 6),
                          Text(
                            '残り検索回数: $_remainingSearches / 100',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _remainingSearches > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'メタデータ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SurfaceField(
                          label: 'カテゴリ/ジャンル',
                          hintText: '例: 哲学、経済学、社会学',
                          controller: _categoryController,
                          onLongPress: () => showTextActionSheet(
                            context,
                            _categoryController.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SurfaceField(
                          label: 'タグ',
                          hintText: 'カンマ区切りで入力',
                          controller: _tagsController,
                          onLongPress: () => showTextActionSheet(
                            context,
                            _tagsController.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: '概念の説明',
                    controller: _bodyController,
                    maxLines: 6,
                    alignLabelWithHint: true,
                    onLongPress: () =>
                        showTextActionSheet(context, _bodyController.text),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: 'メモ',
                    hintText: '補足メモや重要なポイント',
                    controller: _memoController,
                    maxLines: 3,
                    alignLabelWithHint: true,
                    onLongPress: () =>
                        showTextActionSheet(context, _memoController.text),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '参考URL',
                    hintText: '1行に1つずつURLを入力',
                    controller: _referenceUrlsController,
                    maxLines: 3,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _referenceUrlsController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '類似の概念',
                    hintText: '1行に1つずつ入力',
                    controller: _similarConceptsController,
                    maxLines: 2,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _similarConceptsController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '対比される概念',
                    hintText: '1行に1つずつ入力',
                    controller: _contrastingConceptsController,
                    maxLines: 2,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _contrastingConceptsController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '関連する概念',
                    hintText: '1行に1つずつ入力',
                    controller: _relatedConceptsController,
                    maxLines: 2,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _relatedConceptsController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '文化的・歴史的背景',
                    controller: _culturalBackgroundController,
                    maxLines: 4,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _culturalBackgroundController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: 'ワンポイントアドバイス',
                    hintText: '理解や応用のためのアドバイス',
                    controller: _practicalAdviceController,
                    maxLines: 3,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _practicalAdviceController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '実践例・ケーススタディ',
                    controller: _caseStudiesController,
                    maxLines: 4,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _caseStudiesController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: 'ギャルによる説明',
                    controller: _gyaruExplanationController,
                    maxLines: 4,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _gyaruExplanationController.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '幼稚園児でも理解できるよう説明',
                    controller: _childExplanationController,
                    maxLines: 4,
                    alignLabelWithHint: true,
                    onLongPress: () => showTextActionSheet(
                      context,
                      _childExplanationController.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI修正は履歴を残しません。必要なら保存前にコピーしてください。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
