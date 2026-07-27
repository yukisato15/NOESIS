import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/models/ai_chat_message.dart';
import '../../core/ai/prompts/thinking_prompts.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/episode_clip_entries_table.dart';

class EpisodeClipDetailScreen extends StatefulWidget {
  final int clipId;
  final String episodeTitle;
  final String? programName;

  const EpisodeClipDetailScreen({
    super.key,
    required this.clipId,
    required this.episodeTitle,
    this.programName,
  });

  @override
  State<EpisodeClipDetailScreen> createState() => _EpisodeClipDetailScreenState();
}

class _EpisodeClipDetailScreenState extends State<EpisodeClipDetailScreen> {
  final AppDatabase _db = AppDatabase();

  EpisodeClip? _clip;
  List<EpisodeClipEntry> _entries = [];
  AudioPlayer? _player;
  bool _isLoading = true;
  bool _isProcessingAI = false;
  bool _isEditing = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  ThinkingStyle _selectedThinkingStyle = ThinkingStyle.socrates;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player?.dispose();
    _db.close();
    _titleController.dispose();
    _bodyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final clip = await _db.episodeClipsDao.getClipById(widget.clipId);
      final entries =
          await _db.episodeClipEntriesDao.getEntriesByClipId(widget.clipId);
      if (!mounted) return;
      setState(() {
        _clip = clip;
        _entries = entries;
        _isLoading = false;
      });
      _syncControllers();
      await _initPlayerIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('音声記録メモの読み込みに失敗しました: $e')),
      );
    }
  }

  void _syncControllers() {
    if (_clip == null) return;
    _titleController.text = _clip!.title ?? '';
    _bodyController.text = _primaryText;
    _noteController.text = _clip!.note ?? '';
  }

  Future<void> _initPlayerIfNeeded() async {
    final path = _clip?.audioFilePath;
    if (path == null || !File(path).existsSync()) {
      return;
    }
    _player ??= AudioPlayer()
      ..positionStream.listen((value) {
        if (mounted) {
          setState(() => _position = value);
        }
      })
      ..durationStream.listen((value) {
        if (mounted) {
          setState(() => _duration = value ?? Duration.zero);
        }
      })
      ..playingStream.listen((value) {
        if (mounted) {
          setState(() => _isPlaying = value);
        }
      })
      ..playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _player?.seek(Duration.zero);
          _player?.pause();
        }
      });
    await _player!.setFilePath(path);
  }

  String get _primaryText {
    if (_clip == null) return '';
    if (_clip!.transcript?.isNotEmpty == true) return _clip!.transcript!;
    return _clip!.clipText;
  }

  Future<void> _saveEdits() async {
    if (_clip == null) return;
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メモ本文を入力してください')),
      );
      return;
    }

    final updated = _clip!.copyWith(
      title: drift.Value(_titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim()),
      transcript: drift.Value(_clip!.transcript != null ? body : _clip!.transcript),
      clipText: body,
      note: drift.Value(_noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim()),
      updatedAt: drift.Value(DateTime.now()),
    );

    await _db.episodeClipsDao.updateClip(updated);
    setState(() {
      _clip = updated;
      _isEditing = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('音声記録メモを更新しました')),
    );
  }

  Future<void> _summarize() async {
    final content = _buildAiSourceText();
    if (content.isEmpty) return;
    setState(() => _isProcessingAI = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt: '''
以下の音声記録メモを要約してください。
- 全体を2文以内で要約
- 重要ポイントを3〜5個の箇条書きで整理

【コンテンツ】
$content
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'summary': {'type': 'string'},
            'key_points': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': ['summary', 'key_points'],
        },
      );

      final formatted = '''
## 要約

${result['summary']}

## 重要ポイント

${(result['key_points'] as List).map((e) => '• $e').join('\n')}
''';

      await _db.episodeClipEntriesDao.insertEntry(
        EpisodeClipEntriesCompanion.insert(
          clipId: widget.clipId,
          entryType: EpisodeClipEntryType.aiSummary,
          content: formatted,
          thinkingStyleName: drift.Value(_selectedThinkingStyle.name),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI要約に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _rewrite() async {
    final content = _buildAiSourceText();
    if (content.isEmpty) return;
    setState(() => _isProcessingAI = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt: '''
以下の音声記録メモ本文を、意味を変えずに整えてください。
- 誤字脱字、句読点、明らかな文字起こしノイズのみ修正
- 要約しない
- 断定的に補完しすぎない
- 元の文量と論点をできるだけ保つ

【元の本文】
$content
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'rewritten': {'type': 'string'},
          },
          'required': ['rewritten'],
        },
      );

      await _db.episodeClipEntriesDao.insertEntry(
        EpisodeClipEntriesCompanion.insert(
          clipId: widget.clipId,
          entryType: EpisodeClipEntryType.aiRewrite,
          content: result['rewritten'] as String,
          thinkingStyleName: drift.Value(_selectedThinkingStyle.name),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI整文に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _askQuestion() async {
    final content = _buildAiSourceText();
    if (content.isEmpty) return;
    final questionController = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('質問'),
        content: TextField(
          controller: questionController,
          decoration: const InputDecoration(
            hintText: 'このメモについて質問する',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, questionController.text),
            child: const Text('送信'),
          ),
        ],
      ),
    );
    questionController.dispose();

    if (question == null || question.trim().isEmpty) return;
    setState(() => _isProcessingAI = true);
    try {
      final answer = await AIClient.instance.chat(
        messages: ThinkingPrompts.buildChatMessages(
          style: _selectedThinkingStyle,
          memoContent: content,
          history: [
            AIChatMessage(role: 'user', content: question.trim()),
          ],
        ),
      );

      final formatted = '''
## 質問
$question

## 回答
$answer
''';

      await _db.episodeClipEntriesDao.insertEntry(
        EpisodeClipEntriesCompanion.insert(
          clipId: widget.clipId,
          entryType: EpisodeClipEntryType.aiQA,
          content: formatted,
          question: drift.Value(question.trim()),
          thinkingStyleName: drift.Value(_selectedThinkingStyle.name),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('質問応答に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _addManualNote() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('追記を追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '追加で気づいたことや整理を書き残す',
            border: OutlineInputBorder(),
          ),
          minLines: 4,
          maxLines: 8,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.trim().isEmpty) return;

    await _db.episodeClipEntriesDao.insertEntry(
      EpisodeClipEntriesCompanion.insert(
        clipId: widget.clipId,
        entryType: EpisodeClipEntryType.manualNote,
        content: note.trim(),
      ),
    );
    await _load();
  }

  Future<void> _deleteEntry(EpisodeClipEntry entry) async {
    await _db.episodeClipEntriesDao.deleteEntry(entry.id);
    await _load();
  }

  String _buildAiSourceText() {
    final buffer = StringBuffer();
    if (_clip?.title?.isNotEmpty == true) {
      buffer.writeln('メモタイトル: ${_clip!.title}');
    }
    buffer.writeln('コンテンツ名: ${widget.episodeTitle}');
    if (widget.programName?.isNotEmpty == true) {
      buffer.writeln('番組名・チャンネル名: ${widget.programName}');
    }
    if (_primaryText.isNotEmpty) {
      buffer.writeln('\n本文:\n$_primaryText');
    }
    if (_clip?.note?.isNotEmpty == true) {
      buffer.writeln('\n自分のメモ:\n${_clip!.note}');
    }
    return buffer.toString().trim();
  }

  String _entryLabel(EpisodeClipEntryType type) {
    switch (type) {
      case EpisodeClipEntryType.original:
        return '初回記録';
      case EpisodeClipEntryType.aiSummary:
        return 'AI要約';
      case EpisodeClipEntryType.aiRewrite:
        return 'AIリライト';
      case EpisodeClipEntryType.aiQA:
        return '質問応答';
      case EpisodeClipEntryType.manualNote:
        return '手動追記';
    }
  }

  IconData _entryIcon(EpisodeClipEntryType type) {
    switch (type) {
      case EpisodeClipEntryType.original:
        return Icons.notes;
      case EpisodeClipEntryType.aiSummary:
        return Icons.summarize_outlined;
      case EpisodeClipEntryType.aiRewrite:
        return Icons.auto_fix_high_outlined;
      case EpisodeClipEntryType.aiQA:
        return Icons.question_answer_outlined;
      case EpisodeClipEntryType.manualNote:
        return Icons.note_add_outlined;
    }
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('音声記録メモ詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_clip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('音声記録メモ詳細')),
        body: const Center(child: Text('音声記録メモが見つかりませんでした')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声記録メモ詳細'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEdits,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _syncControllers();
                setState(() => _isEditing = false);
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _syncControllers();
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.episodeTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.programName?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.programName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_clip!.audioFilePath != null &&
                File(_clip!.audioFilePath!).existsSync()) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: AppPalette.listening.withValues(alpha: 0.07),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '音声メモ再生',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.listening,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              if (_isPlaying) {
                                await _player?.pause();
                              } else {
                                await _player?.play();
                              }
                            },
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(_isPlaying ? '一時停止' : '再生'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _duration.inMilliseconds == 0
                            ? 0
                            : (_position.inMilliseconds /
                                    _duration.inMilliseconds)
                                .clamp(0.0, 1.0),
                        onChanged: _duration.inMilliseconds == 0
                            ? null
                            : (value) {
                                final target = Duration(
                                  milliseconds:
                                      (_duration.inMilliseconds * value).round(),
                                );
                                _player?.seek(target);
                              },
                        activeColor: AppPalette.listening,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_clip!.audioFilePath != null &&
                !File(_clip!.audioFilePath!).existsSync()) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '音声ファイルが見つかりません',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'このメモには音声パスが残っていますが、元ファイルが端末内に存在しません。以前の一時保存ファイルを参照していた可能性があります。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'メモ本文',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'メモタイトル（任意）',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bodyController,
                            minLines: 6,
                            maxLines: 12,
                            decoration: const InputDecoration(
                              labelText: 'メモ本文',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            minLines: 3,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: '自分のメモ',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_clip!.title?.isNotEmpty == true) ...[
                            Text(
                              _clip!.title!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppPalette.listening,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SelectableContextText(
                            text: _primaryText,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (_clip!.note?.isNotEmpty == true) ...[
                            const SizedBox(height: 18),
                            Text(
                              '自分のメモ',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppPalette.listening,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableContextText(
                              text: _clip!.note!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '作成日時: ${_clip!.createdAt.year}/${_clip!.createdAt.month}/${_clip!.createdAt.day} ${_clip!.createdAt.hour}:${_clip!.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
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
                child: DropdownButton<ThinkingStyle>(
                  value: _selectedThinkingStyle,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: ThinkingStyle.values
                      .map(
                        (style) => DropdownMenuItem(
                          value: style,
                          child: Text(
                            '${style.displayName} - ${style.description}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (style) {
                    if (style != null) {
                      setState(() => _selectedThinkingStyle = style);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    icon: const Icon(Icons.summarize_outlined, size: 18),
                    label: const Text('要約'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingAI ? null : _rewrite,
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                    label: const Text('リライト'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessingAI ? null : _askQuestion,
                    icon: const Icon(Icons.question_answer_outlined, size: 18),
                    label: const Text('質問'),
                  ),
                ),
              ],
            ),
            if (_isProcessingAI) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            if (_entries.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '追記履歴',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in _entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _entryIcon(entry.entryType),
                              size: 18,
                              color: AppPalette.listening,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _entryLabel(entry.entryType),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppPalette.listening,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteEntry(entry),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (entry.thinkingStyleName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            ThinkingStyle.values
                                .firstWhere(
                                  (style) => style.name == entry.thinkingStyleName,
                                  orElse: () => ThinkingStyle.socrates,
                                )
                                .displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppPalette.listening,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SelectableContextText(
                          text: entry.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
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
