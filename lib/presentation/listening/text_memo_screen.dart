import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/episode_clips_table.dart';

/// テキスト入力メモ画面（スキャン・ペースト・手入力対応）
class TextMemoScreen extends StatefulWidget {
  final int episodeId;
  final String initialText;

  const TextMemoScreen({
    super.key,
    required this.episodeId,
    this.initialText = '',
  });

  @override
  State<TextMemoScreen> createState() => _TextMemoScreenState();
}

class _TextMemoScreenState extends State<TextMemoScreen> {
  late final TextEditingController _textCtrl;
  final TextEditingController _noteCtrl = TextEditingController();
  final AppDatabase _db = AppDatabase();
  bool _saving = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _noteCtrl.dispose();
    _db.close();
    super.dispose();
  }

  // ─── スキャン ──────────────────────────────────────────────

  Future<void> _scanFromCamera() async {
    await _pickAndRecognize(ImageSource.camera);
  }

  Future<void> _scanFromGallery() async {
    await _pickAndRecognize(ImageSource.gallery);
  }

  Future<void> _pickAndRecognize(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: source, imageQuality: 90);
      if (xfile == null || !mounted) return;

      setState(() => _scanning = true);

      final inputImage = InputImage.fromFilePath(xfile.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      try {
        final result = await recognizer.processImage(inputImage);
        final recognized = result.text.trim();
        if (recognized.isNotEmpty) {
          final current = _textCtrl.text;
          _textCtrl.text =
              current.isEmpty ? recognized : '$current\n$recognized';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('テキストを認識できませんでした')),
            );
          }
        }
      } finally {
        await recognizer.close();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('スキャン失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final current = _textCtrl.text;
      _textCtrl.text =
          current.isEmpty ? data!.text! : '$current\n${data!.text!}';
    }
  }

  // ─── 保存 ──────────────────────────────────────────────────

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    final note = _noteCtrl.text.trim();
    if (text.isEmpty && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テキストまたはメモを入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _db.ensureEpisodeClipsColumns();
      await _db.episodeClipsDao.insertClip(
        EpisodeClipsCompanion.insert(
          episodeId: widget.episodeId,
          memoType: const drift.Value(AudioMemoType.text),
          transcript: drift.Value(text.isEmpty ? null : text),
          note: drift.Value(note.isEmpty ? null : note),
          clipText: drift.Value(text.isEmpty ? note : text),
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

  // ─── UI ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('テキストメモ'),
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
            TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Column(
        children: [
          // スキャン・ペーストバー
          Container(
            color: AppPalette.soften(AppPalette.listening, 0.92),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _ScanButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'カメラ',
                  loading: _scanning,
                  onTap: _scanFromCamera,
                ),
                const SizedBox(width: 8),
                _ScanButton(
                  icon: Icons.photo_library_outlined,
                  label: 'ギャラリー',
                  loading: _scanning,
                  onTap: _scanFromGallery,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste_outlined, size: 16),
                  label: const Text('ペースト'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppPalette.listening),
                ),
              ],
            ),
          ),
          if (_scanning)
            LinearProgressIndicator(
              color: AppPalette.listening,
              backgroundColor: AppPalette.soften(AppPalette.listening, 0.85),
            ),

          // テキスト入力（メイン）
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _textCtrl,
                maxLines: null,
                expands: true,
                autofocus: widget.initialText.isEmpty,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'トランスクリプト・テキストを入力\n（スキャンで画像から自動認識も可能）',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
              ),
            ),
          ),

          // 自分のメモ欄
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 3,
              textAlignVertical: TextAlignVertical.top,
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
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _ScanButton({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: loading ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.listening,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
