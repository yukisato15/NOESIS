import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/listening_audio_storage.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/episode_clips_table.dart';

/// 録音メモ画面（イン点・アウト点付き）
class RecordingMemoScreen extends StatefulWidget {
  final int episodeId;

  const RecordingMemoScreen({super.key, required this.episodeId});

  @override
  State<RecordingMemoScreen> createState() => _RecordingMemoScreenState();
}

class _RecordingMemoScreenState extends State<RecordingMemoScreen> {
  static const _audioEditingChannel =
      MethodChannel('noesis_flutter/audio_editing');
  static const _segmentSplitDuration = Duration(minutes: 40);

  final AppDatabase _db = AppDatabase();
  AudioRecorder? _recorder;
  AudioPlayer? _player; // 録音完了後にのみ生成（起動時点では音声セッションを取らない）
  final _noteCtrl = TextEditingController();

  // 録音状態
  bool _isRecording = false;
  String? _activeRecordingPath;
  String? _playbackPath;
  final List<String> _recordingSegmentPaths = [];
  Duration _recordingDuration = Duration.zero;
  Duration _currentSegmentDuration = Duration.zero;
  bool _isRollingSegment = false;

  // 再生・レンジ状態
  Duration _totalDuration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  RangeValues _range = const RangeValues(0.0, 1.0);
  Timer? _previewStopTimer;

  // 文字起こし
  bool _transcribing = false;
  String? _transcript;
  String? _transcriptError;

  bool _saving = false;

  void _initPlayer() {
    if (_player != null) return;
    _player = AudioPlayer();
    _player!.positionStream.listen((p) {
      final endMs = (_totalDuration.inMilliseconds * _range.end).round();
      if (_isPlaying &&
          endMs > 0 &&
          p.inMilliseconds >= endMs &&
          !_isRecording) {
        _player!.pause();
      }
      if (mounted) setState(() => _position = p);
    });
    _player!.durationStream.listen((d) {
      if (mounted) setState(() => _totalDuration = d ?? Duration.zero);
    });
    _player!.playingStream.listen((v) {
      if (mounted) setState(() => _isPlaying = v);
    });
    _player!.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _player!.pause();
        _player!.seek(Duration.zero);
      }
    });
  }

  @override
  void dispose() {
    _previewStopTimer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    _noteCtrl.dispose();
    _db.close();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtSecs(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  Future<String> _buildTempRecordingPath(int index) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/memo_rec_${DateTime.now().millisecondsSinceEpoch}_$index.m4a';
  }

  Future<void> _startRecorderAt(String path) {
    return _recorder!
        .start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 22050,
            numChannels: 1,
            iosConfig: IosRecordConfig(
              // ignore: deprecated_member_use
              manageAudioSession: false,
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
  }

  Future<void> _startRecording() async {
    try {
      _recorder ??= AudioRecorder();
      final hasPerm = await _recorder!
          .hasPermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('マイクのアクセス許可が必要です')),
          );
        }
        return;
      }
      final path = await _buildTempRecordingPath(0);

      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration.speech().copyWith(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ),
      );
      await session.setActive(true);

      await _startRecorderAt(path);
      setState(() {
        _isRecording = true;
        _activeRecordingPath = path;
        _playbackPath = null;
        _recordingSegmentPaths
          ..clear()
          ..add(path);
        _recordingDuration = Duration.zero;
        _currentSegmentDuration = Duration.zero;
        _totalDuration = Duration.zero;
        _position = Duration.zero;
        _range = const RangeValues(0.0, 1.0);
        _transcript = null;
        _transcriptError = null;
      });
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_isRecording) return false;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
          _currentSegmentDuration += const Duration(seconds: 1);
        });
        if (_currentSegmentDuration >= _segmentSplitDuration &&
            !_isRollingSegment) {
          await _rollToNextSegment();
        }
        return _isRecording;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('録音開始失敗: $e')));
      }
    }
  }

  Future<void> _rollToNextSegment() async {
    if (_activeRecordingPath == null || _isRollingSegment) return;
    _isRollingSegment = true;
    try {
      await _recorder?.stop().timeout(const Duration(seconds: 5));
      final nextPath =
          await _buildTempRecordingPath(_recordingSegmentPaths.length);
      await _startRecorderAt(nextPath);
      if (!mounted) return;
      setState(() {
        _activeRecordingPath = nextPath;
        _recordingSegmentPaths.add(nextPath);
        _currentSegmentDuration = Duration.zero;
      });
    } finally {
      _isRollingSegment = false;
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder?.stop().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isRecording = false);

    await _preparePlaybackSource();
  }

  Future<void> _transcribe() async {
    if (_recordingSegmentPaths.isEmpty) return;
    setState(() {
      _transcribing = true;
      _transcript = null;
      _transcriptError = null;
    });
    try {
      final buffers = <String>[];
      for (var i = 0; i < _recordingSegmentPaths.length; i++) {
        final path = _recordingSegmentPaths[i];
        final r = await OpenAI.instance.audio.createTranscription(
          file: File(path),
          model: 'whisper-1',
          language: 'ja',
          responseFormat: OpenAIAudioResponseFormat.json,
        );
        final text = r.text.trim();
        if (text.isEmpty) continue;
        if (_recordingSegmentPaths.length == 1) {
          buffers.add(text);
        } else {
          buffers.add('【パート${i + 1}】\n$text');
        }
      }
      if (mounted) setState(() => _transcript = buffers.join('\n\n'));
    } catch (e) {
      if (mounted) setState(() => _transcriptError = 'Whisper APIエラー: $e');
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  Future<String> _persistRecordingFile(String inputPath) async {
    return ListeningAudioStorage.persistAudioFile(
      inputPath,
      folderName: 'listening_memos',
      prefix: 'memo',
    );
  }

  Future<String> _buildTempMergedPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/memo_merge_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<String?> _mergeSegmentsToPath(
    List<String> inputPaths,
    String outputPath,
  ) async {
    try {
      final result = await _audioEditingChannel.invokeMethod<String>(
        'mergeAudioSegments',
        {
          'inputPaths': inputPaths,
          'outputPath': outputPath,
        },
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _trimAudio(String inputPath, int startSec, int endSec) async {
    final outputPath = await ListeningAudioStorage.buildManagedPath(
      folderName: 'listening_memos',
      prefix: 'memo_trim',
    );
    try {
      final result = await _audioEditingChannel.invokeMethod<String>(
        'trimAudio',
        {
          'inputPath': inputPath,
          'outputPath': outputPath,
          'startSeconds': startSec.toDouble(),
          'endSeconds': endSec.toDouble(),
        },
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _preparePlaybackSource() async {
    if (_recordingSegmentPaths.isEmpty) return;
    try {
      final playbackPath = _recordingSegmentPaths.length == 1
          ? _recordingSegmentPaths.first
          : await _mergeSegmentsToPath(
              _recordingSegmentPaths,
              await _buildTempMergedPath(),
            );
      if (playbackPath == null) {
        throw Exception('録音セグメントの結合に失敗しました');
      }
      _playbackPath = playbackPath;
      _initPlayer();
      await _player!.setFilePath(playbackPath);
      if (!mounted) return;
      setState(() => _range = const RangeValues(0.0, 1.0));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('録音プレビューの準備に失敗しました: $e')),
      );
    }
  }

  Future<void> _save() async {
    final totalSec = _totalDuration.inSeconds;
    final startSec = (totalSec * _range.start).round();
    final endSec = (totalSec * _range.end).round();
    final clippedSec = endSec - startSec;
    final tsStr = totalSec > 0
        ? '${_fmtSecs(startSec)} - ${_fmtSecs(endSec)}'
        : null;
    final note = _noteCtrl.text.trim();

    if (_transcript == null && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文字起こしかメモのいずれかが必要です')),
      );
      return;
    }
    if (totalSec > 0 && clippedSec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イン点とアウト点の範囲が不正です')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_playbackPath == null) {
        throw Exception('録音ファイルが見つかりません');
      }

      String savedPath;
      if (totalSec > 0 &&
          (_range.start > 0.005 || _range.end < 0.995) &&
          _playbackPath != null) {
        final trimmed = await _trimAudio(_playbackPath!, startSec, endSec);
        if (trimmed == null) {
          throw Exception('録音ファイルのトリミングに失敗しました');
        }
        savedPath = trimmed;
      } else {
        savedPath = await _persistRecordingFile(_playbackPath!);
      }

      await _db.ensureEpisodeClipsColumns();
      await _db.episodeClipsDao.insertClip(
        EpisodeClipsCompanion.insert(
          episodeId: widget.episodeId,
          memoType: const drift.Value(AudioMemoType.recording),
          audioFilePath: drift.Value(savedPath),
          durationSeconds: drift.Value(
              clippedSec > 0 ? clippedSec : (totalSec > 0 ? totalSec : null)),
          transcript: drift.Value(_transcript),
          note: drift.Value(note.isEmpty ? null : note),
          timestampStr: drift.Value(tsStr),
          clipText: drift.Value(_transcript ?? note),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewTrimHandle({
    required double previousStart,
    required double previousEnd,
    required RangeValues nextRange,
  }) async {
    if (_player == null || _totalDuration == Duration.zero) return;

    final movedStart = (nextRange.start - previousStart).abs() >
        (nextRange.end - previousEnd).abs();
    final ratio = movedStart ? nextRange.start : nextRange.end;
    final targetMs = (_totalDuration.inMilliseconds * ratio).round();
    final previewStartMs = movedStart
        ? (targetMs - 350).clamp(0, _totalDuration.inMilliseconds)
        : (targetMs - 900).clamp(0, _totalDuration.inMilliseconds);
    final previewEndMs = movedStart
        ? (previewStartMs + 1200).clamp(0, _totalDuration.inMilliseconds)
        : (targetMs + 350).clamp(0, _totalDuration.inMilliseconds);

    _previewStopTimer?.cancel();
    await _player!.seek(Duration(milliseconds: previewStartMs));
    await _player!.play();
    _previewStopTimer = Timer(
      Duration(milliseconds: previewEndMs - previewStartMs),
      () async {
        if (!mounted) return;
        await _player?.pause();
        await _player?.seek(Duration(milliseconds: targetMs));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRecording = _playbackPath != null && !_isRecording;
    final totalSec = _totalDuration.inSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('録音メモ'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: (hasRecording && !_saving) ? _save : null,
              child: const Text('保存'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          // ─ 録音ボタン
          Center(
            child: GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red.withValues(alpha: 0.9)
                      : AppPalette.listening,
                  boxShadow: [
                    if (_isRecording)
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isRecording
                  ? '録音中 ${_fmt(_recordingDuration)}  （タップで停止）'
                  : hasRecording
                      ? '録音完了 ${_fmt(_recordingDuration)} / ${_recordingSegmentPaths.length}分割'
                      : 'タップして録音開始',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _isRecording ? Colors.red[700] : null,
              ),
            ),
          ),
          if (_isRecording && _recordingSegmentPaths.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '25MB対策で約${_segmentSplitDuration.inMinutes}分ごとに自動分割しています',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],

          // ─ 再生・イン/アウト点
          if (hasRecording && _totalDuration > Duration.zero) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: AppPalette.listening.withValues(alpha: 0.07),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '再生とトリム確認',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppPalette.listening,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            if (_isPlaying) {
                              _player?.pause();
                            } else {
                              final startMs =
                                  (_totalDuration.inMilliseconds * _range.start)
                                      .round();
                              _player?.seek(Duration(milliseconds: startMs));
                              _player?.play();
                            }
                          },
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          label: Text(_isPlaying ? '一時停止' : '範囲再生'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_fmt(_position)} / ${_fmt(_totalDuration)}',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _totalDuration.inMilliseconds > 0
                          ? (_position.inMilliseconds /
                                  _totalDuration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (v) {
                        final ms =
                            (_totalDuration.inMilliseconds * v).round();
                        _player?.seek(Duration(milliseconds: ms));
                      },
                      activeColor: AppPalette.listening,
                    ),
                    Row(
                      children: [
                        Text(
                          'イン/アウト点',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_fmtSecs((totalSec * _range.start).round())} ～ '
                          '${_fmtSecs((totalSec * _range.end).round())}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppPalette.listening,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: _range,
                      onChanged: (v) {
                        final previous = _range;
                        setState(() => _range = v);
                        _previewStopTimer?.cancel();
                        _previewStopTimer = Timer(
                          const Duration(milliseconds: 180),
                          () => _previewTrimHandle(
                            previousStart: previous.start,
                            previousEnd: previous.end,
                            nextRange: v,
                          ),
                        );
                      },
                      activeColor: AppPalette.listening,
                      inactiveColor:
                          AppPalette.listening.withValues(alpha: 0.2),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(Duration.zero),
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          _fmt(_totalDuration),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'スライダを動かすと、動かした端の前後を短く再生して位置を確認できます。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ─ 文字起こしボタン
          if (hasRecording) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _transcribing ? null : _transcribe,
              icon: _transcribing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.transcribe),
              label: Text(_transcribing ? '文字起こし中...' : 'Whisperで文字起こし'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.listening,
                side: const BorderSide(color: AppPalette.listening),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_transcriptError != null) ...[
              const SizedBox(height: 8),
              Text(_transcriptError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            if (_transcript != null) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(_transcript!,
                      style:
                          theme.textTheme.bodySmall?.copyWith(height: 1.6)),
                ),
              ),
            ],
          ],

          // ─ メモフィールド
          const SizedBox(height: 20),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '自分のメモ・感想（任意）',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_outlined, size: 18),
                tooltip: 'ペースト',
                onPressed: () async {
                  final d = await Clipboard.getData(Clipboard.kTextPlain);
                  if (d?.text != null) _noteCtrl.text = d!.text!;
                },
              ),
            ),
          ),

          // ─ 保存ボタン
          const SizedBox(height: 20),
          FilledButton(
            onPressed: (hasRecording && !_saving) ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.listening,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('保存',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
