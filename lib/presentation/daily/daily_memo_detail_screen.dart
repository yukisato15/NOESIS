import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/tables/daily_memo_entries_table.dart';

/// 日常メモ詳細画面
/// メモ内容の表示と、追記エントリーの時系列表示、AI機能（要約・リライト・質問応答）を提供
class DailyMemoDetailScreen extends ConsumerStatefulWidget {
  final int memoId;

  const DailyMemoDetailScreen({super.key, required this.memoId});

  @override
  ConsumerState<DailyMemoDetailScreen> createState() =>
      _DailyMemoDetailScreenState();
}

class _DailyMemoDetailScreenState
    extends ConsumerState<DailyMemoDetailScreen> {
  DailyMemo? _memo;
  List<DailyMemoEntry> _entries = [];
  bool _isLoading = true;
  bool _isProcessingAI = false;
  bool _isGeneratingMetadata = false;
  bool _isEditing = false;
  ThinkingStyle _selectedThinkingStyle = ThinkingStyle.socrates;

  AppDatabase get _db => ref.read(databaseProvider);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemoAndEntries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoAndEntries() async {
    setState(() => _isLoading = true);
    try {
      final memo = await _db.dailyMemosDao.getDailyMemoById(widget.memoId);
      final entries =
          await _db.dailyMemoEntriesDao.getEntriesByMemoId(widget.memoId);
      if (mounted) {
        setState(() {
          _memo = memo;
          _entries = entries;
          _isLoading = false;
        });
        _syncControllersFromMemo();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _syncControllersFromMemo() {
    if (_memo == null) {
      return;
    }
    _titleController.text = _memo!.title ?? '';
    _categoryController.text = _memo!.category ?? '';
    _contentController.text = _memo!.content;
    if (_memo!.tags == null || _memo!.tags!.isEmpty) {
      _tagsController.text = '';
      return;
    }
    try {
      final decoded = jsonDecode(_memo!.tags!);
      if (decoded is List) {
        _tagsController.text = decoded.join(', ');
      } else {
        _tagsController.text = _memo!.tags!;
      }
    } catch (_) {
      _tagsController.text = _memo!.tags!;
    }
  }

  Future<void> _saveEdits() async {
    if (_memo == null) return;

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メモ本文を入力してください')),
      );
      return;
    }

    final tagsText = _tagsController.text.trim();
    String? tagsJson;
    if (tagsText.isNotEmpty) {
      final tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      tagsJson = tags.isEmpty ? null : jsonEncode(tags);
    }

    final updated = _memo!.copyWith(
      title: Value(_titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim()),
      category: Value(_categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim()),
      tags: Value(tagsJson),
      content: content,
      updatedAt: DateTime.now(),
    );

    try {
      await _db.dailyMemosDao.updateDailyMemo(updated);
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        await _loadMemoAndEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを更新しました')),
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

  void _cancelEdit() {
    _syncControllersFromMemo();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _summarize() async {
    if (_memo == null) return;

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
以下の日常メモを要約してください。
重要なポイントを3-5個の箇条書きで簡潔にまとめてください。

【メモ内容】
${_memo!.content}
''';

      final schema = {
        'type': 'object',
        'properties': {
          'summary': {'type': 'string', 'description': '全体の要約（1-2文）'},
          'key_points': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': '重要なポイント（3-5個の箇条書き）'
          }
        },
        'required': ['summary', 'key_points']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      final summary = result['summary'] as String;
      final keyPoints = (result['key_points'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();

      final formattedResult = '''
## 要約

$summary

## 重要なポイント

${keyPoints.map((p) => '• $p').join('\n')}
''';

      // エントリーとして保存
      await _db.dailyMemoEntriesDao.insertEntry(
        DailyMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: DailyMemoEntryType.aiSummary,
          content: formattedResult,
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );

      await _loadMemoAndEntries();

      if (mounted) {
        setState(() {
          _isProcessingAI = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('要約を追記しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('要約に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _rewrite() async {
    if (_memo == null) return;

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
以下の日常メモを、より分かりやすく読みやすい文章にリライトしてください。
内容の意味は変えずに、表現を整理して改善してください。

【元のメモ】
${_memo!.content}
''';

      final schema = {
        'type': 'object',
        'properties': {
          'rewritten': {'type': 'string', 'description': 'リライト後の文章'}
        },
        'required': ['rewritten']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      final rewritten = result['rewritten'] as String;

      // エントリーとして保存
      await _db.dailyMemoEntriesDao.insertEntry(
        DailyMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: DailyMemoEntryType.aiRewrite,
          content: rewritten,
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );

      await _loadMemoAndEntries();

      if (mounted) {
        setState(() {
          _isProcessingAI = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('リライトを追記しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リライトに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _askQuestion() async {
    if (_memo == null) return;

    final questionController = TextEditingController();

    final question = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('質問を入力'),
        content: TextField(
          controller: questionController,
          decoration: const InputDecoration(
            hintText: 'このメモについて質問してください',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, questionController.text),
            child: const Text('質問する'),
          ),
        ],
      ),
    );

    if (question == null || question.trim().isEmpty) return;

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
以下の日常メモについて質問に答えてください。

【メモ内容】
${_memo!.content}

【質問】
$question
''';

      final schema = {
        'type': 'object',
        'properties': {
          'answer': {'type': 'string', 'description': '質問への回答'}
        },
        'required': ['answer']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      final answer = result['answer'] as String;

      final formattedResult = '''
## 質問
$question

## 回答
$answer
''';

      // エントリーとして保存
      await _db.dailyMemoEntriesDao.insertEntry(
        DailyMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: DailyMemoEntryType.aiQA,
          content: formattedResult,
          question: Value(question),
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );

      await _loadMemoAndEntries();

      if (mounted) {
        setState(() {
          _isProcessingAI = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('質問応答を追記しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('質問応答に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _addManualNote() async {
    final noteController = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手動追記'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: '追加で気づいたことや考えを記録',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          minLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('追記'),
          ),
        ],
      ),
    );

    if (note == null || note.trim().isEmpty) return;

    try {
      await _db.dailyMemoEntriesDao.insertEntry(
        DailyMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: DailyMemoEntryType.manualNote,
          content: note.trim(),
        ),
      );

      await _loadMemoAndEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('追記を保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('追記の保存に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntry(DailyMemoEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このエントリーを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _db.dailyMemoEntriesDao.deleteEntry(entry.id);
      await _loadMemoAndEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エントリーを削除しました')),
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

  Future<void> _deleteMemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この日常メモを削除しますか？\n※追記履歴もすべて削除されます'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 追記履歴も削除
        await _db.dailyMemoEntriesDao.deleteAllEntriesByMemoId(widget.memoId);
        await _db.dailyMemosDao.deleteDailyMemo(widget.memoId);
        if (mounted) {
          Navigator.of(context).pop(true);
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

  Future<void> _generateMetadata() async {
    if (_memo == null) return;

    setState(() {
      _isGeneratingMetadata = true;
    });

    try {
      final prompt = '''
以下の日常メモから、適切なメタ情報を生成してください。

【メモ内容】
${_memo!.content}

以下の情報を生成してください：
1. タイトル: メモの内容を端的に表す短いタイトル（10文字以内）
2. カテゴリ: メモの分類（例: 仕事、学習、プライベート、アイデアなど）
''';

      final schema = {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'メモのタイトル（10文字以内）'},
          'category': {'type': 'string', 'description': 'メモのカテゴリ'},
        },
        'required': ['title', 'category']
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.standard,
      );

      final title = result['title'] as String;
      final category = result['category'] as String;

      // データベースを更新
      await _db.dailyMemosDao.updateDailyMemo(
        _memo!.copyWith(
          title: Value(title),
          category: Value(category),
        ),
      );

      await _loadMemoAndEntries();

      if (mounted) {
        setState(() {
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

  String _getEntryTypeLabel(DailyMemoEntryType type) {
    switch (type) {
      case DailyMemoEntryType.original:
        return '初回記録';
      case DailyMemoEntryType.aiSummary:
        return 'AI要約';
      case DailyMemoEntryType.aiRewrite:
        return 'AIリライト';
      case DailyMemoEntryType.aiQA:
        return '質問応答';
      case DailyMemoEntryType.manualNote:
        return '手動追記';
    }
  }

  IconData _getEntryTypeIcon(DailyMemoEntryType type) {
    switch (type) {
      case DailyMemoEntryType.original:
        return Icons.create;
      case DailyMemoEntryType.aiSummary:
        return Icons.summarize;
      case DailyMemoEntryType.aiRewrite:
        return Icons.edit_note;
      case DailyMemoEntryType.aiQA:
        return Icons.question_answer;
      case DailyMemoEntryType.manualNote:
        return Icons.note_add;
    }
  }

  Widget _buildEntryCard(DailyMemoEntry entry, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // エントリーヘッダー
            Row(
              children: [
                Icon(
                  _getEntryTypeIcon(entry.entryType),
                  size: 18,
                  color: AppPalette.daily,
                ),
                const SizedBox(width: 8),
                Text(
                  _getEntryTypeLabel(entry.entryType),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppPalette.daily,
                    fontWeight: FontWeight.bold,
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
                      color: AppPalette.daily.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ThinkingStyle.values
                          .firstWhere(
                            (s) => s.name == entry.thinkingStyleName,
                            orElse: () => ThinkingStyle.socrates,
                          )
                          .displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.daily,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteEntry(entry),
                  tooltip: '削除',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // エントリー内容
            SelectableContextText(
              text: entry.content,
              style: theme.textTheme.bodyMedium,
            ),

            // 作成日時
            const SizedBox(height: 8),
            Text(
              '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day} ${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('メモ詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_memo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('メモ詳細')),
        body: const Center(child: Text('メモが見つかりませんでした')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_memo!.title ?? '日常メモ'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEdits,
              tooltip: '保存',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'キャンセル',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _syncControllersFromMemo();
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMemo,
              tooltip: '削除',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // カテゴリータグとメタ情報生成ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.soften(AppPalette.daily, 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '日常メモ',
                    style: TextStyle(
                      color: AppPalette.daily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!_isEditing &&
                    (_memo?.title == null || _memo?.category == null))
                  OutlinedButton.icon(
                    onPressed: _isGeneratingMetadata ? null : _generateMetadata,
                    icon: _isGeneratingMetadata
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('メタ情報生成'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // メタ情報表示
            if (_isEditing) ...[
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'メタ情報（編集）',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'タグ（カンマ区切り）',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_memo!.title != null || _memo!.category != null) ...[
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'メタ情報',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEditing)
                            OutlinedButton.icon(
                              onPressed: _isGeneratingMetadata
                                  ? null
                                  : _generateMetadata,
                              icon: _isGeneratingMetadata
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 16),
                              label: const Text('再生成'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_memo!.title != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.title, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'タイトル: ${_memo!.title}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      if (_memo!.category != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.category, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'カテゴリ: ${_memo!.category}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 元のメモ本文
            Text(
              'メモ本文',
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
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: 'メモ本文',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 10,
                        minLines: 6,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 状況・出来事と思考メモを分けて表示
                          if (_memo!.content.contains('【状況・出来事】') &&
                              _memo!.content.contains('【思考メモ】')) ...[
                            // 状況・出来事部分
                            Text(
                              '状況・出来事',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppPalette.daily,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableContextText(
                              text: _memo!.content
                                  .split('【思考メモ】')[0]
                                  .replaceFirst('【状況・出来事】', '')
                                  .trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            // 思考メモ部分
                            Text(
                              '思考メモ',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppPalette.daily,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableContextText(
                              text:
                                  _memo!.content.split('【思考メモ】')[1].trim(),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ] else ...[
                            // 思考メモのみの場合
                            SelectableContextText(
                              text: _memo!.content,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '作成日時: ${_memo!.createdAt.year}/${_memo!.createdAt.month}/${_memo!.createdAt.day} ${_memo!.createdAt.hour}:${_memo!.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // 思考キャラクター選択
            Text(
              '思考キャラクター',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<ThinkingStyle>(
                        value: _selectedThinkingStyle,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ThinkingStyle.values
                            .map((style) => DropdownMenuItem(
                                  value: style,
                                  child: Text(
                                    '${style.displayName} - ${style.description}',
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (style) {
                          if (style != null) {
                            setState(() {
                              _selectedThinkingStyle = style;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI機能ボタン
            Text(
              'AI機能',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingAI ? null : _summarize,
                    icon: const Icon(Icons.summarize, size: 18),
                    label: const Text('要約'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingAI ? null : _rewrite,
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('リライト'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingAI ? null : _askQuestion,
                    icon: const Icon(Icons.question_answer, size: 18),
                    label: const Text('質問'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI処理中インジケータ
            if (_isProcessingAI)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('AIで処理中...'),
                      ],
                    ),
                  ),
                ),
              ),

            // 追記エントリー一覧
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    '追記履歴',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.daily.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_entries.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.daily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _entries.length,
                (index) => _buildEntryCard(_entries[index], theme),
              ),
            ],

            // 手動追記ボタン
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addManualNote,
                icon: const Icon(Icons.add),
                label: const Text('追記を追加'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
