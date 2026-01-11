import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_palette.dart';
import '../../core/utils/image_ocr_helper.dart';
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
  bool _isScanning = false;

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

  Future<void> _scanImageForContent() async {
    setState(() => _isScanning = true);

    try {
      final result = await ImageOcrHelper.pickCropAndRecognize(
        context: context,
        cropEnabled: true,
      );

      if (result == null || !mounted) {
        setState(() => _isScanning = false);
        return;
      }

      if (!result.hasText) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('テキストが検出されませんでした')),
          );
        }
        setState(() => _isScanning = false);
        return;
      }

      _contentController.text = result.recognizedText.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テキストを読み込みました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
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
            SurfaceField(
              label: '内容',
              hintText: '即時的・断片的なメモ...',
              controller: _contentController,
              maxLines: 20,
              alignLabelWithHint: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt),
                tooltip: '画像から読み取り',
                onPressed: _isScanning ? null : _scanImageForContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
