import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/models/ai_chat_message.dart';
import '../../core/ai/prompts/thinking_prompts.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/listening_audio_storage.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/book_ai_entries_table.dart';
import '../../data/local/tables/episode_clips_table.dart';
import 'episode_clip_detail_screen.dart';
import '../../data/local/tables/podcast_episodes_table.dart';
import 'recording_memo_screen.dart';
import 'text_memo_screen.dart';

class EpisodeDetailScreen extends StatefulWidget {
  final int episodeId;

  const EpisodeDetailScreen({super.key, required this.episodeId});

  @override
  State<EpisodeDetailScreen> createState() => _EpisodeDetailScreenState();
}

class _EpisodeDetailScreenState extends State<EpisodeDetailScreen>
    with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  // AudioPlayer は起動時に生成しない（Audible など他アプリの音声を止めないため）
  AudioPlayer? _player;
  late TabController _tabController;

  PodcastEpisode? _episode;
  List<EpisodeClip> _clips = [];
  List<EpisodeAiEntry> _overallAiEntries = [];
  bool _loading = true;

  // 再生状態
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // 編集状態
  bool _editMode = false;
  late TextEditingController _titleController;
  late TextEditingController _programController;
  late TextEditingController _speakerController;
  late TextEditingController _genreController;
  late TextEditingController _publishedDateController;
  late TextEditingController _sourceUrlController;
  late TextEditingController _relatedUrlController;
  late TextEditingController _ratingController;
  late TextEditingController _synopsisController;
  late TextEditingController _reviewSummaryController;
  late TextEditingController _transcriptController;
  late TextEditingController _summaryController;

  // AI
  bool _aiLoading = false;
  ThinkingStyle _selectedThinkingStyle = ThinkingStyle.socrates;

  bool get _hasTranscript => _episode?.transcript?.isNotEmpty == true;

  void _initPlayer() {
    if (_player != null) return;
    _player = AudioPlayer();
    _player!.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player!.durationStream.listen((dur) {
      if (mounted) setState(() => _duration = dur ?? Duration.zero);
    });
    _player!.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
  }

  Future<String> _persistClipAudioFile(String inputPath) async {
    return ListeningAudioStorage.persistAudioFile(
      inputPath,
      folderName: 'listening_audio',
      prefix: 'clip_file',
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _titleController = TextEditingController();
    _programController = TextEditingController();
    _speakerController = TextEditingController();
    _genreController = TextEditingController();
    _publishedDateController = TextEditingController();
    _sourceUrlController = TextEditingController();
    _relatedUrlController = TextEditingController();
    _ratingController = TextEditingController();
    _synopsisController = TextEditingController();
    _reviewSummaryController = TextEditingController();
    _transcriptController = TextEditingController();
    _summaryController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _db.close();
    _player?.dispose();
    _titleController.dispose();
    _programController.dispose();
    _speakerController.dispose();
    _genreController.dispose();
    _publishedDateController.dispose();
    _sourceUrlController.dispose();
    _relatedUrlController.dispose();
    _ratingController.dispose();
    _synopsisController.dispose();
    _reviewSummaryController.dispose();
    _transcriptController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final episode =
        await _db.podcastEpisodesDao.getEpisodeById(widget.episodeId);
    final clips =
        await _db.episodeClipsDao.getClipsByEpisode(widget.episodeId);
    final aiEntries =
        await _db.episodeAiEntriesDao.getEntriesByEpisodeId(widget.episodeId);
    if (!mounted) return;
    setState(() {
      _episode = episode;
      _clips = clips;
      _overallAiEntries = aiEntries;
      _loading = false;
    });
    if (episode != null) {
      _titleController.text = episode.title;
      _programController.text = episode.programName ?? '';
      _speakerController.text = episode.speaker ?? '';
      _genreController.text = episode.genre ?? '';
      _publishedDateController.text = episode.publishedAt != null
          ? DateFormat('yyyy-MM-dd').format(episode.publishedAt!.toLocal())
          : '';
      _sourceUrlController.text = episode.sourceUrl ?? '';
      _relatedUrlController.text = episode.relatedUrl ?? '';
      _ratingController.text = episode.rating ?? '';
      _synopsisController.text = episode.synopsis ?? '';
      _reviewSummaryController.text = episode.reviewSummary ?? '';
      _transcriptController.text = episode.transcript ?? '';
      _summaryController.text = episode.summary ?? '';

      // 音声ファイルがあればプレーヤーを初期化（ここで初めて生成 → 他アプリの音声を止めない）
      if (episode.audioFilePath != null &&
          File(episode.audioFilePath!).existsSync()) {
        _initPlayer();
        await _player!
            .setFilePath(episode.audioFilePath!)
            .catchError((_) => null);
      }
    }
  }

  // ─── 保存 ────────────────────────────────────────────────

  Future<void> _saveEdit() async {
    if (_episode == null) return;
    final publishedAtRaw = _publishedDateController.text.trim();
    DateTime? publishedAt;
    if (publishedAtRaw.isNotEmpty) {
      publishedAt = DateTime.tryParse(publishedAtRaw);
      if (publishedAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配信日は YYYY-MM-DD 形式で入力してください')),
        );
        return;
      }
    }
    final updated = _episode!.copyWith(
      title: _titleController.text.trim(),
      programName: drift.Value(_programController.text.trim().isEmpty
          ? null
          : _programController.text.trim()),
      speaker: drift.Value(_speakerController.text.trim().isEmpty
          ? null
          : _speakerController.text.trim()),
      genre: drift.Value(_genreController.text.trim().isEmpty
          ? null
          : _genreController.text.trim()),
      publishedAt: drift.Value(publishedAt),
      sourceUrl: drift.Value(_sourceUrlController.text.trim().isEmpty
          ? null
          : _sourceUrlController.text.trim()),
      relatedUrl: drift.Value(_relatedUrlController.text.trim().isEmpty
          ? null
          : _relatedUrlController.text.trim()),
      rating: drift.Value(_ratingController.text.trim().isEmpty
          ? null
          : _ratingController.text.trim()),
      synopsis: drift.Value(_synopsisController.text.trim().isEmpty
          ? null
          : _synopsisController.text.trim()),
      reviewSummary: drift.Value(_reviewSummaryController.text.trim().isEmpty
          ? null
          : _reviewSummaryController.text.trim()),
      transcript: drift.Value(_transcriptController.text.trim().isEmpty
          ? null
          : _transcriptController.text.trim()),
      summary: drift.Value(_summaryController.text.trim().isEmpty
          ? null
          : _summaryController.text.trim()),
      updatedAt: DateTime.now(),
    );
    await _db.podcastEpisodesDao.updateEpisode(updated);
    setState(() {
      _episode = updated;
      _editMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存しました')));
    }
  }

  // ─── AI要約 ──────────────────────────────────────────────

  String _buildEpisodeAiSourceText() {
    if (_episode == null) return '';
    final buffer = StringBuffer();
    buffer.writeln('タイトル: ${_episode!.title}');
    if (_episode!.programName?.isNotEmpty == true) {
      buffer.writeln('番組名・チャンネル名: ${_episode!.programName}');
    }
    if (_episode!.speaker?.isNotEmpty == true) {
      buffer.writeln('話者・出演者: ${_episode!.speaker}');
    }
    if (_episode!.synopsis?.isNotEmpty == true) {
      buffer.writeln('\n概要:\n${_episode!.synopsis}');
    }
    if (_episode!.transcript?.isNotEmpty == true) {
      buffer.writeln('\nトランスクリプト:\n${_episode!.transcript}');
    } else if (_clips.isNotEmpty) {
      buffer.writeln('\n音声記録メモ:');
      for (final clip in _clips) {
        final body =
            clip.transcript?.isNotEmpty == true ? clip.transcript! : clip.clipText;
        if (body.trim().isEmpty) continue;
        buffer.writeln('- ${clip.title ?? clip.memoType.label}: $body');
        if (clip.note?.trim().isNotEmpty == true) {
          buffer.writeln('  自分のメモ: ${clip.note}');
        }
      }
    }
    return buffer.toString().trim();
  }

  List<String> get _overallQaHistory => _overallAiEntries
      .where((entry) => entry.entryType == AggregateAiEntryType.qa)
      .map((entry) => entry.content)
      .toList();

  List<EpisodeAiEntry> get _overallQaEntries => _overallAiEntries
      .where((entry) => entry.entryType == AggregateAiEntryType.qa)
      .toList();

  Future<void> _deleteOverallSummary() async {
    if (_episode == null) return;
    await _db.episodeAiEntriesDao.deleteEntriesByType(
      widget.episodeId,
      AggregateAiEntryType.summary,
    );
    final updated = _episode!.copyWith(
      summary: const drift.Value(null),
      updatedAt: DateTime.now(),
    );
    await _db.podcastEpisodesDao.updateEpisode(updated);
    await _load();
  }

  Future<void> _deleteOverallAnalysis() async {
    if (_episode == null) return;
    await _db.episodeAiEntriesDao.deleteEntriesByType(
      widget.episodeId,
      AggregateAiEntryType.analysis,
    );
    final updated = _episode!.copyWith(
      structuredNotes: const drift.Value(null),
      updatedAt: DateTime.now(),
    );
    await _db.podcastEpisodesDao.updateEpisode(updated);
    await _load();
  }

  Future<void> _deleteQuestionEntry(EpisodeAiEntry entry) async {
    await _db.episodeAiEntriesDao.deleteEntryById(entry.id);
    await _load();
  }

  Future<void> _generateSummary() async {
    final sourceText = _buildEpisodeAiSourceText();
    if (sourceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIが参照できる本文がありません')),
      );
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final ai = AIClient.instance;
      final result = await ai.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '以下の音声コンテンツ全体を要約してください。\n'
                '- 3〜5行の簡潔な要約\n'
                '- 主要なトピック・キーワード（箇条書き）\n'
                '- 特に重要な発言や知見\n\n'
                '## コンテンツ全体\n$sourceText',
              ),
            ],
          ),
        ],
      );
      final summary = result.trim();
      final updated = _episode!.copyWith(
        summary: drift.Value(summary),
        updatedAt: DateTime.now(),
      );
      await _db.podcastEpisodesDao.updateEpisode(updated);
      await _db.episodeAiEntriesDao.insertEntry(
        EpisodeAiEntriesCompanion.insert(
          episodeId: widget.episodeId,
          entryType: AggregateAiEntryType.summary,
          content: summary,
          thinkingStyleName: drift.Value(_selectedThinkingStyle.name),
        ),
      );
      if (mounted) {
        setState(() {
          _episode = updated;
          _summaryController.text = summary;
        });
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI要約エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _generateStructuredNotes() async {
    final sourceText = _buildEpisodeAiSourceText();
    if (sourceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIが参照できる本文がありません')),
      );
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final ai = AIClient.instance;
      final result = await ai.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '以下の音声コンテンツ全体を章立て・構造化してください。\n'
                'マークダウン形式で、見出し・箇条書き・重要ポイントを整理してください。\n\n'
                '## コンテンツ全体\n$sourceText',
              ),
            ],
          ),
        ],
      );
      final notes = result.trim();
      final updated = _episode!.copyWith(
        structuredNotes: drift.Value(notes),
        updatedAt: DateTime.now(),
      );
      await _db.podcastEpisodesDao.updateEpisode(updated);
      await _db.episodeAiEntriesDao.insertEntry(
        EpisodeAiEntriesCompanion.insert(
          episodeId: widget.episodeId,
          entryType: AggregateAiEntryType.analysis,
          content: notes,
          thinkingStyleName: drift.Value(_selectedThinkingStyle.name),
        ),
      );
      if (mounted) setState(() => _episode = updated);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI構造化エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _askAboutEpisode() async {
    final sourceText = _buildEpisodeAiSourceText();
    if (sourceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIが参照できる本文がありません')),
      );
      return;
    }

    final controller = TextEditingController();
    final question = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コンテンツ全体への質問'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '要点や論点について質問する',
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
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('送信'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (question == null || question.trim().isEmpty) return;

    setState(() => _aiLoading = true);
    try {
      final answer = await AIClient.instance.chat(
        messages: ThinkingPrompts.buildChatMessages(
          style: _selectedThinkingStyle,
          memoContent: sourceText,
          history: [
            AIChatMessage(role: 'user', content: question.trim()),
          ],
        ),
      );
      await _db.episodeAiEntriesDao.insertEntry(
        EpisodeAiEntriesCompanion.insert(
          episodeId: widget.episodeId,
          entryType: AggregateAiEntryType.qa,
          content: '## 質問\n${question.trim()}\n\n## 回答\n$answer',
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
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ─── メモ追加 ────────────────────────────────────────────

  Future<void> _addClip(String text) async {
    await _showTextMemoSheet(initialText: text);
  }

  Future<void> _showAddMemoBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('音声記録メモを追加',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MemoTypeButton(
                    icon: Icons.mic,
                    label: '録音',
                    color: Colors.red[400]!,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showRecordingMemoSheet();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoTypeButton(
                    icon: Icons.text_fields,
                    label: 'テキスト',
                    color: AppPalette.listening,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showTextMemoSheet();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MemoTypeButton(
                    icon: Icons.audio_file_outlined,
                    label: 'ファイル',
                    color: Colors.orange[700]!,
                    onTap: () {
                      Navigator.pop(ctx);
                      // シート閉鎖アニメーション完了後にファイルピッカーを起動
                      Future.delayed(
                        const Duration(milliseconds: 400),
                        _showFileMemoSheet,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTextMemoSheet({String initialText = ''}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TextMemoScreen(
          episodeId: widget.episodeId,
          initialText: initialText,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _showFileMemoSheet() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform
          .pickFiles(type: FileType.audio, allowMultiple: false);
    } catch (_) {
      return; // キャンセルまたはエラー時は何もしない
    }
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null) return;

    // 文字起こし → 保存
    String? transcript;
    String? errorMsg;
    bool loading = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          // 初回表示時に文字起こし開始
          if (loading && transcript == null && errorMsg == null) {
            Future.microtask(() async {
              try {
                final r = await OpenAI.instance.audio.createTranscription(
                  file: File(filePath),
                  model: 'whisper-1',
                  language: 'ja',
                  responseFormat: OpenAIAudioResponseFormat.json,
                );
                if (ctx.mounted) setInner(() { transcript = r.text; loading = false; });
              } catch (e) {
                if (ctx.mounted) setInner(() { errorMsg = 'エラー: $e'; loading = false; });
              }
            });
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ファイル文字起こし',
                    style: Theme.of(ctx).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(filePath.split('/').last,
                    style: Theme.of(ctx).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                if (loading)
                  const Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Whisperで文字起こし中...'),
                    SizedBox(height: 16),
                  ])
                else if (errorMsg != null)
                  Text(errorMsg!, style: const TextStyle(color: Colors.red))
                else ...[
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(transcript!,
                          style: Theme.of(ctx).textTheme.bodySmall),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final persistedPath =
                            await _persistClipAudioFile(filePath);
                        await _db.episodeClipsDao.insertClip(
                          EpisodeClipsCompanion.insert(
                            episodeId: widget.episodeId,
                            memoType: const drift.Value(AudioMemoType.file),
                            audioFilePath: drift.Value(persistedPath),
                            transcript: drift.Value(transcript),
                            clipText: drift.Value(transcript ?? ''),
                          ),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.listening,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('保存'),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('キャンセル'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRecordingMemoSheet() async {
    await _player?.stop();
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordingMemoScreen(episodeId: widget.episodeId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _sendClipToModule(EpisodeClip clip) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'どのモジュールに送りますか？',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModuleChip(
                  label: 'クリップボードにコピー',
                  icon: Icons.copy,
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: clip.clipText));
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('コピーしました')),
                      );
                    }
                  },
                ),
                _ModuleChip(
                  label: '辞書に追加',
                  icon: Icons.menu_book_outlined,
                  onTap: () {
                    // TODO: 辞書連携
                    Navigator.pop(ctx);
                  },
                ),
                _ModuleChip(
                  label: '思考メモに追加',
                  icon: Icons.scatter_plot_outlined,
                  onTap: () {
                    // TODO: 思考モジュール連携
                    Navigator.pop(ctx);
                  },
                ),
                _ModuleChip(
                  label: '日常メモに追加',
                  icon: Icons.edit_note,
                  onTap: () {
                    // TODO: 日常メモ連携
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEpisode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('エピソードを削除'),
        content: const Text('このエピソードとすべてのクリップを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _db.episodeClipsDao
        .deleteClipsByEpisode(widget.episodeId);
    await _db.podcastEpisodesDao.deleteEpisode(widget.episodeId);
    if (mounted) Navigator.of(context).pop();
  }

  // ─── 再生コントロール ────────────────────────────────────

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _episode == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('音声記録')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final ep = _episode!;
    final hasAudio = ep.audioFilePath != null &&
        File(ep.audioFilePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: _editMode
            ? const Text('編集中')
            : Text(ep.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (_editMode) ...[
            TextButton(
              onPressed: () => setState(() => _editMode = false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: _saveEdit,
              child: const Text('保存'),
            ),
          ] else ...[
            if (_aiLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2)),
              ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    setState(() => _editMode = true);
                    break;
                  case 'summary':
                    _generateSummary();
                    break;
                  case 'structure':
                    _generateStructuredNotes();
                    break;
                  case 'memo':
                    _showAddMemoBottomSheet();
                    break;
                  case 'delete':
                    _deleteEpisode();
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('編集')),
                const PopupMenuItem(
                    value: 'summary', child: Text('AI全体要約を生成')),
                const PopupMenuItem(
                    value: 'structure', child: Text('AI全体分析を生成')),
                const PopupMenuItem(
                    value: 'memo', child: Text('音声記録メモを追加')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('削除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.listening,
          unselectedLabelColor:
              theme.colorScheme.secondary.withValues(alpha: 0.5),
          indicatorColor: AppPalette.listening,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: '情報'),
            const Tab(text: 'トランスクリプト'),
            Tab(text: '音声記録メモ (${_clips.length})'),
            const Tab(text: 'AI全体要約'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 音声プレーヤー（音声ファイルがある場合のみ）
          if (hasAudio)
            _AudioPlayer(
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              onPlayPause: () {
                if (_isPlaying) {
                  _player?.pause();
                } else {
                  _initPlayer();
                  _player?.play();
                }
              },
              onSeek: (pos) => _player?.seek(pos),
              formatDuration: _formatDuration,
            ),
          if (!hasAudio && ep.audioFilePath != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'この音声記録の元ファイルが見つかりません。過去の一時保存ファイルを参照していた可能性があります。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange[900],
                  height: 1.6,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ─ 情報
                _InfoTab(
                  episode: ep,
                  editMode: _editMode,
                  theme: theme,
                  titleController: _titleController,
                  programController: _programController,
                  speakerController: _speakerController,
                  genreController: _genreController,
                  publishedDateController: _publishedDateController,
                  sourceUrlController: _sourceUrlController,
                  relatedUrlController: _relatedUrlController,
                  ratingController: _ratingController,
                  synopsisController: _synopsisController,
                  reviewSummaryController: _reviewSummaryController,
                ),
                // ─ トランスクリプト
                _hasTranscript
                    ? _TranscriptTab(
                        episode: ep,
                        editMode: _editMode,
                        controller: _transcriptController,
                        onAddClip: _addClip,
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notes_outlined,
                                size: 56,
                                color: theme.colorScheme.secondary
                                    .withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'トランスクリプトはまだありません',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '録音メモの文字起こしや、音声ファイルの文字起こしを追加するとここに表示されます。',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                // ─ 音声記録メモ
                _ClipsTab(
                  clips: _clips,
                  episodeTitle: ep.title,
                  programName: ep.programName,
                  onAdd: _showAddMemoBottomSheet,
                  onSendTo: _sendClipToModule,
                  onDelete: (clip) async {
                    await _db.episodeClipsDao.deleteClip(clip.id);
                    _load();
                  },
                ),
                // ─ AI全体要約
                _SummaryTab(
                  episode: ep,
                  editMode: _editMode,
                  summaryController: _summaryController,
                  aiLoading: _aiLoading,
                  selectedThinkingStyle: _selectedThinkingStyle,
                  onThinkingStyleChanged: (style) {
                    setState(() => _selectedThinkingStyle = style);
                  },
                  onGenerateSummary: _generateSummary,
                  onGenerateStructured: _generateStructuredNotes,
                  onAskQuestion: _askAboutEpisode,
                  questionHistory: _overallQaHistory,
                  questionEntries: _overallQaEntries,
                  onDeleteSummary: _deleteOverallSummary,
                  onDeleteAnalysis: _deleteOverallAnalysis,
                  onDeleteQuestion: _deleteQuestionEntry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 情報タブ ────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  final PodcastEpisode episode;
  final bool editMode;
  final ThemeData theme;
  final TextEditingController titleController;
  final TextEditingController programController;
  final TextEditingController speakerController;
  final TextEditingController genreController;
  final TextEditingController publishedDateController;
  final TextEditingController sourceUrlController;
  final TextEditingController relatedUrlController;
  final TextEditingController ratingController;
  final TextEditingController synopsisController;
  final TextEditingController reviewSummaryController;

  const _InfoTab({
    required this.episode,
    required this.editMode,
    required this.theme,
    required this.titleController,
    required this.programController,
    required this.speakerController,
    required this.genreController,
    required this.publishedDateController,
    required this.sourceUrlController,
    required this.relatedUrlController,
    required this.ratingController,
    required this.synopsisController,
    required this.reviewSummaryController,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd');

    if (editMode) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: programController,
              decoration: const InputDecoration(
                labelText: '番組名・チャンネル名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: speakerController,
              decoration: const InputDecoration(
                labelText: '話者・出演者',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: genreController,
              decoration: const InputDecoration(
                labelText: 'ジャンル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: publishedDateController,
              decoration: const InputDecoration(
                labelText: '配信日 (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sourceUrlController,
              decoration: const InputDecoration(
                labelText: 'ソースURL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relatedUrlController,
              decoration: const InputDecoration(
                labelText: '関連URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ratingController,
              decoration: const InputDecoration(
                labelText: '評価',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: synopsisController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'あらすじ・概要',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reviewSummaryController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'レビュー要約',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ソース種別バッジ + 登録日
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.listening, 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  episode.sourceType.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppPalette.listening,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '登録: ${fmt.format(episode.createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // タイトル
          Text(
            episode.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          // 番組名・チャンネル
          if (episode.programName != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.podcasts,
              label: '番組・チャンネル',
              value: episode.programName!,
              color: AppPalette.listening,
            ),
          ],

          // 話者・出演者
          if (episode.speaker != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.person_outline,
              label: '話者・出演者',
              value: episode.speaker!,
            ),
          ],

          // ジャンル
          if (episode.genre != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'ジャンル',
              value: episode.genre!,
            ),
          ],

          // 配信日
          if (episode.publishedAt != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: '配信日',
              value: fmt.format(episode.publishedAt!.toLocal()),
            ),
          ],

          // 再生時間
          if (episode.durationSeconds != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.timer_outlined,
              label: '再生時間',
              value: _fmtDuration(episode.durationSeconds!),
            ),
          ],

          // 評価
          if (episode.rating != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.star_outline,
              label: '評価',
              value: episode.rating!,
            ),
          ],

          // あらすじ・概要
          if (episode.synopsis != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'あらすじ・概要', theme: theme),
            const SizedBox(height: 8),
            Text(
              episode.synopsis!,
              style:
                  theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
          ],

          // レビュー要約
          if (episode.reviewSummary != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'レビュー要約', theme: theme),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.listening, 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                episode.reviewSummary!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
            ),
          ],

          // ソースURL
          if (episode.sourceUrl != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'ソースURL', theme: theme),
            const SizedBox(height: 6),
            _UrlTile(url: episode.sourceUrl!, theme: theme),
          ],

          // 関連URL
          if (episode.relatedUrl != null) ...[
            const SizedBox(height: 12),
            _SectionHeader(label: '関連URL', theme: theme),
            const SizedBox(height: 6),
            _UrlTile(url: episode.relatedUrl!, theme: theme),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmtDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h時間$m分$s秒';
    if (m > 0) return '$m分$s秒';
    return '$s秒';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 16,
            color: color ??
                theme.colorScheme.secondary.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: color != null ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: AppPalette.listening,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _UrlTile extends StatelessWidget {
  final String url;
  final ThemeData theme;

  const _UrlTile({required this.url, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) await launchUrl(uri);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.link, size: 16, color: AppPalette.listening),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                url,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.listening,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 音声プレーヤー ───────────────────────────────────────────

class _AudioPlayer extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final String Function(Duration) formatDuration;

  const _AudioPlayer({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: onPlayPause,
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: AppPalette.listening,
              size: 36,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12),
                    activeTrackColor: AppPalette.listening,
                    inactiveTrackColor: AppPalette.soften(
                        AppPalette.listening, 0.7),
                    thumbColor: AppPalette.listening,
                    overlayColor:
                        AppPalette.listening.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) =>
                        onSeek(duration * v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(position),
                          style: theme.textTheme.labelSmall),
                      Text(formatDuration(duration),
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── トランスクリプトタブ ─────────────────────────────────────

class _TranscriptTab extends StatelessWidget {
  final PodcastEpisode episode;
  final bool editMode;
  final TextEditingController controller;
  final ValueChanged<String> onAddClip;

  const _TranscriptTab({
    required this.episode,
    required this.editMode,
    required this.controller,
    required this.onAddClip,
  });

  @override
  Widget build(BuildContext context) {
    if (episode.transcript == null || episode.transcript!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.text_fields,
                size: 48,
                color: AppPalette.listening.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'トランスクリプトがありません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (editMode) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(
      TextSpan(text: episode.transcript),
      contextMenuBuilder: (ctx, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        final buttonItems = editableTextState.contextMenuButtonItems;
        if (!selection.isCollapsed) {
          final selectedText = episode.transcript!.substring(
            selection.start.clamp(0, episode.transcript!.length),
            selection.end.clamp(0, episode.transcript!.length),
          );
          buttonItems.add(ContextMenuButtonItem(
            onPressed: () {
              onAddClip(selectedText);
              editableTextState.hideToolbar();
            },
            label: 'クリップに追加',
          ));
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.8,
          ),
      ),
    );
  }
}

// ─── クリップタブ ─────────────────────────────────────────────

class _ClipsTab extends StatelessWidget {
  final List<EpisodeClip> clips;
  final String episodeTitle;
  final String? programName;
  final VoidCallback onAdd;
  final ValueChanged<EpisodeClip> onSendTo;
  final ValueChanged<EpisodeClip> onDelete;

  const _ClipsTab({
    required this.clips,
    required this.episodeTitle,
    required this.programName,
    required this.onAdd,
    required this.onSendTo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (clips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_none,
              size: 48,
              color: AppPalette.listening.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '音声記録メモがありません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('音声記録メモを追加'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: clips.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == clips.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('音声記録メモを追加'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.listening,
                side: const BorderSide(color: AppPalette.listening),
              ),
            ),
          );
        }
        final clip = clips[i];
        final displayText = clip.transcript?.isNotEmpty == true
            ? clip.transcript!
            : clip.clipText;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EpisodeClipDetailScreen(
                    clipId: clip.id,
                    episodeTitle: episodeTitle,
                    programName: programName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppPalette.soften(AppPalette.listening, 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          clip.memoType.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppPalette.listening,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (clip.title != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clip.title!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (clip.durationSeconds != null)
                        Text(
                          _fmtSec(clip.durationSeconds!),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      const Icon(Icons.chevron_right, size: 16,
                          color: Colors.grey),
                    ],
                  ),
                  if (clip.timestampStr != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      clip.timestampStr!,
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppPalette.listening,
                              ),
                    ),
                  ],
                  if (displayText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      displayText,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (clip.note != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      clip.note!,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => onSendTo(clip),
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text('送る'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.listening,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => onDelete(clip),
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('削除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

String _fmtSec(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

// ─── AI要約タブ ───────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final PodcastEpisode episode;
  final bool editMode;
  final TextEditingController summaryController;
  final bool aiLoading;
  final ThinkingStyle selectedThinkingStyle;
  final ValueChanged<ThinkingStyle> onThinkingStyleChanged;
  final VoidCallback onGenerateSummary;
  final VoidCallback onGenerateStructured;
  final VoidCallback onAskQuestion;
  final List<String> questionHistory;
  final List<EpisodeAiEntry> questionEntries;
  final Future<void> Function() onDeleteSummary;
  final Future<void> Function() onDeleteAnalysis;
  final Future<void> Function(EpisodeAiEntry entry) onDeleteQuestion;

  const _SummaryTab({
    required this.episode,
    required this.editMode,
    required this.summaryController,
    required this.aiLoading,
    required this.selectedThinkingStyle,
    required this.onThinkingStyleChanged,
    required this.onGenerateSummary,
    required this.onGenerateStructured,
    required this.onAskQuestion,
    required this.questionHistory,
    required this.questionEntries,
    required this.onDeleteSummary,
    required this.onDeleteAnalysis,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: aiLoading ? null : onGenerateSummary,
                icon: aiLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: const Text('全体要約'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: aiLoading ? null : onGenerateStructured,
                icon: const Icon(Icons.format_list_bulleted, size: 16),
                label: const Text('分析'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.listening,
                  side: const BorderSide(color: AppPalette.listening),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: aiLoading ? null : onAskQuestion,
                icon: const Icon(Icons.question_answer_outlined, size: 16),
                label: const Text('質問'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.listening,
                  side: const BorderSide(color: AppPalette.listening),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('思考キャラクター',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppPalette.listening,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<ThinkingStyle>(
              value: selectedThinkingStyle,
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
                  onThinkingStyleChanged(style);
                }
              },
            ),
          ),
          if (episode.summary != null &&
              episode.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('全体要約',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppPalette.listening,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            editMode
                ? TextField(
                    controller: summaryController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.soften(AppPalette.listening, 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: onDeleteSummary,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: '削除',
                          ),
                        ),
                        Text(
                          episode.summary!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
          ],
          if (episode.structuredNotes != null &&
              episode.structuredNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('構造化メモ',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppPalette.listening,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.listening, 0.93),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: onDeleteAnalysis,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '削除',
                    ),
                  ),
                  Text(
                    episode.structuredNotes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.7,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (questionHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('質問履歴',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppPalette.listening,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            for (final entry in questionEntries.reversed)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.listening, 0.95),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => onDeleteQuestion(entry),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                      ),
                    ),
                    Text(
                      entry.content,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),
          ],
          if ((episode.summary == null || episode.summary!.isEmpty) &&
              (episode.structuredNotes == null ||
                  episode.structuredNotes!.isEmpty) &&
              questionHistory.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: AppPalette.listening.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AIでコンテンツ全体を要約・分析・質問できます',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── モジュール送信チップ ────────────────────────────────────

class _ModuleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppPalette.listening),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppPalette.soften(AppPalette.listening, 0.88),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppPalette.listening,
          ),
      side: BorderSide.none,
    );
  }
}

// ─── メモ種別選択ボタン ────────────────────────────────────────

class _MemoTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MemoTypeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
