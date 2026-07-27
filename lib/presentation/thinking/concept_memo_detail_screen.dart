import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import 'package:dart_openai/dart_openai.dart';
import '../../data/local/database.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import 'widgets/thinking_style_selector.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts/thinking_prompts.dart';
import 'package:intl/intl.dart';

class ConceptMemoDetailScreen extends StatefulWidget {
  final int memoId;

  const ConceptMemoDetailScreen({super.key, required this.memoId});

  @override
  State<ConceptMemoDetailScreen> createState() =>
      _ConceptMemoDetailScreenState();
}

class _ConceptMemoDetailScreenState extends State<ConceptMemoDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;
  ConceptMemo? _memo;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isGeneratingSummary = false;

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadMemo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadMemo() async {
    setState(() {
      _isLoading = true;
    });

    final memo = await _db.conceptMemosDao.getConceptMemoById(widget.memoId);
    if (memo != null) {
      setState(() {
        _memo = memo;
        _titleController.text = memo.title ?? '';
        _contentController.text = memo.content;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    final updatedMemo = _memo!.copyWith(
      title: drift.Value(_titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null),
      content: _contentController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await _db.conceptMemosDao.updateConceptMemo(updatedMemo);

    setState(() {
      _memo = updatedMemo;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
    }
  }

  Future<void> _deleteMemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この概念メモを削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.conceptMemosDao.deleteConceptMemo(widget.memoId);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _generateSummaryWithAI() async {
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final prompt = ThinkingPrompts.summarizeConceptMemo(_memo!.content);
      final summary = await _aiClient.chat(messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)],
        ),
      ]);

      final updatedMemo = _memo!.copyWith(
        summary: drift.Value(summary),
        updatedAt: DateTime.now(),
      );

      await _db.conceptMemosDao.updateConceptMemo(updatedMemo);

      setState(() {
        _memo = updatedMemo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('要約を生成しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('処理に失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isGeneratingSummary = false;
      });
    }
  }

  Future<void> _showThinkingStyleDialog() async {
    final style = await showThinkingStyleSelector(
      context,
      current: ThinkingStyle.socrates,
    );

    if (style != null) {
      _showThinkingDialog(style);
    }
  }

  Future<void> _showThinkingDialog(ThinkingStyle style) async {
    // TODO: AI対話機能の実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${style.displayName}との対話'),
        content: const Text('AI対話機能は次のステップで実装予定'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_memo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: const Center(child: Text('概念メモが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編集' : (_memo!.title ?? '概念メモ')),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMemo,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemo,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _titleController.text = _memo!.title ?? '';
                  _contentController.text = _memo!.content;
                  _isEditing = false;
                });
              },
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
      floatingActionButton: !_isEditing
          ? FloatingActionButton.extended(
              onPressed: _showThinkingStyleDialog,
              backgroundColor: AppPalette.thinking,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.psychology),
              label: const Text(
                'AI思考',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
    );
  }

  Widget _buildViewMode() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.thinking, 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '概念メモ',
                  style: TextStyle(
                    color: AppPalette.thinking,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '更新: ${dateFormat.format(_memo!.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_memo!.title != null) ...[
            SelectableContextText(
              text: _memo!.title!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
          ],
          if (_memo!.summary != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.thinking, 0.9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppPalette.thinking.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppPalette.thinking),
                      const SizedBox(width: 8),
                      Text(
                        'AI要約',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppPalette.thinking,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableContextText(
                    text: _memo!.summary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SelectableContextText(
            text: _memo!.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (_memo!.summary == null)
            ElevatedButton.icon(
              onPressed: _isGeneratingSummary ? null : _generateSummaryWithAI,
              icon: _isGeneratingSummary
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isGeneratingSummary ? '生成中...' : 'AI要約を生成',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.thinking,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル（任意）',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '内容',
              hintText: '思考や概念を自由に記述',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 20,
          ),
        ],
      ),
    );
  }
}
