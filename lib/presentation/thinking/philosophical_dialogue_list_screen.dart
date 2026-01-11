import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/concept_dictionaries_table.dart';
import '../../data/local/tables/philosophical_messages_table.dart';
import 'concept_dictionary_add_screen.dart';
import 'philosophical_dialogue_detail_screen.dart';

class PhilosophicalDialogueListScreen extends ConsumerStatefulWidget {
  const PhilosophicalDialogueListScreen({super.key});

  @override
  ConsumerState<PhilosophicalDialogueListScreen> createState() =>
      _PhilosophicalDialogueListScreenState();
}

class _PhilosophicalDialogueListScreenState
    extends ConsumerState<PhilosophicalDialogueListScreen> {
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  Future<List<PhilosophicalDialogue>> _loadDialogues() async {
    final dialogues = await _db.philosophicalDialoguesDao.getAllDialogues();
    final rows = await (_db.selectOnly(_db.philosophicalMessages)
          ..addColumns([_db.philosophicalMessages.dialogueId])
          ..groupBy([_db.philosophicalMessages.dialogueId]))
        .get();
    final idsWithMessages = rows
        .map((row) => row.read(_db.philosophicalMessages.dialogueId))
        .whereType<int>()
        .toSet();
    return dialogues.where((d) => idsWithMessages.contains(d.id)).toList();
  }

  Future<void> _deleteDialogue(int dialogueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('対話を削除しますか？'),
          content: const Text('この対話とメッセージ履歴を削除します。'),
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
      _db.philosophicalMessages,
    )..where((t) => t.dialogueId.equals(dialogueId))).go();
    await _db.philosophicalDialoguesDao.deleteDialogue(dialogueId);

    if (mounted) {
      setState(() {});
    }
  }

  String _formatMessageForAI(PhilosophicalMessage message) {
    final persona = (message.persona ?? '').trim();
    final personaPrefix = persona.isEmpty ? '' : '($persona) ';
    switch (message.inputType) {
      case DialogueInputType.image:
        final base = message.content.trim().isEmpty
            ? '画像が共有されました。'
            : message.content.trim();
        return '$personaPrefix[画像] $base';
      case DialogueInputType.voice:
        return '$personaPrefix[音声] ${message.content.trim()}';
      case DialogueInputType.text:
        return '$personaPrefix${message.content.trim()}';
    }
  }

  Future<void> _showSummaryDialog(PhilosophicalDialogue dialogue) async {
    final summary = dialogue.summary?.trim() ?? '';
    if (summary.isEmpty) {
      return;
    }
    final shouldRegister = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('会話の要約'),
          content: SingleChildScrollView(
            child: Text(summary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('閉じる'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('概念辞書に登録'),
            ),
          ],
        );
      },
    );

    if (shouldRegister == true) {
      await _startConceptRegistration(dialogue, summary);
    }
  }

  Future<void> _startConceptRegistration(
    PhilosophicalDialogue dialogue,
    String summary,
  ) async {
    try {
      final messages =
          await _db.philosophicalDialoguesDao.getMessagesByDialogue(
        dialogue.id,
      );
      final conversation = messages
          .map(
            (msg) =>
                '[${msg.role == DialogueRole.user ? 'ユーザー' : 'AI'}] ${_formatMessageForAI(msg)}',
          )
          .join('\n');
      final existingConcepts =
          await _db.select(_db.conceptDictionaries).get();
      final existingTitles = existingConcepts
          .map((c) => c.title.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final prompt = '''
以下は哲学的対話の要約とログです。この内容から概念辞書のエントリ名候補を1つ出してください。
既存の概念が近い場合は、そのタイトルを優先してください。

# 既存の概念タイトル一覧
${existingTitles.isEmpty ? 'なし' : existingTitles.join(' / ')}

# 要約
$summary

# 対話ログ
$conversation

出力はJSON形式で、以下のキーを必ず含めてください。
- concept_title: 概念辞書のエントリ名候補
''';

      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: {
          'type': 'object',
          'properties': {
            'concept_title': {'type': 'string'},
          },
          'required': ['concept_title'],
        },
        mode: AIMode.standard,
      );

      final suggestedTitle = (json['concept_title'] ?? '').toString().trim();
      if (suggestedTitle.isEmpty || !mounted) {
        return;
      }

      final controller = TextEditingController(text: suggestedTitle);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('概念名の候補'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '概念名'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      final finalTitle = controller.text.trim();
      controller.dispose();
      if (confirmed != true || finalTitle.isEmpty || !mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConceptDictionaryAddScreen(
            initialTitle: finalTitle,
            initialContext: [
              '要約',
              summary,
              '',
              '対話ログ',
              conversation,
            ].join('\n'),
            origin: ConceptOrigin.dialogue,
            autoGenerateOnLoad: true,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('概念名の取得に失敗しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('対話一覧')),
      body: FutureBuilder<List<PhilosophicalDialogue>>(
        future: _loadDialogues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('読み込みに失敗しました'));
          }

          final dialogues = snapshot.data ?? [];

          if (dialogues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text('対話がありません', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: dialogues.length,
            itemBuilder: (context, index) {
              final dialogue = dialogues[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppPalette.soften(
                      AppPalette.thinking,
                      0.2,
                    ),
                    child: Icon(Icons.forum, color: AppPalette.thinking),
                  ),
                  title: Text(
                    dialogue.title.trim().isEmpty ? '無題の対話' : dialogue.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogue.summary != null &&
                          dialogue.summary!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dialogue.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '最終更新 ${_formatDate(dialogue.updatedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogue.summary != null &&
                          dialogue.summary!.trim().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: '要約済み',
                          onPressed: () => _showSummaryDialog(dialogue),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteDialogue(dialogue.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'delete', child: Text('削除')),
                        ],
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PhilosophicalDialogueDetailScreen(
                          dialogueId: dialogue.id,
                        ),
                      ),
                    );
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
