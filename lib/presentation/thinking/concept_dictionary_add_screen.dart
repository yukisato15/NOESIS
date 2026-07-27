import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/concept_dictionaries_table.dart';
import '../shared/surface_field.dart';

class ConceptDictionaryAddScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContext;
  final bool autoGenerateOnLoad;
  final ConceptOrigin origin;

  const ConceptDictionaryAddScreen({
    super.key,
    this.initialTitle,
    this.initialContext,
    this.autoGenerateOnLoad = false,
    this.origin = ConceptOrigin.direct,
  });

  @override
  State<ConceptDictionaryAddScreen> createState() =>
      _ConceptDictionaryAddScreenState();
}

class _ConceptDictionaryAddScreenState
    extends State<ConceptDictionaryAddScreen> {
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

  bool _isGenerating = false;
  bool _isSaving = false;
  AIMode _selectedMode = AIMode.standard;
  int _remainingSearches = 100;

  // Quote Capture用の画像管理
  XFile? _sourceImage;

  @override
  void initState() {
    super.initState();
    _loadSearchUsage();
    _db.ensureConceptDictionaryColumns();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleController.text = widget.initialTitle!.trim();
    }
    if (widget.autoGenerateOnLoad &&
        widget.initialTitle != null &&
        widget.initialTitle!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isGenerating) {
          _generate();
        }
      });
    }
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

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _sourceImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('撮影に失敗しました: $e')));
      }
    }
  }

  Future<void> _pickSourceImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _sourceImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('画像の選択に失敗しました: $e')));
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          _titleController.text = data.text!;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('クリップボードから貼り付けました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('貼り付けに失敗しました: $e')));
      }
    }
  }

  Map<String, dynamic> _conceptSchema() {
    return {
      'type': 'object',
      'properties': {
        'category': {'type': 'string'},
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'description': {'type': 'string'},
        'memo': {'type': 'string'},
        'reference_urls': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'similar_concepts': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'contrasting_concepts': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'related_concepts': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'cultural_background': {'type': 'string'},
        'practical_advice': {'type': 'string'},
        'case_studies': {'type': 'string'},
        'gyaru_explanation': {'type': 'string'},
        'child_explanation': {'type': 'string'},
      },
      'required': ['description'],
    };
  }

  Future<void> _generate() async {
    final term = _titleController.text.trim();
    if (term.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('概念名を入力してください。')));
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final contextNote = widget.initialContext?.trim();
      final prompt =
          '''
あなたは哲学的対話に強い編集者です。
以下の概念について、概念辞書に登録するための詳細情報を生成してください。
固有名詞（人物名・キャラクター名・作品名・団体名など）はできる限り避け、
抽象化した「概念・原理・考え方」に言い換えてください。
ただし、歴史的に提唱者として重要な場合（例: 19世紀にマルクスが提唱など）は
必要最小限で触れて構いません。

概念名: $term
${contextNote == null || contextNote.isEmpty ? '' : '\n# 対話の要約・ログ\n$contextNote\n'}
出力はJSON形式で、以下のキーを含めてください。
- category: 適切なカテゴリ（例: 哲学、倫理学、認識論、美学、論理学、社会哲学）
- tags: 関連するタグの配列（3-5個程度）
- description: 概念の説明（日本語・明瞭・詳細に）
- memo: 補足メモや重要なポイント
- reference_urls: 参考になるURLの配列（実在するもののみ）
- similar_concepts: 類似の概念の配列
- contrasting_concepts: 対比される概念の配列
- related_concepts: 関連する概念の配列
- cultural_background: 文化的・歴史的背景
- practical_advice: 理解や応用のためのワンポイントアドバイス
- case_studies: 実践例やケーススタディ
- gyaru_explanation: ギャルによる説明（短くポジティブに）
- child_explanation: 幼稚園児でも理解できるよう説明（例え話を含める）
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

      // 各フィールドに値を設定
      if (json['category'] != null) {
        _categoryController.text = json['category'].toString();
      }
      if (json['tags'] != null && json['tags'] is List) {
        final tags = (json['tags'] as List).map((e) => e.toString()).toList();
        _tagsController.text = tags.join(', ');
      }
      if (json['description'] != null) {
        _bodyController.text = json['description'].toString();
      }
      if (json['memo'] != null) {
        _memoController.text = json['memo'].toString();
      }
      if (json['reference_urls'] != null && json['reference_urls'] is List) {
        final urls = (json['reference_urls'] as List)
            .map((e) => e.toString())
            .toList();
        _referenceUrlsController.text = urls.join('\n');
      }
      if (json['similar_concepts'] != null &&
          json['similar_concepts'] is List) {
        final concepts = (json['similar_concepts'] as List)
            .map((e) => e.toString())
            .toList();
        _similarConceptsController.text = concepts.join('\n');
      }
      if (json['contrasting_concepts'] != null &&
          json['contrasting_concepts'] is List) {
        final concepts = (json['contrasting_concepts'] as List)
            .map((e) => e.toString())
            .toList();
        _contrastingConceptsController.text = concepts.join('\n');
      }
      if (json['related_concepts'] != null &&
          json['related_concepts'] is List) {
        final concepts = (json['related_concepts'] as List)
            .map((e) => e.toString())
            .toList();
        _relatedConceptsController.text = concepts.join('\n');
      }
      if (json['cultural_background'] != null) {
        _culturalBackgroundController.text = json['cultural_background']
            .toString();
      }
      if (json['practical_advice'] != null) {
        _practicalAdviceController.text = json['practical_advice'].toString();
      }
      if (json['case_studies'] != null) {
        _caseStudiesController.text = json['case_studies'].toString();
      }
      if (json['gyaru_explanation'] != null) {
        _gyaruExplanationController.text = json['gyaru_explanation'].toString();
      }
      if (json['child_explanation'] != null) {
        _childExplanationController.text = json['child_explanation'].toString();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成に失敗しました: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
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
    if (_isSaving) {
      return;
    }
    await _db.ensureConceptDictionaryColumns();
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

    try {
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

      await _db
          .into(_db.conceptDictionaries)
          .insert(
            ConceptDictionariesCompanion.insert(
              title: title,
              body: body,
              origin: Value(widget.origin),
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
              contrastingConcepts: Value(
                _listToJson(_contrastingConceptsController),
              ),
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
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final originLabel = widget.origin == ConceptOrigin.dialogue
        ? '対話から登録'
        : '直接入力';

    return Scaffold(
      appBar: AppBar(
        title: const Text('概念辞書を入力'),
        actions: [
          TextButton(
            onPressed: (_isGenerating || _isSaving) ? null : _save,
            child: Text(
              '保存',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppPalette.thinking,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              '登録経路: $originLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            // 概念名入力（一番上）
            SurfaceField(
              label: '概念名',
              hintText: '例: 形式的包摂と実質的包摂',
              controller: _titleController,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'カメラで撮影',
                    onPressed: _takePhoto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'ギャラリーから選択',
                    onPressed: _pickSourceImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    tooltip: 'クリップボードから貼り付け',
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 画像プレビュー（撮影後のみ表示）
            if (_sourceImage != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('撮影した画像', style: theme.textTheme.titleSmall),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _sourceImage = null;
                              });
                            },
                            tooltip: '画像を削除',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '※ 2本指でズーム → 画像を長押しして範囲選択 → コピー → 上の貼り付けボタン',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LiveTextImageView(
                          imagePath: _sourceImage!.path,
                          height: 400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI生成',
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: _isGenerating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? '生成中...' : 'AIで生成'),
                    ),
                  ),
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
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: 'タグ',
                    hintText: 'カンマ区切りで入力: タグ1, タグ2, タグ3',
                    controller: _tagsController,
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
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: 'メモ',
              hintText: '補足メモや重要なポイント',
              controller: _memoController,
              maxLines: 3,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '参考URL',
              hintText: '1行に1つずつURLを入力',
              controller: _referenceUrlsController,
              maxLines: 3,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '類似の概念',
              hintText: '1行に1つずつ入力',
              controller: _similarConceptsController,
              maxLines: 2,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '対比される概念',
              hintText: '1行に1つずつ入力',
              controller: _contrastingConceptsController,
              maxLines: 2,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '関連する概念',
              hintText: '1行に1つずつ入力',
              controller: _relatedConceptsController,
              maxLines: 2,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '文化的・歴史的背景',
              controller: _culturalBackgroundController,
              maxLines: 4,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: 'ワンポイントアドバイス',
              hintText: '理解や応用のためのアドバイス',
              controller: _practicalAdviceController,
              maxLines: 3,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '実践例・ケーススタディ',
              controller: _caseStudiesController,
              maxLines: 4,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: 'ギャルによる説明',
              controller: _gyaruExplanationController,
              maxLines: 4,
              alignLabelWithHint: true,
            ),
            const SizedBox(height: 12),
            SurfaceField(
              label: '幼稚園児でも理解できるよう説明',
              controller: _childExplanationController,
              maxLines: 4,
              alignLabelWithHint: true,
            ),
          ],
        ),
      ),
    );
  }
}
