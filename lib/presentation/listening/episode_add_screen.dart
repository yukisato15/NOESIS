import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:record/record.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/listening_audio_storage.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/podcast_episodes_table.dart';

class EpisodeAddScreen extends StatefulWidget {
  const EpisodeAddScreen({super.key});

  @override
  State<EpisodeAddScreen> createState() => _EpisodeAddScreenState();
}

class _EpisodeAddScreenState extends State<EpisodeAddScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppDatabase _db = AppDatabase();

  // 共通
  final _titleController = TextEditingController();
  final _programController = TextEditingController();
  final _speakerController = TextEditingController();

  // URL タブ
  final _urlController = TextEditingController();
  bool _urlLoading = false;
  String? _urlTranscript;
  String? _urlError;
  String? _urlInfo; // 情報メッセージ（青色表示）

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
  final _textTranscriptController = TextEditingController();

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
    _programController.dispose();
    _speakerController.dispose();
    _urlController.dispose();
    _textTranscriptController.dispose();
    _recorder?.dispose();
    super.dispose();
  }

  // ─── URL処理 ────────────────────────────────────────────

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
      } else if (_isSpotifyUrl(url)) {
        if (mounted) {
          setState(() => _urlError =
              'SpotifyのURLは直接トランスクリプトを取得できません。\n\n'
              '【対処法】\n'
              '① Spotifyアプリでエピソードを開き、表示されているトランスクリプトを全選択してコピー → 「テキスト」タブに貼り付け\n'
              '② または音声ファイルを「ファイル」タブからインポートしてWhisperで文字起こし');
        }
      } else {
        // ポッドキャストRSS / 音声URLとして処理
        await _processPodcastUrl(url);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _urlError = 'エラーが発生しました: $e');
      }
    } finally {
      if (mounted) setState(() => _urlLoading = false);
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  bool _isSpotifyUrl(String url) {
    return url.contains('spotify.com') ||
        url.contains('open.spotify') ||
        url.contains('spotify.link');
  }

  Future<void> _processYouTubeUrl(String url) async {
    final videoId = _extractYouTubeVideoId(url);
    if (videoId == null) {
      if (mounted) {
        setState(() => _urlError = 'YouTubeのビデオIDを取得できませんでした。URLを確認してください。');
      }
      return;
    }

    try {
      // 動画ページをデスクトップUAで取得（モバイルUAだと字幕データが少ない）
      final pageRes = await http.get(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'ja,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 15));
      final body = pageRes.body;

      // タイトルを抽出
      if (_titleController.text.isEmpty) {
        final titleMatch = RegExp(r'"title":"([^"]+)"').firstMatch(body);
        if (titleMatch != null) {
          _titleController.text = _unescapeJson(titleMatch.group(1)!);
        }
      }

      // チャンネル名を抽出
      if (_programController.text.isEmpty) {
        final channelMatch = RegExp(r'"author":"([^"]+)"').firstMatch(body);
        if (channelMatch != null) {
          _programController.text = _unescapeJson(channelMatch.group(1)!);
        }
      }

      // タイトル・チャンネル名の取得完了を通知
      if (mounted) {
        setState(() => _urlInfo =
            'タイトルと番組名を取得しました。\n\n'
            'YouTubeの字幕は認証が必要なため自動取得できません。\n\n'
            '【文字起こしの貼り付け方法】\n'
            '① YouTubeアプリで動画を開く\n'
            '② 動画下の「…」→「文字起こしを開く」\n'
            '③ テキストを全選択してコピー\n'
            '④「テキスト」タブに貼り付けて保存');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _urlError =
            'ページの取得に失敗しました。\nネットワーク接続を確認してください。');
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    // youtu.be/VIDEO_ID 形式
    final shortMatch =
        RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);
    // youtube.com/watch?v=VIDEO_ID 形式
    final longMatch =
        RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url);
    if (longMatch != null) return longMatch.group(1);
    return null;
  }

  String _unescapeJson(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\"', '"');
  }

  Future<void> _processPodcastUrl(String url) async {
    // RSSフィードかどうか確認
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0'},
    );
    final body = response.body;

    // Spotifyへのリダイレクト先を確認
    final finalUrl = response.request?.url.toString() ?? url;
    if (_isSpotifyUrl(finalUrl)) {
      if (mounted) {
        setState(() => _urlError =
            'SpotifyのURLは直接トランスクリプトを取得できません。\n\n'
            '【対処法】\n'
            '① Spotifyアプリでエピソードを開き、表示されているトランスクリプトを全選択してコピー → 「テキスト」タブに貼り付け\n'
            '② または音声ファイルを「ファイル」タブからインポートしてWhisperで文字起こし');
      }
      return;
    }

    // XMLでなければ早期リターン
    if (!body.trimLeft().startsWith('<')) {
      if (mounted) {
        setState(() => _urlError =
            'このURLはRSSフィードではありません。\n「テキスト」タブにトランスクリプトを貼り付けるか、「ファイル」タブから音声ファイルをインポートしてください。');
      }
      return;
    }

    // podcast:transcript タグを探す
    final transcriptMatch = RegExp(
      r'<podcast:transcript[^>]+url="([^"]+)"',
    ).firstMatch(body);

    if (transcriptMatch != null) {
      final transcriptUrl = transcriptMatch.group(1)!;
      final transcriptRes = await http.get(Uri.parse(transcriptUrl));
      if (mounted) {
        setState(() => _urlTranscript = transcriptRes.body);
      }
      return;
    }

    // RSSのtitleを自動補完
    final titleMatch = RegExp(r'<title>([^<]+)</title>').firstMatch(body);
    if (titleMatch != null && _titleController.text.isEmpty) {
      _titleController.text = titleMatch.group(1) ?? '';
    }

    if (mounted) {
      setState(() => _urlError =
          'このURLからは自動でトランスクリプトを取得できませんでした。\n「テキスト」タブに貼り付けるか、音声ファイルを「ファイル」タブから取り込んでください。');
    }
  }

  // ─── ファイル処理 ────────────────────────────────────────

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedFilePath = result.files.first.path);
  }

  Future<void> _transcribeFile() async {
    if (_selectedFilePath == null) return;
    setState(() {
      _fileLoading = true;
      _fileError = null;
      _fileTranscript = null;
    });
    try {
      final transcription =
          await OpenAI.instance.audio.createTranscription(
        file: File(_selectedFilePath!),
        model: 'whisper-1',
        language: 'ja',
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      if (mounted) {
        setState(() => _fileTranscript = transcription.text);
        if (_titleController.text.isEmpty) {
          final fileName = _selectedFilePath!.split('/').last;
          _titleController.text =
              fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _fileError = 'Whisper APIエラー: $e');
    } finally {
      if (mounted) setState(() => _fileLoading = false);
    }
  }

  // ─── 録音処理 ────────────────────────────────────────────

  Future<void> _startRecording() async {
    String? path;
    try {
      _recorder ??= AudioRecorder();
      final hasPermission = await _recorder!
          .hasPermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('マイクのアクセス許可が必要です。設定アプリから許可してください。')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      final transcription = await OpenAI.instance.audio.createTranscription(
        file: File(_recordingPath!),
        model: 'whisper-1',
        language: 'ja',
        responseFormat: OpenAIAudioResponseFormat.json,
      );
      if (mounted) setState(() => _recordingTranscript = transcription.text);
    } catch (e) {
      if (mounted) setState(() => _recordingError = 'Whisper APIエラー: $e');
    } finally {
      if (mounted) setState(() => _recordingLoading = false);
    }
  }

  // ─── 保存 ────────────────────────────────────────────────

  String? _getActiveTranscript() {
    switch (_tabController.index) {
      case 0:
        return _urlTranscript;
      case 1:
        return _fileTranscript;
      case 2:
        return _recordingTranscript;
      case 3:
        return _textTranscriptController.text.trim().isEmpty
            ? null
            : _textTranscriptController.text.trim();
    }
    return null;
  }

  EpisodeSourceType _getSourceType() {
    switch (_tabController.index) {
      case 0:
        return _isYouTubeUrl(_urlController.text.trim())
            ? EpisodeSourceType.youtube
            : EpisodeSourceType.podcast;
      case 1:
        return EpisodeSourceType.file;
      case 2:
        return EpisodeSourceType.recording;
      case 3:
        return EpisodeSourceType.text;
    }
    return EpisodeSourceType.text;
  }

  Future<String?> _persistEpisodeAudioPath() async {
    final inputPath = _selectedFilePath ?? _recordingPath;
    if (inputPath == null || inputPath.isEmpty) return null;
    final prefix = _tabController.index == 2 ? 'episode_recording' : 'episode_file';
    return ListeningAudioStorage.persistAudioFile(
      inputPath,
      folderName: 'listening_audio',
      prefix: prefix,
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }
    final transcript = _getActiveTranscript();
    setState(() => _saving = true);
    try {
      final persistedAudioPath = await _persistEpisodeAudioPath();
      await _db.podcastEpisodesDao.insertEpisode(
        PodcastEpisodesCompanion.insert(
          title: title,
          sourceType: drift.Value(_getSourceType()),
          sourceUrl: drift.Value(_urlController.text.trim().isEmpty
              ? null
              : _urlController.text.trim()),
          programName: drift.Value(_programController.text.trim().isEmpty
              ? null
              : _programController.text.trim()),
          speaker: drift.Value(_speakerController.text.trim().isEmpty
              ? null
              : _speakerController.text.trim()),
          transcript: drift.Value(transcript),
          audioFilePath: drift.Value(persistedAudioPath),
        ),
      );
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('音声記録を追加'),
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
            TextButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
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
          // 共通フィールド
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル *',
                    hintText: 'エピソードのタイトル',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _programController,
                        decoration: const InputDecoration(
                          labelText: '番組名',
                          hintText: '例: ゆる言語学ラジオ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _speakerController,
                        decoration: const InputDecoration(
                          labelText: '話者',
                          hintText: '例: 水野・堀元',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                  onPickFile: _pickAudioFile,
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
                _TextTab(
                  controller: _textTranscriptController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── URLタブ ─────────────────────────────────────────────────

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
                    suffixIcon: urlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => urlController.clear(),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: loading ? null : onProcess,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
                    child: Text(
                      info!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800],
                            height: 1.6,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[800],
                    ),
              ),
            ),
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

// ─── ファイルタブ ─────────────────────────────────────────────

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
                backgroundColor: AppPalette.listening,
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

// ─── 録音タブ ─────────────────────────────────────────────────

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

  String _formatDuration(Duration d) {
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
              Icon(Icons.mic_off, size: 48,
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)),
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
            'マイクで録音し、Whisperで自動文字起こしします',
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
            Text(
              _formatDuration(duration),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '録音中... タップして停止',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
          ] else if (hasRecording) ...[
            Text(
              '録音完了 (${_formatDuration(duration)})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.listening,
                    fontWeight: FontWeight.w500,
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
                backgroundColor: AppPalette.listening,
              ),
            ),
          ] else ...[
            Text(
              'タップして録音開始',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.6),
                  ),
            ),
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

// ─── テキストタブ ─────────────────────────────────────────────

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
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7),
                          ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    controller.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.paste, size: 16),
                label: const Text('貼り付け'),
                style: TextButton.styleFrom(
                  foregroundColor: AppPalette.listening,
                ),
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

// ─── 共通ウィジェット ─────────────────────────────────────────

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
            const Icon(Icons.check_circle,
                color: Colors.green, size: 16),
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
            border:
                Border.all(color: Colors.green.withValues(alpha: 0.2)),
          ),
          child: SingleChildScrollView(
            child: Text(
              transcript,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.5),
            ),
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
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red[800],
            ),
      ),
    );
  }
}
