import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_client.dart';

import '../../core/ai/coding_teacher_type.dart';
import '../../core/ai/learning_level.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/tables/code_entries_table.dart';
import '../../data/local/tables/code_entry_entries_table.dart';

/// コードエントリー詳細画面
class CodeEntryDetailScreen extends ConsumerStatefulWidget {
  final int entryId;

  const CodeEntryDetailScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<CodeEntryDetailScreen> createState() =>
      _CodeEntryDetailScreenState();
}

class _CodeEntryDetailScreenState
    extends ConsumerState<CodeEntryDetailScreen> {
  CodeEntry? _entry;
  List<CodeEntryEntry> _entries = [];
  bool _isLoading = true;
  bool _isProcessingAI = false;
  bool _isEditing = false;
  CodingTeacherType _selectedTeacher = CodingTeacherType.professional;
  LearningLevel _learningLevel = LearningLevel.beginner;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _loadEntryAndHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _syncControllersFromEntry() {
    if (_entry == null) {
      return;
    }
    _titleController.text = _entry!.title;
    _codeController.text = _entry!.code;
    _categoryController.text = _entry!.category ?? '';
    _tagsController.text = _decodeTags(_entry!.tags).join(', ');
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _parseTags(String input) {
    final normalized = input.replaceAll('、', ',');
    return normalized
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _enterEditMode() {
    _syncControllersFromEntry();
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    _syncControllersFromEntry();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveEdits() async {
    if (_entry == null) {
      return;
    }
    final title = _titleController.text.trim();
    final code = _codeController.text.trim();
    if (title.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルとコードを入力してください')),
      );
      return;
    }
    final category = _categoryController.text.trim();
    final tags = _parseTags(_tagsController.text);
    try {
      await _db.codeEntriesDao.updateCodeEntryCompanion(
        widget.entryId,
        CodeEntriesCompanion(
          title: Value(title),
          code: Value(code),
          category: Value(category.isEmpty ? null : category),
          tags: Value(tags.isEmpty ? null : jsonEncode(tags)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _loadEntryAndHistory();
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('編集内容を保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _loadEntryAndHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entry =
          await _db.codeEntriesDao.getCodeEntryById(widget.entryId);
      final entries =
          await _db.codeEntryEntriesDao.getEntriesByCodeEntryId(widget.entryId);

      setState(() {
        _entry = entry;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _addAIExplanation() async {
    if (_entry == null) return;

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
あなたは${_selectedTeacher.displayName}です。
以下のコードについて、${_learningLevel.displayName}向けに詳しく解説してください。

【コード】
${_entry!.code}

【言語】
${_entry!.language ?? '不明'}

【あなたの役割】
${_selectedTeacher.systemPrompt}

【学習者のレベル】
${_learningLevel.description}
${_learningLevel.guidanceNote}

コードの動作、重要なポイント、学習すべき概念を、
${_learningLevel.displayName}が理解できるように丁寧に説明してください。
''';

      final explanation = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      await _db.codeEntryEntriesDao.insertEntry(
        CodeEntryEntriesCompanion.insert(
          codeEntryId: widget.entryId,
          entryType: CodeEntryEntryType.aiExplanation,
          content: explanation,
          thinkingStyleName: Value(_selectedTeacher.name),
        ),
      );

      await _loadEntryAndHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI解説を追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI解説の生成に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  /// コードの範囲選択部分について質問する
  Future<void> _askAboutCodeSection(String selectedCode) async {
    final questionController = TextEditingController();

    final question = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コードについて質問'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('選択されたコード:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedCode,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '質問を入力',
                hintText: 'このコードについて質問したいことを入力してください',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(questionController.text),
            child: const Text('質問'),
          ),
        ],
      ),
    );

    if (question != null && question.isNotEmpty) {
      setState(() {
        _isProcessingAI = true;
      });

      try {
        final prompt = '''
あなたは${_selectedTeacher.displayName}です。
以下のコードの一部について、${_learningLevel.displayName}向けに質問に答えてください。

【全体のコード】
${_entry!.code}

【質問対象の部分】
$selectedCode

【質問】
$question

【あなたの役割】
${_selectedTeacher.systemPrompt}

【学習者のレベル】
${_learningLevel.description}

${_learningLevel.displayName}が理解できるように、丁寧に答えてください。
''';

        final answer = await AIClient.instance.chat(
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.user,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              ],
            ),
          ],
        );

        // 質問と回答をエントリーとして追加
        await _db.codeEntryEntriesDao.insertEntry(
          CodeEntryEntriesCompanion.insert(
            codeEntryId: widget.entryId,
            entryType: CodeEntryEntryType.aiQA,
            content: '【質問対象コード】\n$selectedCode\n\n【質問】\n$question\n\n【回答】\n$answer',
            thinkingStyleName: Value(_selectedTeacher.name),
          ),
        );

        await _loadEntryAndHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('回答を追加しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('質問の処理に失敗しました: $e')),
          );
        }
      } finally {
        setState(() {
          _isProcessingAI = false;
        });
      }
    }
  }

  Future<void> _addUserNote() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを追加'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'メモを入力',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _db.codeEntryEntriesDao.insertEntry(
          CodeEntryEntriesCompanion.insert(
            codeEntryId: widget.entryId,
            entryType: CodeEntryEntryType.userNote,
            content: result,
          ),
        );

        await _loadEntryAndHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メモを追加しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メモの追加に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteEntry(int entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このエントリを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.codeEntryEntriesDao.deleteEntry(entryId);
        await _loadEntryAndHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('エントリを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  /// タイトル編集
  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _entry!.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タイトル編集'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'タイトル',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != _entry!.title) {
      try {
        await _db.codeEntriesDao.updateCodeEntryCompanion(
          widget.entryId,
          CodeEntriesCompanion(
            title: Value(newTitle),
          ),
        );

        await _loadEntryAndHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('タイトルを更新しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新に失敗しました: $e')),
          );
        }
      }
    }

    controller.dispose();
  }

  String _getEntryTypeLabel(CodeEntryEntryType type) {
    switch (type) {
      case CodeEntryEntryType.original:
        return '初回記録';
      case CodeEntryEntryType.aiExplanation:
        return 'AI解説';
      case CodeEntryEntryType.userNote:
        return 'ユーザーメモ';
      case CodeEntryEntryType.aiRewrite:
        return 'AIリライト';
      case CodeEntryEntryType.aiQA:
        return 'AI質問応答';
    }
  }

  String _getCodeEntryTypeLabel(CodeEntryType type) {
    switch (type) {
      case CodeEntryType.whole:
        return 'コード全体';
      case CodeEntryType.function:
        return '関数単位';
      case CodeEntryType.block:
        return 'ブロック単位';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('コード詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('コード詳細')),
        body: const Center(child: Text('コードエントリーが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry!.title),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: '保存',
              onPressed: _saveEdits,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'キャンセル',
              onPressed: _cancelEdit,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '編集',
              onPressed: _enterEditMode,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '削除',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('削除確認'),
                    content: const Text('このコードエントリーを削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await _db.codeEntryEntriesDao
                        .deleteAllEntriesByCodeEntryId(widget.entryId);
                    await _db.codeEntriesDao.deleteCodeEntry(widget.entryId);

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('削除に失敗しました: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリータグ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.code, 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ITコード - ${_getCodeEntryTypeLabel(_entry!.entryType)}',
                style: TextStyle(
                  color: AppPalette.code,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'タイトル',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ',
                          hintText: '任意',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'タグ',
                          hintText: 'カンマ区切り',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if ((_entry!.category ?? '').isNotEmpty ||
                _decodeTags(_entry!.tags).isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((_entry!.category ?? '').isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.folder, size: 16),
                            const SizedBox(width: 6),
                            Text(_entry!.category!),
                          ],
                        ),
                      if (_decodeTags(_entry!.tags).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _decodeTags(_entry!.tags)
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // AI解析結果
            if (_entry!.language != null ||
                _entry!.structure != null ||
                _entry!.capabilities != null) ...[
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI解析結果',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_entry!.language != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.code, size: 16),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.code.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _entry!.language!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppPalette.code,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_entry!.libraries != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.folder_special, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final lib in jsonDecode(_entry!.libraries!))
                                    Chip(
                                      label: Text(lib),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_entry!.structure != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '構造',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _entry!.structure!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (_entry!.capabilities != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '機能',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _entry!.capabilities!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (_entry!.useCases != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '用途',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _entry!.useCases!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (_entry!.learningPoints != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '学習ポイント',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _entry!.learningPoints!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 元のコード
            Text(
              'コード',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _isEditing
                    ? TextField(
                        controller: _codeController,
                        maxLines: null,
                        minLines: 8,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'コード',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      )
                    : SelectableContextText(
                        text: _entry!.code,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                        onAskAboutCode: (selectedCode) async {
                          await _askAboutCodeSection(selectedCode);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // AI解析結果（拡張項目）
            if (_entry!.cautions != null || _entry!.tips != null || _entry!.commonMistakes != null) ...[
              _buildSectionTitle(theme, '学習サポート情報'),
              const SizedBox(height: 12),

              if (_entry!.cautions != null) _buildInfoCard(theme, '⚠️ 使用上の注意', _entry!.cautions!, Colors.orange),
              if (_entry!.tips != null) _buildInfoCard(theme, '💡 ワンポイントアドバイス', _entry!.tips!, Colors.blue),
              if (_entry!.commonMistakes != null) _buildInfoCard(theme, '❌ よくある誤用・間違い', _entry!.commonMistakes!, Colors.red),
              if (_entry!.trivia != null) _buildInfoCard(theme, '🎯 面白エピソード・トリビア', _entry!.trivia!, Colors.purple),

              const SizedBox(height: 16),
            ],

            // わかりやすい説明
            if (_entry!.gyaruExplanation != null || _entry!.kindergartenExplanation != null) ...[
              _buildSectionTitle(theme, 'わかりやすい説明'),
              const SizedBox(height: 12),

              if (_entry!.gyaruExplanation != null) _buildInfoCard(theme, '💅 ギャル先生の説明', _entry!.gyaruExplanation!, Colors.pink),
              if (_entry!.kindergartenExplanation != null) _buildInfoCard(theme, '👶 幼稚園児向け説明', _entry!.kindergartenExplanation!, Colors.green),

              const SizedBox(height: 16),
            ],

            // 関連コード
            if (_entry!.synonymousCodes != null || _entry!.antonymousCodes != null || _entry!.relatedCodes != null || _entry!.examples != null) ...[
              _buildSectionTitle(theme, '関連コード'),
              const SizedBox(height: 12),

              if (_entry!.synonymousCodes != null) _buildCodeListCard(theme, '🔄 類義のコード', _entry!.synonymousCodes!),
              if (_entry!.antonymousCodes != null) _buildCodeListCard(theme, '⚡ 対義のコード', _entry!.antonymousCodes!),
              if (_entry!.relatedCodes != null) _buildCodeListCard(theme, '🔗 関連するコード', _entry!.relatedCodes!),
              if (_entry!.examples != null) _buildCodeListCard(theme, '📝 具体例', _entry!.examples!),

              const SizedBox(height: 16),
            ],

            Text(
              '作成日時: ${_entry!.createdAt.year}/${_entry!.createdAt.month}/${_entry!.createdAt.day} ${_entry!.createdAt.hour}:${_entry!.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),

            // AI機能ボタン
            Card(
              color: AppPalette.soften(AppPalette.code, 0.9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI先生に質問',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPalette.code,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CodingTeacherType>(
                      value: _selectedTeacher,
                      decoration: const InputDecoration(
                        labelText: '先生のタイプ',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: CodingTeacherType.values.map((teacher) {
                        return DropdownMenuItem(
                          value: teacher,
                          child: Text(
                            '${teacher.displayName} - ${teacher.description}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (teacher) {
                        if (teacher != null) {
                          setState(() {
                            _selectedTeacher = teacher;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<LearningLevel>(
                      value: _learningLevel,
                      decoration: const InputDecoration(
                        labelText: 'あなたのレベル',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: LearningLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(
                            '${level.displayName} - ${level.description}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (level) {
                        if (level != null) {
                          setState(() {
                            _learningLevel = level;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessingAI ? null : _addAIExplanation,
                        icon: _isProcessingAI
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.psychology),
                        label: const Text('先生に質問して解説を追加'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.code,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessingAI ? null : _generateQuiz,
                            icon: const Icon(Icons.quiz),
                            label: const Text('クイズ'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.code,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isProcessingAI ? null : _generateSummary,
                            icon: const Icon(Icons.summarize),
                            label: const Text('要点'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.code,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addUserNote,
                        icon: const Icon(Icons.note_add),
                        label: const Text('メモを追加'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 追記履歴
            if (_entries.length > 1) ...[
              Text(
                '追記履歴',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in _entries.skip(1))
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.code.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getEntryTypeLabel(entry.entryType),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppPalette.code,
                                ),
                              ),
                            ),
                            if (entry.thinkingStyleName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.code.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  CodingTeacherType.values
                                      .firstWhere(
                                        (s) => s.name == entry.thinkingStyleName,
                                        orElse: () => CodingTeacherType.professional,
                                      )
                                      .displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppPalette.code,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteEntry(entry.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableContextText(
                          text: entry.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startFreeConversation,
        icon: const Icon(Icons.chat),
        label: const Text('先生に相談'),
        backgroundColor: AppPalette.code,
      ),
    );
  }

  /// クイズを生成
  Future<void> _generateQuiz() async {
    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
あなたは${_selectedTeacher.displayName}です。
以下のコードについて、${_learningLevel.displayName}向けの理解度確認クイズを3問作成してください。

【コード】
${_entry!.code}

${_selectedTeacher.systemPrompt}

以下の形式でクイズを作成してください：

【問題1】
（問題文）
A. 選択肢1
B. 選択肢2
C. 選択肢3
D. 選択肢4
正解: （A～D）
解説: （なぜその答えが正しいのか）

【問題2】
...

【問題3】
...

${_learningLevel.displayName}のレベルに合わせた難易度で作成してください。
''';

      final quiz = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      await _db.codeEntryEntriesDao.insertEntry(
        CodeEntryEntriesCompanion.insert(
          codeEntryId: widget.entryId,
          entryType: CodeEntryEntryType.userNote,
          content: '【理解度確認クイズ】\n\n$quiz',
          thinkingStyleName: Value(_selectedTeacher.name),
        ),
      );

      await _loadEntryAndHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クイズを生成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('クイズ生成に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  /// 要点まとめを生成
  Future<void> _generateSummary() async {
    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
あなたは${_selectedTeacher.displayName}です。
以下のコードについて、${_learningLevel.displayName}向けに要点をまとめてください。

【コード】
${_entry!.code}

${_selectedTeacher.systemPrompt}

以下の項目を含めて簡潔にまとめてください：

1. このコードの目的
2. 重要な概念・テクニック
3. 覚えておくべきポイント
4. よくある間違い
5. 次に学ぶべきこと

${_learningLevel.displayName}が復習しやすいように、わかりやすくまとめてください。
''';

      final summary = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      await _db.codeEntryEntriesDao.insertEntry(
        CodeEntryEntriesCompanion.insert(
          codeEntryId: widget.entryId,
          entryType: CodeEntryEntryType.userNote,
          content: '【要点まとめ】\n\n$summary',
          thinkingStyleName: Value(_selectedTeacher.name),
        ),
      );

      await _loadEntryAndHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('要点をまとめました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('要点まとめに失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessingAI = false;
      });
    }
  }

  /// 先生AIとの自由対話を開始
  Future<void> _startFreeConversation() async {
    final conversationController = TextEditingController();
    final List<Map<String, String>> chatHistory = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.school, color: AppPalette.code),
              const SizedBox(width: 8),
              Text('${_selectedTeacher.displayName}と対話'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // チャット履歴
                Expanded(
                  child: ListView.builder(
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = chatHistory[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? AppPalette.code.withValues(alpha: 0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUser ? 'あなた' : _selectedTeacher.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isUser ? AppPalette.code : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(message['content']!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // 入力フィールド
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: conversationController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'コードについて質問や相談をどうぞ...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              final userMessage = conversationController.text.trim();
                              if (userMessage.isEmpty) return;

                              setState(() {
                                chatHistory.add({'role': 'user', 'content': userMessage});
                                conversationController.clear();
                              });

                              try {
                                final messages = [
                                  OpenAIChatCompletionChoiceMessageModel(
                                    role: OpenAIChatMessageRole.system,
                                    content: [
                                      OpenAIChatCompletionChoiceMessageContentItemModel.text(
                                        '${_selectedTeacher.systemPrompt}\n\n対象のコード:\n${_entry!.code}\n\n学習者のレベル: ${_learningLevel.displayName}',
                                      ),
                                    ],
                                  ),
                                  ...chatHistory.map((msg) {
                                    return OpenAIChatCompletionChoiceMessageModel(
                                      role: msg['role'] == 'user'
                                          ? OpenAIChatMessageRole.user
                                          : OpenAIChatMessageRole.assistant,
                                      content: [
                                        OpenAIChatCompletionChoiceMessageContentItemModel.text(msg['content']!),
                                      ],
                                    );
                                  }).toList(),
                                ];

                                final response = await AIClient.instance.chat(messages: messages);

                                setState(() {
                                  chatHistory.add({'role': 'assistant', 'content': response});
                                });
                              } catch (e) {
                                setState(() {
                                  chatHistory.add({
                                    'role': 'assistant',
                                    'content': 'エラーが発生しました: $e'
                                  });
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            if (chatHistory.isNotEmpty)
              TextButton(
                onPressed: () async {
                  // 対話履歴を保存
                  final conversationText = chatHistory
                      .map((msg) => '【${msg['role'] == 'user' ? 'あなた' : _selectedTeacher.displayName}】\n${msg['content']}')
                      .join('\n\n');

                  await _db.codeEntryEntriesDao.insertEntry(
                    CodeEntryEntriesCompanion.insert(
                      codeEntryId: widget.entryId,
                      entryType: CodeEntryEntryType.userNote,
                      content: '【先生との対話記録】\n\n$conversationText',
                      thinkingStyleName: Value(_selectedTeacher.name),
                    ),
                  );

                  await _loadEntryAndHistory();

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('対話を保存しました')),
                    );
                  }
                },
                child: const Text('対話を保存'),
              ),
          ],
        ),
      ),
    );
  }

  /// セクションタイトルを構築
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppPalette.code,
      ),
    );
  }

  /// 情報カードを構築
  Widget _buildInfoCard(ThemeData theme, String title, String content, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// コードリストカードを構築
  Widget _buildCodeListCard(ThemeData theme, String title, String jsonArrayString) {
    try {
      final List<dynamic> codeList = jsonDecode(jsonArrayString);
      if (codeList.isEmpty) return const SizedBox.shrink();

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppPalette.code,
                ),
              ),
              const SizedBox(height: 12),
              ...codeList.asMap().entries.map((entry) {
                final index = entry.key;
                final code = entry.value.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          code,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
