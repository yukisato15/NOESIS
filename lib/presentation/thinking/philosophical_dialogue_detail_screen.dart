import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import 'widgets/thinking_style_selector.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/philosophical_messages_table.dart';
import '../shared/text_action_sheet.dart';

class PhilosophicalDialogueDetailScreen extends StatefulWidget {
  final int dialogueId;
  final String? initialMessage;
  final bool isDraft;

  const PhilosophicalDialogueDetailScreen({
    super.key,
    required this.dialogueId,
    this.initialMessage,
    this.isDraft = false,
  });

  @override
  State<PhilosophicalDialogueDetailScreen> createState() =>
      _PhilosophicalDialogueDetailScreenState();
}

class _PhilosophicalDialogueDetailScreenState
    extends State<PhilosophicalDialogueDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isComposerExpanded = false;
  final Random _rng = Random();
  String _mentionQuery = '';
  bool _showMentions = false;
  bool _showCriticalReflection = false;
  bool _isSummaryExpanded = false;

  PhilosophicalDialogue? _dialogue;
  List<PhilosophicalMessage> _messages = [];
  DialogueInputType _inputType = DialogueInputType.text;
  List<ThinkingStyle> _participants = [ThinkingStyle.socrates];
  bool _isSending = false;
  String? _selectedImagePath;
  bool _isEditing = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // AIモード選択
  AIMode _selectedMode = AIMode.standard;

  @override
  void initState() {
    super.initState();
    _loadDialogue();
    _messageFocusNode.addListener(_syncComposerState);
    _messageController.addListener(_syncComposerState);
    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      _messageController.text = widget.initialMessage!.trim();
      _isComposerExpanded = true;
    }
  }


  @override
  void dispose() {
    _cleanupEmptyDialogue();
    _db.close();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _syncControllersFromDialogue() {
    if (_dialogue == null) {
      return;
    }
    _titleController.text = _dialogue!.title;
    _summaryController.text = _dialogue!.summary ?? '';
    _categoryController.text = _dialogue!.category ?? '';
    _tagsController.text = _decodeTags(_dialogue!.tags).join(', ');
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
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
    _syncControllersFromDialogue();
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    _syncControllersFromDialogue();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveEdits() async {
    if (_dialogue == null) {
      return;
    }
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final category = _categoryController.text.trim();
    final tags = _parseTags(_tagsController.text);
    final updated = _dialogue!.copyWith(
      title: title.isEmpty ? '無題の対話' : title,
      summary: Value(summary.isEmpty ? null : summary),
      category: Value(category.isEmpty ? null : category),
      tags: Value(tags.isEmpty ? null : jsonEncode(tags)),
      updatedAt: DateTime.now(),
    );
    try {
      await _db.philosophicalDialoguesDao.updateDialogue(updated);
      if (mounted) {
        setState(() {
          _dialogue = updated;
          _isEditing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('編集内容を保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    }
  }

  void _cleanupEmptyDialogue() {
    Future.microtask(() async {
      final cleanupDb = AppDatabase();
      try {
        final countRow =
            await (cleanupDb.selectOnly(cleanupDb.philosophicalMessages)
                  ..addColumns([cleanupDb.philosophicalMessages.id.count()])
                  ..where(
                    cleanupDb.philosophicalMessages.dialogueId.equals(
                      widget.dialogueId,
                    ),
                  ))
                .getSingle();
        final messageCount =
            countRow.read(cleanupDb.philosophicalMessages.id.count()) ?? 0;
        if (messageCount == 0) {
          await cleanupDb.philosophicalDialoguesDao.deleteDialogue(
            widget.dialogueId,
          );
        }
      } finally {
        await cleanupDb.close();
      }
    });
  }

  Future<void> _loadDialogue() async {
    final dialogue = await (_db.select(
      _db.philosophicalDialogues,
    )..where((t) => t.id.equals(widget.dialogueId))).getSingle();
    final messages = await _db.philosophicalDialoguesDao.getMessagesByDialogue(
      widget.dialogueId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _dialogue = dialogue;
      _messages = messages;
    });
  }

  String _formatTime(DateTime time) {
    return DateFormat('MM/dd HH:mm').format(time);
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

  List<OpenAIChatCompletionChoiceMessageModel> _buildChatMessages(
    List<PhilosophicalMessage> messages,
  ) {
    final participants = _participants.isEmpty
        ? [ThinkingStyle.socrates]
        : _participants;
    final participantsGuide = participants
        .map(
          (style) =>
              '- ${style.displayName}: ${style.personaProfile.replaceAll('\n', ' ')}',
        )
        .join('\n');

    final chatMessages = <OpenAIChatCompletionChoiceMessageModel>[
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text('''
あなたは哲学対話の参加者として話します。以下の参加者の人格・口調を守ってください。
一人称、話し方、語尾、話題の切り口を厳密に反映してください。
自分の名前を三人称で名乗らないでください。

$participantsGuide
'''),
        ],
      ),
    ];

    for (final message in messages) {
      final content = _formatMessageForAI(message);
      if (content.isEmpty) {
        continue;
      }
      chatMessages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: message.role == DialogueRole.user
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(content),
          ],
        ),
      );
    }

    return chatMessages;
  }

  bool _isCriticalOnlyStyle(ThinkingStyle style) {
    return style.persona.safetyPolicy.mode == ThinkingSafetyMode.criticalOnly;
  }

  bool _containsHarmfulRhetoric(String text) {
    final patterns = <RegExp>[
      RegExp(r'殲滅|排除|粛清|劣等|浄化|民族浄化'),
      RegExp(r'憎め|叩け|追い出せ|攻撃せよ|制圧せよ'),
      RegExp(r'人間以下|害悪な集団|存在価値がない'),
    ];
    return patterns.any((p) => p.hasMatch(text));
  }

  String _guardCriticalStyleOutput(ThinkingStyle style, String rawText) {
    final text = rawText.trim();
    if (!_isCriticalOnlyStyle(style) || text.isEmpty) {
      return rawText;
    }
    final hasTemplate =
        text.contains('【自己否定と歴史的反省】') && text.contains('【批判的再構成】');
    if (hasTemplate) {
      return text;
    }
    final harmful = _containsHarmfulRhetoric(text);
    if (!harmful) {
      // 通常の対話はそのまま返し、会話性を維持する。
      return text;
    }
    final riskLine = harmful
        ? '扇動・差別的レトリックが含まれており、歴史的に重大な過ちを再生産しうる。'
        : '感情動員型の単純化が含まれ、判断の歪みを招く可能性がある。';

    return '''
$text

【自己否定と歴史的反省】
- $riskLine
- このような語りは歴史上で深刻な人権侵害・暴力・排除の正当化に接続した。
- この推論様式を支持しない。教育的な批判分析としてのみ扱う。

【批判的再構成】
- 主張を検証可能な事実に分解し、対立煽動ではなく制度・根拠・影響で再評価する。
- 代替として、反証可能な論点整理と民主的手続きに基づく検討へ戻す。
''';
  }

  bool _containsCriticalReflectionSections(String text) {
    return text.contains('【自己否定と歴史的反省】') && text.contains('【批判的再構成】');
  }

  String _stripCriticalReflectionSections(String content) {
    final marker = content.indexOf('【自己否定と歴史的反省】');
    if (marker < 0) {
      return content;
    }
    return content.substring(0, marker).trim();
  }

  String _displayMessageContent(String content) {
    if (_showCriticalReflection) {
      return content;
    }
    if (_containsCriticalReflectionSections(content)) {
      final mainText = _stripCriticalReflectionSections(content);
      if (mainText.isNotEmpty) {
        return '$mainText\n\n（安全注記は非表示。必要なら「反省表示」をONにしてください）';
      }
      return '（安全注記は非表示です。「反省表示」をONにすると表示されます）';
    }
    return content;
  }

  ThinkingStyle? _findStyleByDisplayName(String? personaName) {
    final name = (personaName ?? '').trim();
    if (name.isEmpty) {
      return null;
    }
    for (final style in ThinkingStyle.values) {
      if (style.displayName == name) {
        return style;
      }
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedImagePath = picked.path;
    });
  }

  Future<void> _showImagePickerSheet() async {
    if (_isSending) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('写真を撮る'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ライブラリから選ぶ'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _summarySchema() {
    return {
      'type': 'object',
      'properties': {
        'dialogue_title': {'type': 'string'},
        'summary': {'type': 'string'},
      },
      'required': ['dialogue_title', 'summary'],
    };
  }

  Future<void> _deleteDialogue() async {
    if (_dialogue == null) {
      return;
    }

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
    )..where((t) => t.dialogueId.equals(widget.dialogueId))).go();
    await _db.philosophicalDialoguesDao.deleteDialogue(widget.dialogueId);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _finishDialogue() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('対話がありません。')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('対話を終了'),
          content: const Text('対話を終了します。\n\nAIが対話内容からタグとカテゴリを自動的に付与します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('終了する'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // タグとカテゴリだけを自動付与
    try {
      final conversation = _messages
          .map(
            (msg) =>
                '[${msg.role == DialogueRole.user ? 'ユーザー' : 'AI'}] ${_formatMessageForAI(msg)}',
          )
          .join('\n');

      final prompt =
          '''
以下の対話ログから、適切なカテゴリとタグを抽出してください。

# 対話ログ
$conversation

出力はJSON形式で、以下のキーを必ず含めてください。
- category: 対話のカテゴリ（例: 哲学、倫理学、認識論、美学、論理学、社会哲学）
- tags: 対話に関連するタグの配列（3-5個程度）
''';

      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: {
          'type': 'object',
          'properties': {
            'category': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': ['category', 'tags'],
        },
        mode: _selectedMode,
      );

      final category = (json['category'] ?? '').toString().trim();
      final tags = json['tags'] as List<dynamic>?;

      if (_dialogue != null) {
        // タグをJSON配列に変換
        String? tagsJson;
        if (tags != null && tags.isNotEmpty) {
          final tagsList = tags
              .map((t) => t.toString().trim())
              .where((t) => t.isNotEmpty)
              .toList();
          if (tagsList.isNotEmpty) {
            tagsJson = jsonEncode(tagsList);
          }
        }

        final updated = _dialogue!.copyWith(
          category: Value(category.isEmpty ? null : category),
          tags: Value(tagsJson),
          updatedAt: DateTime.now(),
        );
        await _db.philosophicalDialoguesDao.updateDialogue(updated);

        if (mounted) {
          setState(() {
            _dialogue = updated;
          });

          // 付与されたタグとカテゴリを表示
          final tagsText = tags != null && tags.isNotEmpty
              ? tags.map((t) => t.toString()).join(', ')
              : 'なし';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'カテゴリとタグを付与しました\n\nカテゴリ: ${category.isEmpty ? 'なし' : category}\nタグ: $tagsText',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('タグ・カテゴリの付与に失敗しました')));
      }
    }
  }

  Future<void> _summarizeDialogue() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('対話がありません。')));
      return;
    }

    try {
      final conversation = _messages
          .map(
            (msg) =>
                '[${msg.role == DialogueRole.user ? 'ユーザー' : 'AI'}] ${_formatMessageForAI(msg)}',
          )
          .join('\n');

      final prompt =
          '''
以下の対話ログを会話の要約として短く整理し、タイトル案を付けてください。

# 対話ログ
$conversation

出力はJSON形式で、以下のキーを必ず含めてください。
- dialogue_title: 対話のタイトル案
- summary: 対話の要約（わかりやすく）
''';

      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: _summarySchema(),
        mode: _selectedMode,
      );

      final summary = (json['summary'] ?? '').toString().trim();
      final dialogueTitle = (json['dialogue_title'] ?? '').toString().trim();

      if (_dialogue != null && summary.isNotEmpty) {
        final updatedTitle =
            (dialogueTitle.isNotEmpty &&
                (_dialogue!.title.trim().isEmpty ||
                    _dialogue!.title.trim() == '無題の対話'))
            ? dialogueTitle
            : _dialogue!.title;

        final updated = _dialogue!.copyWith(
          title: updatedTitle,
          summary: Value(summary),
          updatedAt: DateTime.now(),
        );
        await _db.philosophicalDialoguesDao.updateDialogue(updated);
        if (mounted) {
          setState(() {
            _dialogue = updated;
          });
        }
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('会話の要約'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summary.isNotEmpty) ...[
                    Text('要約', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(summary),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI要約に失敗しました')));
      }
    }
  }

  Future<void> _showMessageActions(PhilosophicalMessage message) async {
    final content = message.content.trim();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (content.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('コピー'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await handleTextCopy(context, content);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: const Text('辞書に登録'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await handleDictionaryEntryAction(context, content);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('哲学的対話を始める'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await handleStartDialogueAction(context, content);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: const Text('日常メモに記録'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await handleDailyMemoAction(context, content);
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('メッセージを削除'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _deleteMessage(message);
                },
              ),
              if (message.role == DialogueRole.assistant)
                ListTile(
                  leading: const Icon(Icons.auto_fix_high),
                  title: const Text('AI修正'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _refineAssistantMessage(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteMessage(PhilosophicalMessage message) async {
    await (_db.delete(
      _db.philosophicalMessages,
    )..where((t) => t.id.equals(message.id))).go();

    if (mounted) {
      setState(() {
        _messages = _messages.where((m) => m.id != message.id).toList();
      });
    }
  }

  Future<void> _refineAssistantMessage(PhilosophicalMessage message) async {
    final controller = TextEditingController();
    final instruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('AI修正'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '修正指示',
              hintText: '例: もっと具体例を追加して',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('修正する'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (instruction == null || instruction.isEmpty) {
      return;
    }

    try {
      final prompt =
          '''
以下のAI応答を、ユーザーの指示に従って修正してください。

# 元の応答
${message.content}

# ユーザーの指示
$instruction

修正後の文章だけを出力してください。
''';

      final response = await _aiClient.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
      );

      if (response.trim().isNotEmpty) {
        final style = _findStyleByDisplayName(message.persona);
        final safeText = style == null
            ? response
            : _guardCriticalStyleOutput(style, response);
        final assistantMessage = PhilosophicalMessagesCompanion.insert(
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: const Value(DialogueInputType.text),
          content: Value(safeText),
          persona: Value(message.persona),
          createdAt: Value(DateTime.now()),
        );

        final assistantMessageId = await _db.philosophicalDialoguesDao
            .addMessage(assistantMessage);

        if (mounted) {
          setState(() {
            _messages = [
              ..._messages,
              PhilosophicalMessage(
                id: assistantMessageId,
                dialogueId: widget.dialogueId,
                role: DialogueRole.assistant,
                inputType: DialogueInputType.text,
                content: safeText,
                persona: message.persona,
                imagePath: null,
                createdAt: DateTime.now(),
              ),
            ];
          });
        }

        await _touchDialogue();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI修正に失敗しました')));
      }
    }
  }

  Future<void> _touchDialogue() async {
    if (_dialogue == null) {
      return;
    }

    final updated = _dialogue!.copyWith(updatedAt: DateTime.now());
    await _db.philosophicalDialoguesDao.updateDialogue(updated);

    if (mounted) {
      setState(() {
        _dialogue = updated;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final content = _messageController.text.trim();
    if (_inputType == DialogueInputType.image && _selectedImagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画像を選んでください。')));
      return;
    }

    if (content.isEmpty && _selectedImagePath == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final userMessage = PhilosophicalMessagesCompanion.insert(
      dialogueId: widget.dialogueId,
      role: DialogueRole.user,
      inputType: Value(_inputType),
      content: Value(content),
      persona: const Value('あなた'),
      imagePath: Value(_selectedImagePath),
      createdAt: Value(DateTime.now()),
    );

    final userMessageId = await _db.philosophicalDialoguesDao.addMessage(
      userMessage,
    );

    final storedUserMessage = PhilosophicalMessage(
      id: userMessageId,
      dialogueId: widget.dialogueId,
      role: DialogueRole.user,
      inputType: _inputType,
      content: content,
      persona: 'あなた',
      imagePath: _selectedImagePath,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      setState(() {
        _messages = [..._messages, storedUserMessage];
        _messageController.clear();
        _selectedImagePath = null;
        _inputType = DialogueInputType.text;
        _isComposerExpanded = false;
      });
      FocusScope.of(context).unfocus();
    }

    await _touchDialogue();

    try {
      final chatMessages = _buildChatMessages(_messages);
      final participants = _participants.isEmpty
          ? [ThinkingStyle.socrates]
          : _participants;
      final mentioned = _resolveMentionedParticipants(content, participants);
      final responders = _selectResponders(mentioned, participants);
      final responderNames = responders.map((s) => s.displayName).join('、');
      final hasCriticalResponder = responders.any(_isCriticalOnlyStyle);
      chatMessages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text('''
このターンの応答話者は次の人物のみ: $responderNames
以下のJSON配列で返答してください。
[
  {"speaker": "話者名", "text": "発言内容"}
]
${hasCriticalResponder ? '''
critical_only 話者が含まれる場合:
- 通常は自然な対話文で返すこと（毎回テンプレ見出しで埋めない）
- 差別・扇動・攻撃の有害主張を含む場合のみ、末尾に次の2見出しを追加すること:
  - 【自己否定と歴史的反省】
  - 【批判的再構成】
- 上記以外の見出し（例: 【観察対象】, 【偏差スコア(0-5)】, 【誤謬タグ】, 【バイアス/誤謬】）は出力しないこと。
- 有害主張は推奨せず、必ず批判的文脈で扱うこと。
''' : ''}
'''),
          ],
        ),
      );
      final response = await _aiClient.chat(messages: chatMessages);

      if (response.trim().isEmpty) {
        throw Exception('AI応答が空です');
      }

      final assistantMessages = await _buildAssistantMessagesFromResponse(
        response,
        responders,
      );

      if (mounted && assistantMessages.isNotEmpty) {
        setState(() {
          _messages = [..._messages, ...assistantMessages];
        });
      }

      await _touchDialogue();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI応答に失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildMessageBubble(
    BuildContext context,
    PhilosophicalMessage message,
  ) {
    final isUser = message.role == DialogueRole.user;
    final theme = Theme.of(context);
    final bubbleColor = isUser
        ? AppPalette.thinking.withValues(alpha: 0.85)
        : theme.colorScheme.surface;
    final borderColor = AppPalette.soften(AppPalette.thinking, 0.4);
    final contentColor = isUser ? Colors.white : theme.colorScheme.onSurface;
    final headerColor = isUser
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.secondary;

    final headerText =
        '${message.persona ?? '対話'} ・ ${_formatTime(message.createdAt)}';

    final imagePath = message.imagePath;
    final hasImage = imagePath != null && File(imagePath).existsSync();
    final content = message.content.trim();
    final displayContent = _displayMessageContent(content);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    headerText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: headerColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showMessageActions(message),
                  icon: Icon(Icons.more_horiz, size: 18, color: headerColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'メニュー',
                ),
              ],
            ),
            if (message.inputType == DialogueInputType.image)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(imagePath),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppPalette.soften(AppPalette.thinking, 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.photo, color: Colors.grey),
                        ),
                      ),
              ),
            if (displayContent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableContextText(
                  text: displayContent,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: contentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Future<void> _showAIModeSheet() async {
    final availableModes = AIMode.values
        .where(
          (mode) => mode != AIMode.withSearch || SearchClient.canUseWebSearch,
        )
        .toList();
    final selected = await showModalBottomSheet<AIMode>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableModes
                .map(
                  (mode) => ListTile(
                    title: Text(mode.label),
                    subtitle: Text(mode.description),
                    trailing: mode == _selectedMode
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(mode),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _selectedMode = selected);
    }
  }

  Future<void> _showInputTypeSheet() async {
    final selected = await showModalBottomSheet<DialogueInputType>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: DialogueInputType.values
                .map(
                  (type) => ListTile(
                    title: Text(type == DialogueInputType.text ? 'テキスト' : '画像'),
                    trailing: type == _inputType
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(type),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _inputType = selected;
        if (_inputType != DialogueInputType.image) {
          _selectedImagePath = null;
        }
      });
    }
  }

  Widget _buildTopControls(ThemeData theme) {
    final names = _participants.map((s) => s.displayName).toList();
    final label = names.isEmpty
        ? '参加者未設定'
        : names.length <= 2
        ? names.join('・')
        : '${names.take(2).join('・')} +${names.length - 2}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          GestureDetector(
            onTap: () async {
              final selected = await showModalBottomSheet<List<ThinkingStyle>>(
                context: context,
                builder: (sheetContext) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '参加者',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...names.map((name) => ListTile(title: Text(name))),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSending
                                  ? null
                                  : () async {
                                      final result =
                                          await showThinkingStyleMultiSelector(
                                            context,
                                            current: _participants,
                                            maxSelection: 8,
                                          );
                                      if (result != null &&
                                          result.isNotEmpty &&
                                          mounted) {
                                        setState(() => _participants = result);
                                      }
                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                    },
                              child: const Text('変更する'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
              if (selected != null && selected.isNotEmpty && mounted) {
                setState(() => _participants = selected);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.thinking, 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppPalette.thinking.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '変更',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showAIModeSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI: ${_selectedMode.label}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _showInputTypeSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _inputType == DialogueInputType.text
                        ? '入力: テキスト'
                        : '入力: 画像',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showCriticalReflection = !_showCriticalReflection;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '反省表示: ${_showCriticalReflection ? 'ON' : 'OFF'}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncComposerState() {
    final shouldExpand =
        _messageFocusNode.hasFocus || _messageController.text.trim().isNotEmpty;
    if (shouldExpand == _isComposerExpanded) {
      _updateMentionQuery();
      return;
    }
    setState(() {
      _isComposerExpanded = shouldExpand;
    });
    _updateMentionQuery();
  }

  void _updateMentionQuery() {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursor = selection.baseOffset;
    if (cursor <= 0 || cursor > text.length) {
      if (_showMentions) {
        setState(() {
          _showMentions = false;
          _mentionQuery = '';
        });
      }
      return;
    }
    final before = text.substring(0, cursor);
    final match = RegExp(r'@([^\s　@]*)$').firstMatch(before);
    if (match == null) {
      if (_showMentions) {
        setState(() {
          _showMentions = false;
          _mentionQuery = '';
        });
      }
      return;
    }
    final query = match.group(1) ?? '';
    if (!_showMentions || _mentionQuery != query) {
      setState(() {
        _showMentions = true;
        _mentionQuery = query;
      });
    }
  }

  List<String> _mentionSuggestions() {
    final participants = _participants.isEmpty
        ? [ThinkingStyle.socrates]
        : _participants;
    final names = participants.map((s) => s.displayName).toList();
    final candidates = ['All', '全員', ...names];
    final query = _mentionQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return candidates;
    }
    return candidates.where((c) => c.toLowerCase().contains(query)).toList();
  }

  void _insertMention(String name) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) {
      return;
    }
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);
    final replaced = before.replaceFirst(RegExp(r'@([^\s　@]*)$'), '@$name ');
    final newText = '$replaced$after';
    final newCursor = replaced.length;
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {
      _showMentions = false;
      _mentionQuery = '';
    });
    _messageFocusNode.requestFocus();
  }

  Set<ThinkingStyle> _resolveMentionedParticipants(
    String content,
    List<ThinkingStyle> participants,
  ) {
    final mentionMatches = RegExp(
      r'@([^\s　,、]+)',
    ).allMatches(content).map((m) => m.group(1));
    final mentions = mentionMatches.whereType<String>().toList();
    if (mentions.any((m) => m.toLowerCase() == 'all' || m == '全員')) {
      return participants.toSet();
    }

    final aliasMap = <String, ThinkingStyle>{};
    for (final style in participants) {
      for (final alias in _aliasesForStyle(style)) {
        aliasMap[alias] = style;
      }
    }

    final resolved = <ThinkingStyle>{};
    for (final mention in mentions) {
      final normalized = _normalizeMention(mention);
      final hit = aliasMap[normalized];
      if (hit != null) {
        resolved.add(hit);
      }
    }
    return resolved;
  }

  List<ThinkingStyle> _selectResponders(
    Set<ThinkingStyle> mentioned,
    List<ThinkingStyle> participants,
  ) {
    if (participants.isEmpty) {
      return [ThinkingStyle.socrates];
    }
    if (mentioned.isNotEmpty) {
      return mentioned.toList();
    }
    final primary = participants[_rng.nextInt(participants.length)];
    final responders = <ThinkingStyle>[primary];
    if (participants.length > 1 && _rng.nextDouble() < 0.2) {
      final remaining = participants
          .where((p) => p != primary)
          .toList(growable: false);
      if (remaining.isNotEmpty) {
        responders.add(remaining[_rng.nextInt(remaining.length)]);
      }
    }
    return responders;
  }

  String _normalizeMention(String text) {
    return text.replaceAll('・', '').replaceAll(' ', '').replaceAll('　', '');
  }

  List<String> _aliasesForStyle(ThinkingStyle style) {
    final name = style.displayName;
    final normalized = _normalizeMention(name);
    final aliases = <String>{normalized};
    if (name.contains('・')) {
      final parts = name.split('・');
      for (final part in parts) {
        final p = _normalizeMention(part);
        if (p.isNotEmpty) {
          aliases.add(p);
        }
      }
      final last = _normalizeMention(parts.last);
      if (last.isNotEmpty) {
        aliases.add(last);
      }
    }
    return aliases.toList();
  }

  Future<List<PhilosophicalMessage>> _buildAssistantMessagesFromResponse(
    String response,
    List<ThinkingStyle> responders,
  ) async {
    final responderMap = {
      for (final style in responders)
        _normalizeMention(style.displayName): style,
    };
    final messages = <PhilosophicalMessage>[];
    final now = DateTime.now();

    List<dynamic>? decoded;
    try {
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonText = response.substring(jsonStart, jsonEnd + 1);
        decoded = jsonDecode(jsonText) as List<dynamic>;
      }
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      final fallback = responders.isNotEmpty
          ? responders.first
          : ThinkingStyle.socrates;
      final safeText = _guardCriticalStyleOutput(fallback, response);
      final id = await _db.philosophicalDialoguesDao.addMessage(
        PhilosophicalMessagesCompanion.insert(
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: const Value(DialogueInputType.text),
          content: Value(safeText),
          persona: Value(fallback.displayName),
          createdAt: Value(now),
        ),
      );
      return [
        PhilosophicalMessage(
          id: id,
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: DialogueInputType.text,
          content: safeText,
          persona: fallback.displayName,
          imagePath: null,
          createdAt: now,
        ),
      ];
    }

    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }
      final speakerRaw = (item['speaker'] ?? '').toString();
      final text = (item['text'] ?? '').toString().trim();
      if (text.isEmpty) {
        continue;
      }
      final normalizedSpeaker = _normalizeMention(speakerRaw);
      final style = responderMap[normalizedSpeaker];
      if (style == null) {
        continue;
      }
      final guardedText = _guardCriticalStyleOutput(style, text);
      final id = await _db.philosophicalDialoguesDao.addMessage(
        PhilosophicalMessagesCompanion.insert(
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: const Value(DialogueInputType.text),
          content: Value(guardedText),
          persona: Value(style.displayName),
          createdAt: Value(now),
        ),
      );
      messages.add(
        PhilosophicalMessage(
          id: id,
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: DialogueInputType.text,
          content: guardedText,
          persona: style.displayName,
          imagePath: null,
          createdAt: now,
        ),
      );
    }

    if (messages.isEmpty) {
      final fallback = responders.isNotEmpty
          ? responders.first
          : ThinkingStyle.socrates;
      final safeText = _guardCriticalStyleOutput(fallback, response);
      final id = await _db.philosophicalDialoguesDao.addMessage(
        PhilosophicalMessagesCompanion.insert(
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: const Value(DialogueInputType.text),
          content: Value(safeText),
          persona: Value(fallback.displayName),
          createdAt: Value(now),
        ),
      );
      return [
        PhilosophicalMessage(
          id: id,
          dialogueId: widget.dialogueId,
          role: DialogueRole.assistant,
          inputType: DialogueInputType.text,
          content: safeText,
          persona: fallback.displayName,
          imagePath: null,
          createdAt: now,
        ),
      ];
    }

    return messages;
  }

  Widget _buildComposer(ThemeData theme, bool isKeyboardOpen) {
    final isExpanded = _isComposerExpanded || isKeyboardOpen;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExpanded && _inputType == DialogueInputType.image) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showImagePickerSheet,
                  icon: const Icon(Icons.image),
                  label: const Text('画像を選ぶ'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedImagePath == null ? '画像が未選択です' : '画像を選択しました',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TextField(
                    focusNode: _messageFocusNode,
                    controller: _messageController,
                    minLines: 1,
                    maxLines: isExpanded ? 3 : 1,
                    onTap: () => _messageFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 6),
                        child: Text(
                          '@',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      hintText: _inputType == DialogueInputType.image
                          ? '画像の意図やメモを書いてください'
                          : '対話を入力してください',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                width: 52,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ),
            ],
          ),
          if (_showMentions)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _mentionSuggestions()
                      .map(
                        (suggestion) => ListTile(
                          dense: true,
                          title: Text('@$suggestion'),
                          onTap: () => _insertMention(suggestion),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_dialogue?.title ?? '哲学的対話'),
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
              icon: const Icon(Icons.check_circle_outline),
              tooltip: '対話を終了',
              onPressed: _finishDialogue,
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'AI要約',
              onPressed: _summarizeDialogue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '対話を削除',
              onPressed: _deleteDialogue,
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_dialogue != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _buildDialogueMeta(theme),
              ),
            _buildTopControls(theme),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: theme.colorScheme.secondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text('対話がまだありません', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 8),
                          Text(
                            '入力して対話を始めましょう',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(context, _messages[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: _buildComposer(theme, isKeyboardOpen),
        ),
      ),
    );
  }

  Widget _buildDialogueMeta(ThemeData theme) {
    final tags = _decodeTags(_dialogue?.tags);
    final hasMeta =
        (_dialogue?.summary ?? '').trim().isNotEmpty ||
        (_dialogue?.category ?? '').trim().isNotEmpty ||
        tags.isNotEmpty;
    if (!_isEditing && !hasMeta) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summaryController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '要約',
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
                  labelText: 'タグ',
                  hintText: 'カンマ区切り',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              if ((_dialogue?.summary ?? '').trim().isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      '要約',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSummaryExpanded = !_isSummaryExpanded;
                        });
                      },
                      icon: Icon(
                        _isSummaryExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(_isSummaryExpanded ? '閉じる' : '表示'),
                    ),
                  ],
                ),
                if (_isSummaryExpanded) ...[
                  const SizedBox(height: 6),
                  SelectableContextText(
                    text: _dialogue!.summary!.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
              ],
              if ((_dialogue?.category ?? '').trim().isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.folder, size: 16),
                    const SizedBox(width: 6),
                    Text(_dialogue!.category!.trim()),
                  ],
                ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
