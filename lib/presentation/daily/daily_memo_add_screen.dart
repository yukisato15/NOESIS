import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';
import '../shared/surface_field.dart';

class DailyMemoAddScreen extends StatefulWidget {
  final String? initialContent;

  const DailyMemoAddScreen({
    super.key,
    this.initialContent,
  });

  @override
  State<DailyMemoAddScreen> createState() => _DailyMemoAddScreenState();
}

class _DailyMemoAddScreenState extends State<DailyMemoAddScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isSaving = false;

  // Quote Capture用の画像管理
  XFile? _sourceImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null &&
        widget.initialContent!.trim().isNotEmpty) {
      _contentController.text = widget.initialContent!.trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _sourceImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _pickSourceImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _sourceImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の選択に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          _contentController.text = data.text!;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('クリップボードから貼り付けました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('貼り付けに失敗しました: $e')),
        );
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

    setState(() {
      _isSaving = true;
    });

    try {
      // タグをJSON配列に変換
      String? tagsJson;
      final tagsText = _tagsController.text.trim();
      if (tagsText.isNotEmpty) {
        final tagsList = tagsText
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (tagsList.isNotEmpty) {
          tagsJson = jsonEncode(tagsList);
        }
      }

      final now = DateTime.now();
      await _db.dailyMemosDao.createDailyMemo(
        DailyMemosCompanion(
          title: drift.Value(_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null),
          content: drift.Value(_contentController.text.trim()),
          category: drift.Value(_categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim()),
          tags: drift.Value(tagsJson),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('処理に失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('日常メモ追加'),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemo,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.daily, 0.88),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppPalette.daily.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: AppPalette.daily),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '即時的・断片的なメモを記録。\n後で他のアーカイブへ整理できます。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'メタ情報',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: 'タイトル（任意）',
                    hintText: '例: 会議メモ、アイデア',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: 'カテゴリ/ジャンル（任意）',
                    hintText: '例: 仕事、プライベート、学習',
                    controller: _categoryController,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: 'タグ（任意）',
                    hintText: 'カンマ区切りで入力: タグ1, タグ2, タグ3',
                    controller: _tagsController,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 内容入力（メイン）
            SurfaceField(
              label: '内容',
              hintText: '即時的・断片的なメモ...',
              controller: _contentController,
              maxLines: 20,
              alignLabelWithHint: true,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'カメラで撮影',
                    onPressed: _takePhoto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    tooltip: 'ギャラリーから選択',
                    onPressed: _pickSourceImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_paste),
                    tooltip: 'クリップボードから貼り付け',
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 画像プレビュー（撮影後のみ表示）
            if (_sourceImage != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '撮影した画像',
                            style: theme.textTheme.titleSmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _sourceImage = null;
                              });
                            },
                            tooltip: '画像を削除',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '※ 2本指でズーム → 画像を長押しして範囲選択 → コピー → 上の貼り付けボタン',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LiveTextImageView(
                          imagePath: _sourceImage!.path,
                          height: 400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
