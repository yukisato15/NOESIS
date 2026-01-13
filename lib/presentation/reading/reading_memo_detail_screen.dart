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
import '../../data/local/tables/reading_memo_entries_table.dart';

/// 読書メモ詳細画面
/// メモ内容の表示と、追記エントリーの時系列表示、AI機能（要約・リライト・質問応答）を提供
class ReadingMemoDetailScreen extends ConsumerStatefulWidget {
  final int memoId;
  final String bookTitle;

  const ReadingMemoDetailScreen({
    super.key,
    required this.memoId,
    required this.bookTitle,
  });

  @override
  ConsumerState<ReadingMemoDetailScreen> createState() =>
      _ReadingMemoDetailScreenState();
}

class _ReadingMemoDetailScreenState
    extends ConsumerState<ReadingMemoDetailScreen> {
  ReadingMemo? _memo;
  List<ReadingMemoEntry> _entries = [];
  bool _isLoading = true;
  bool _isProcessingAI = false;
  ThinkingStyle _selectedThinkingStyle = ThinkingStyle.socrates;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _loadMemoAndEntries();
  }

  Future<void> _loadMemoAndEntries() async {
    setState(() => _isLoading = true);
    try {
      final memo = await _db.readingMemosDao.getMemoById(widget.memoId);
      final entries =
          await _db.readingMemoEntriesDao.getEntriesByMemoId(widget.memoId);
      if (mounted) {
        setState(() {
          _memo = memo;
          _entries = entries;
          _isLoading = false;
        });
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

  Future<void> _summarize() async {
    if (_memo == null) return;

    setState(() {
      _isProcessingAI = true;
    });

    try {
      final prompt = '''
以下の読書メモを要約してください。
重要なポイントを3-5個の箇条書きで簡潔にまとめてください。

【メモ内容】
${_memo!.content ?? _memo!.thoughtText}
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
      await _db.readingMemoEntriesDao.insertEntry(
        ReadingMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: MemoEntryType.aiSummary,
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
以下の読書メモを、より分かりやすく読みやすい文章にリライトしてください。
内容の意味は変えずに、表現を整理して改善してください。

【元のメモ】
${_memo!.content ?? _memo!.thoughtText}
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
      await _db.readingMemoEntriesDao.insertEntry(
        ReadingMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: MemoEntryType.aiRewrite,
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
以下の読書メモについて質問に答えてください。

【メモ内容】
${_memo!.content ?? _memo!.thoughtText}

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
      await _db.readingMemoEntriesDao.insertEntry(
        ReadingMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: MemoEntryType.aiQA,
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
      await _db.readingMemoEntriesDao.insertEntry(
        ReadingMemoEntriesCompanion.insert(
          memoId: widget.memoId,
          entryType: MemoEntryType.manualNote,
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

  Future<void> _deleteEntry(ReadingMemoEntry entry) async {
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
      await _db.readingMemoEntriesDao.deleteEntry(entry.id);
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

  String _getEntryTypeLabel(MemoEntryType type) {
    switch (type) {
      case MemoEntryType.original:
        return '初回記録';
      case MemoEntryType.aiSummary:
        return 'AI要約';
      case MemoEntryType.aiRewrite:
        return 'AIリライト';
      case MemoEntryType.aiQA:
        return '質問応答';
      case MemoEntryType.manualNote:
        return '手動追記';
    }
  }

  IconData _getEntryTypeIcon(MemoEntryType type) {
    switch (type) {
      case MemoEntryType.original:
        return Icons.create;
      case MemoEntryType.aiSummary:
        return Icons.summarize;
      case MemoEntryType.aiRewrite:
        return Icons.edit_note;
      case MemoEntryType.aiQA:
        return Icons.question_answer;
      case MemoEntryType.manualNote:
        return Icons.note_add;
    }
  }

  Widget _buildEntryCard(ReadingMemoEntry entry, ThemeData theme) {
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
                  color: AppPalette.reading,
                ),
                const SizedBox(width: 8),
                Text(
                  _getEntryTypeLabel(entry.entryType),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppPalette.reading,
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
                      color: AppPalette.reading.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ThinkingStyle.values
                              .firstWhere(
                                (s) => s.name == entry.thinkingStyleName,
                                orElse: () => ThinkingStyle.socrates,
                              )
                              .displayName ??
                          entry.thinkingStyleName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.reading,
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
                color: theme.colorScheme.secondary.withOpacity(0.6),
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
        title: const Text('メモ詳細'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 書籍情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.book, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.bookTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // メタ情報
            if (_memo!.sectionTitle != null &&
                _memo!.sectionTitle!.isNotEmpty) ...{
              Row(
                children: [
                  const Icon(Icons.topic, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _memo!.sectionTitle!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppPalette.reading,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            },
            if (_memo!.pageNumber != null && _memo!.pageNumber!.isNotEmpty) ...{
              Row(
                children: [
                  const Icon(Icons.numbers, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ページ: ${_memo!.pageNumber}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            },

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_memo!.excerptText != null &&
                        _memo!.excerptText!.isNotEmpty) ...{
                      Text(
                        '本文抜粋',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppPalette.reading,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableContextText(
                        text: _memo!.excerptText!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        '思考メモ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppPalette.reading,
                        ),
                      ),
                      const SizedBox(height: 8),
                    },
                    SelectableContextText(
                      text: _memo!.content ?? _memo!.thoughtText,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '作成日時: ${_memo!.createdAt.year}/${_memo!.createdAt.month}/${_memo!.createdAt.day} ${_memo!.createdAt.hour}:${_memo!.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withOpacity(0.6),
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
                      color: AppPalette.reading.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_entries.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.reading,
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
