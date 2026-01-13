import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';

/// 日常メモ追加画面
/// タブで2種類のメモを切り替えて登録: 状況・出来事、思考メモ
class DailyMemoAddScreen extends ConsumerStatefulWidget {
  final String? initialContent;

  const DailyMemoAddScreen({
    super.key,
    this.initialContent,
  });

  @override
  ConsumerState<DailyMemoAddScreen> createState() =>
      _DailyMemoAddScreenState();
}

class _DailyMemoAddScreenState extends ConsumerState<DailyMemoAddScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _situationController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();

  late TabController _tabController;
  XFile? _sourceImage;
  bool _isSaving = false;
  bool _isGeneratingMetadata = false;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialContent != null &&
        widget.initialContent!.trim().isNotEmpty) {
      _thoughtController.text = widget.initialContent!.trim();
      _tabController.index = 1; // 思考メモタブに移動
    }
  }

  @override
  void dispose() {
    _situationController.dispose();
    _thoughtController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _tabController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗しました: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の選択に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          controller.text = data.text!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('クリップボードから貼り付けました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('貼り付けに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _generateMetadata() async {
    // メモ内容を取得
    final situation = _situationController.text.trim();
    final thought = _thoughtController.text.trim();

    if (situation.isEmpty && thought.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メモ内容を先に入力してください')),
      );
      return;
    }

    setState(() {
      _isGeneratingMetadata = true;
    });

    try {
      final content = situation.isNotEmpty
          ? '状況: $situation\n思考: $thought'
          : thought;

      final prompt = '''
以下の日常メモから、適切なメタ情報を生成してください。

【メモ内容】
$content

以下の情報を生成してください：
1. タイトル: メモの内容を端的に表す短いタイトル（10文字以内）
2. カテゴリ: メモの分類（例: 仕事、学習、プライベート、アイデアなど）
3. タグ: 関連するキーワード（2-4個）
''';

      final schema = {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'メモのタイトル（10文字以内）'},
          'category': {'type': 'string', 'description': 'メモのカテゴリ'},
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '関連タグ（2-4個）'
          }
        },
        'required': ['title', 'category', 'tags']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      final title = result['title'] as String;
      final category = result['category'] as String;
      final tags =
          (result['tags'] as List<dynamic>).map((e) => e.toString()).toList();

      if (mounted) {
        setState(() {
          _titleController.text = title;
          _categoryController.text = category;
          _tagsController.text = tags.join(', ');
          _isGeneratingMetadata = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メタ情報を生成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingMetadata = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メタ情報の生成に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _saveMemo() async {
    if (!_formKey.currentState!.validate()) return;

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

      // メモ内容を構築
      final situation = _situationController.text.trim();
      final thought = _thoughtController.text.trim();

      final content = situation.isNotEmpty
          ? '【状況・出来事】\n$situation\n\n【思考メモ】\n$thought'
          : thought;

      final now = DateTime.now();
      await _db.dailyMemosDao.createDailyMemo(
        DailyMemosCompanion(
          title: Value(_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null),
          content: Value(content),
          category: Value(_categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim()),
          tags: Value(tagsJson),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日常メモを保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSituationTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 状況・出来事フィールド
        TextFormField(
          controller: _situationController,
          decoration: const InputDecoration(
            labelText: '状況・出来事',
            hintText: 'その時の状況や起きた出来事を記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          minLines: 4,
        ),
        const SizedBox(height: 8),

        // 入力補助ボタン（状況用）
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('カメラ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickSourceImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('ギャラリー'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pasteFromClipboard(_situationController),
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('貼り付け'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 画像プレビュー
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
                      Text(
                        '撮影した画像',
                        style: theme.textTheme.titleSmall,
                      ),
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

        const SizedBox(height: 24),

        // 思考メモフィールド
        TextFormField(
          controller: _thoughtController,
          decoration: const InputDecoration(
            labelText: '思考メモ *',
            hintText: '状況に対する自分の考えや気づきを記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          minLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '思考メモを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        _buildMetadataFields(),
      ],
    );
  }

  Widget _buildThoughtTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 思考メモフィールドのみ
        TextFormField(
          controller: _thoughtController,
          decoration: const InputDecoration(
            labelText: '思考メモ *',
            hintText: '即時的・断片的な考えやアイデアを記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 15,
          minLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '思考メモを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),

        // 入力補助ボタン（思考メモ用）
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('カメラ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickSourceImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('ギャラリー'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pasteFromClipboard(_thoughtController),
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('貼り付け'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 画像プレビュー
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
                      Text(
                        '撮影した画像',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
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

        const SizedBox(height: 24),

        _buildMetadataFields(),
      ],
    );
  }

  Widget _buildMetadataFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'メタ情報（任意）',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isGeneratingMetadata ? null : _generateMetadata,
              icon: _isGeneratingMetadata
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: const Text('AI生成'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'タイトル',
            hintText: '例: 会議メモ、アイデア',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'カテゴリ',
            hintText: '例: 仕事、プライベート、学習',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'タグ',
            hintText: 'カンマ区切り: タグ1, タグ2, タグ3',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('日常メモ追加'),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemo,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '状況・出来事 + 思考'),
            Tab(text: '思考メモのみ'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSituationTab(),
            _buildThoughtTab(),
          ],
        ),
      ),
    );
  }
}
