import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/listening_audio_storage.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/episode_clips_table.dart';

/// 音声記録メモ追加画面（録音・ファイル・テキスト・URLから追加）
class AudioMemoAddScreen extends StatefulWidget {
  final int episodeId;
  final String episodeTitle;

  const AudioMemoAddScreen({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
  });

  @override
  State<AudioMemoAddScreen> createState() => _AudioMemoAddScreenState();
}

class _AudioMemoAddScreenState extends State<AudioMemoAddScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppDatabase _db = AppDatabase();

  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  // URL タブ
  final _urlController = TextEditingController();
  bool _urlLoading = false;
  String? _urlTranscript;
  String? _urlError;
  String? _urlInfo;

  // ファイルタブ
  String? _selectedFilePath;
  bool _fileLoading = false;
  String? _fileTranscript;
  String? _fileError;

  // 録音タブ
  AudioRecorder? _recorder;
  bool _isRecording = false;
  String? _recordingPath;
  bool _recordingLoading = false;
  String? _recordingTranscript;
  String? _recordingError;
  Duration _recordingDuration = Duration.zero;

  // テキストタブ
  final _textController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _db.close();
    _titleController.dispose();
    _noteController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  // ─── URL 処理 ─────────────────────────────────────────────────

  bool _isYouTubeUrl(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  Future<void> _processUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _urlLoading = true;
      _urlError = null;
      _urlInfo = null;
      _urlTranscript = null;
    });

    try {
      if (_isYouTubeUrl(url)) {
        await _processYouTubeUrl(url);
      } else {
        await _processPodcastUrl(url);
      }
    } catch (e) {
      if (mounted) setState(() => _urlError = 'エラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _urlLoading = false);
    }
  }

  Future<void> _processYouTubeUrl(String url) async {
    final videoId =
        RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url)?.group(1) ??
            RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url)?.group(1);

    if (videoId == null) {
      setState(() => _urlError = 'YouTubeのビデオIDを取得できませんでした。');
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept-Language': 'ja,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 15));

      String unescape(String s) => s
          .replaceAll(r'\n', ' ')
          .replaceAll(r'\u0026', '&')
          .replaceAll(r'\"', '"');

      if (_titleController.text.isEmpty) {
        final m = RegExp(r'"title":"([^"]+)"').firstMatch(res.body);
        if (m != null) _titleController.text = unescape(m.group(1)!);
      }

      if (mounted) {
        setState(() => _urlInfo =
            'YouTubeの字幕は認証が必要なため自動取得できません。\n\n'
            '【文字起こしの貼り付け方法】\n'
            '① YouTubeアプリで動画を開く\n'
            '② 動画下の「…」→「文字起こしを開く」\n'
            '③ テキストを全選択してコピー\n'
            '④「テキスト」タブに貼り付けて保存');
      }
    } catch (e) {
      setState(() => _urlError = 'ページの取得に失敗しました: $e');
    }
  }

  Future<void> _processPodcastUrl(String url) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 15));

    final body = res.body;
    if (!body.trimLeft().startsWith('<')) {
      setState(() => _urlError =
          'このURLからは自動取得できません。「テキスト」タブに貼り付けるか「ファイル」タブから音声ファイルをインポートしてください。');
      return;
    }

    final transcriptMatch = RegExp(
      r'<podcast:transcript[^>]+url="([^"]+)"',
    ).firstMatch(body);
    if (transcriptMatch != null) {
      final transcriptRes =
          await http.get(Uri.parse(transcriptMatch.group(1)!));
      if (mounted) setState(() => _urlTranscript = transcriptRes.body);
      return;
    }

    if (_titleController.text.isEmpty) {
      final m = RegExp(r'<title>([^<]+)</title>').firstMatch(body);
      if (m != null) _titleController.text = m.group(1)!.trim();
    }

    setState(() => _urlError =
        'このURLからは自動でトランスクリプトを取得できませんでした。「テキスト」タブに貼り付けてください。');
  }

  // ─── ファイル処理 ──────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFilePath = result.files.first.path;
      _fileTranscript = null;
      _fileError = null;
    });
  }

  Future<void> _transcribeFile() async {
    if (_selectedFilePath == null) return;
    setState(() {
      _fileLoading = true;
      _fileError = null;
      _fileTranscript = null;
    });
    try {
      final result = await OpenAI.instance.audio.createTranscription(
        file: File(_selectedFilePath!),
        model: 'whisper-1',
        language: 'ja',
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      if (mounted) setState(() => _fileTranscript = result.text);
    } catch (e) {
      if (mounted) setState(() => _fileError = 'Whisper APIエラー: $e');
    } finally {
      if (mounted) setState(() => _fileLoading = false);
    }
  }

  // ─── 録音処理 ──────────────────────────────────────────────────

  Future<void> _startRecording() async {
    String? path;
    try {
      _recorder ??= AudioRecorder();
      final hasPerm = await _recorder!
          .hasPermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('マイクのアクセス許可が必要です。設定アプリから許可してください。')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      path =
          '${dir.path}/memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder!
          .start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 64000,
              sampleRate: 22050,
              numChannels: 1,
              iosConfig: IosRecordConfig(
                categoryOptions: [
                  IosAudioCategoryOption.mixWithOthers,
                  IosAudioCategoryOption.defaultToSpeaker,
                  IosAudioCategoryOption.allowBluetooth,
                  IosAudioCategoryOption.allowBluetoothA2DP,
                ],
              ),
            ),
            path: path,
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('録音の開始に失敗しました: $e')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordingDuration = Duration.zero;
      _recordingError = null;
      _recordingTranscript = null;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() => _recordingDuration += const Duration(seconds: 1));
      return _isRecording;
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder?.stop().timeout(const Duration(seconds: 5));
    } catch (_) {}
    if (mounted) setState(() => _isRecording = false);
  }

  Future<void> _transcribeRecording() async {
    if (_recordingPath == null) return;
    setState(() {
      _recordingLoading = true;
      _recordingError = null;
      _recordingTranscript = null;
    });
    try {
      final result = await OpenAI.instance.audio.createTranscription(
        file: File(_recordingPath!),
        model: 'whisper-1',
        language: 'ja',
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      if (mounted) setState(() => _recordingTranscript = result.text);
    } catch (e) {
      if (mounted) setState(() => _recordingError = 'Whisper APIエラー: $e');
    } finally {
      if (mounted) setState(() => _recordingLoading = false);
    }
  }

  // ─── 保存 ──────────────────────────────────────────────────────

  String? _getTranscript() {
    switch (_tabController.index) {
      case 0:
        return _urlTranscript;
      case 1:
        return _fileTranscript;
      case 2:
        return _recordingTranscript;
      case 3:
        final t = _textController.text.trim();
        return t.isEmpty ? null : t;
    }
    return null;
  }

  AudioMemoType _getMemoType() {
    switch (_tabController.index) {
      case 0:
        return AudioMemoType.url;
      case 1:
        return AudioMemoType.file;
      case 2:
        return AudioMemoType.recording;
      case 3:
        return AudioMemoType.text;
    }
    return AudioMemoType.text;
  }

  String? _getAudioFilePath() {
    switch (_tabController.index) {
      case 1:
        return _selectedFilePath;
      case 2:
        return _recordingPath;
      default:
        return null;
    }
  }

  int? _getDurationSeconds() {
    if (_tabController.index == 2 && !_isRecording) {
      return _recordingDuration.inSeconds > 0
          ? _recordingDuration.inSeconds
          : null;
    }
    return null;
  }

  Future<String?> _persistAudioFilePath() async {
    final inputPath = _getAudioFilePath();
    if (inputPath == null || inputPath.isEmpty) return null;
    final prefix = _tabController.index == 2 ? 'memo_recording' : 'memo_file';
    return ListeningAudioStorage.persistAudioFile(
      inputPath,
      folderName: 'listening_audio',
      prefix: prefix,
    );
  }

  Future<void> _save() async {
    final transcript = _getTranscript();
    final note = _noteController.text.trim();
    if (transcript == null && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('文字起こしかメモのいずれかを入力してください')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final persistedAudioPath = await _persistAudioFilePath();
      await _db.ensureEpisodeClipsColumns();
      await _db.episodeClipsDao.insertClip(
        EpisodeClipsCompanion.insert(
          episodeId: widget.episodeId,
          title: drift.Value(_titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim()),
          memoType: drift.Value(_getMemoType()),
          audioFilePath: drift.Value(persistedAudioPath),
          durationSeconds: drift.Value(_getDurationSeconds()),
          transcript: drift.Value(transcript),
          note: drift.Value(note.isEmpty ? null : note),
          clipText: drift.Value(transcript ?? note),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '音声記録メモを追加',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('保存')),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppPalette.listening,
          unselectedLabelColor:
              theme.colorScheme.secondary.withValues(alpha: 0.5),
          indicatorColor: AppPalette.listening,
          tabs: const [
            Tab(icon: Icon(Icons.link), text: 'URL'),
            Tab(icon: Icon(Icons.audio_file_outlined), text: 'ファイル'),
            Tab(icon: Icon(Icons.mic_outlined), text: '録音'),
            Tab(icon: Icon(Icons.text_fields), text: 'テキスト'),
          ],
        ),
      ),
      body: Column(
        children: [
          // メモタイトル・ノート共通入力
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _MemoTextField(
                  controller: _titleController,
                  label: 'メモのタイトル（任意）',
                  hint: '例: 第1章の録音',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 8),
                _MemoTextField(
                  controller: _noteController,
                  label: '自分のメモ・感想',
                  hint: '気づいたこと、感想、要点など',
                  icon: Icons.edit_note,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _UrlTab(
                  urlController: _urlController,
                  loading: _urlLoading,
                  transcript: _urlTranscript,
                  error: _urlError,
                  info: _urlInfo,
                  onProcess: _processUrl,
                ),
                _FileTab(
                  filePath: _selectedFilePath,
                  loading: _fileLoading,
                  transcript: _fileTranscript,
                  error: _fileError,
                  onPickFile: _pickFile,
                  onTranscribe: _transcribeFile,
                ),
                _RecordingTab(
                  isRecording: _isRecording,
                  duration: _recordingDuration,
                  hasRecording: _recordingPath != null,
                  loading: _recordingLoading,
                  transcript: _recordingTranscript,
                  error: _recordingError,
                  onStart: _startRecording,
                  onStop: _stopRecording,
                  onTranscribe: _transcribeRecording,
                ),
                _TextTab(controller: _textController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Paste ボタン付きシンプルフィールド ───────────────────────────

class _MemoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _MemoTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: const Icon(Icons.content_paste_outlined, size: 18),
          tooltip: 'ペースト',
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) controller.text = data!.text!;
          },
        ),
      ),
    );
  }
}

// ─── URL タブ ────────────────────────────────────────────────────

class _UrlTab extends StatelessWidget {
  final TextEditingController urlController;
  final bool loading;
  final String? transcript;
  final String? error;
  final String? info;
  final VoidCallback onProcess;

  const _UrlTab({
    required this.urlController,
    required this.loading,
    required this.transcript,
    required this.error,
    required this.info,
    required this.onProcess,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YouTube・ポッドキャストのURLを貼り付けてください',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_outlined, size: 18),
                      tooltip: 'ペースト',
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) urlController.text = data!.text!;
                      },
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: loading ? null : onProcess,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('取得'),
              ),
            ],
          ),
          if (info != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(info!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800], height: 1.6)),
                  ),
                ],
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: error!),
          ],
          if (transcript != null) ...[
            const SizedBox(height: 12),
            _TranscriptPreview(transcript: transcript!),
          ],
        ],
      ),
    );
  }
}

// ─── ファイル タブ ────────────────────────────────────────────────

class _FileTab extends StatelessWidget {
  final String? filePath;
  final bool loading;
  final String? transcript;
  final String? error;
  final VoidCallback onPickFile;
  final VoidCallback onTranscribe;

  const _FileTab({
    required this.filePath,
    required this.loading,
    required this.transcript,
    required this.error,
    required this.onPickFile,
    required this.onTranscribe,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MP3・M4A・WAVなどの音声ファイルをWhisperで文字起こしします',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('音声ファイルを選択'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.listening,
              side: const BorderSide(color: AppPalette.listening),
            ),
          ),
          if (filePath != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.listening, 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.audio_file,
                      color: AppPalette.listening, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath!.split('/').last,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : onTranscribe,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.transcribe),
              label: Text(loading ? '文字起こし中...' : 'Whisperで文字起こし'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: error!),
          ],
          if (transcript != null) ...[
            const SizedBox(height: 12),
            _TranscriptPreview(transcript: transcript!),
          ],
        ],
      ),
    );
  }
}

// ─── 録音 タブ ────────────────────────────────────────────────────

class _RecordingTab extends StatelessWidget {
  final bool isRecording;
  final Duration duration;
  final bool hasRecording;
  final bool loading;
  final String? transcript;
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onTranscribe;

  const _RecordingTab({
    required this.isRecording,
    required this.duration,
    required this.hasRecording,
    required this.loading,
    required this.transcript,
    required this.error,
    required this.onStart,
    required this.onStop,
    required this.onTranscribe,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  @override
  Widget build(BuildContext context) {
    if (_isSimulator) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text('録音機能はiPhone実機でのみ使用できます',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'マイクで録音し、Whisperで自動文字起こしします\n（スピーカー再生中の音声もそのまま録音できます）',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: isRecording ? onStop : onStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? Colors.red.withValues(alpha: 0.9)
                    : AppPalette.listening,
                boxShadow: [
                  if (isRecording)
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isRecording) ...[
            Text(_fmt(duration),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('録音中... タップして停止',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red[700])),
          ] else if (hasRecording) ...[
            Text('録音完了 (${_fmt(duration)})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.listening,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : onTranscribe,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.transcribe),
              label: Text(loading ? '文字起こし中...' : 'Whisperで文字起こし'),
              style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening),
            ),
          ] else ...[
            Text('タップして録音開始',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.6))),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: error!),
          ],
          if (transcript != null) ...[
            const SizedBox(height: 16),
            _TranscriptPreview(transcript: transcript!),
          ],
        ],
      ),
    );
  }
}

// ─── テキスト タブ ─────────────────────────────────────────────────

class _TextTab extends StatelessWidget {
  final TextEditingController controller;

  const _TextTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'トランスクリプトを貼り付け、または手入力してください',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.7),
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final data =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) controller.text = data!.text!;
                },
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('貼り付け'),
                style: TextButton.styleFrom(
                    foregroundColor: AppPalette.listening),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'ここにトランスクリプトを入力...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 共通ウィジェット ──────────────────────────────────────────────

class _TranscriptPreview extends StatelessWidget {
  final String transcript;
  const _TranscriptPreview({required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 6),
            Text(
              'トランスクリプト取得成功（${transcript.length}文字）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: SingleChildScrollView(
            child: Text(transcript,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.6)),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Text(message,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.orange[800])),
    );
  }
}
