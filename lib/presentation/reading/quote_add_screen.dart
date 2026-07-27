import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/text_normalizer.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';

/// Quote Capture画面
/// 書籍から引用したテキスト（ライブテキスト経由）を登録する
class QuoteAddScreen extends StatefulWidget {
  final int entryId;
  final String bookTitle;

  const QuoteAddScreen({
    super.key,
    required this.entryId,
    required this.bookTitle,
  });

  @override
  State<QuoteAddScreen> createState() => _QuoteAddScreenState();
}

class _QuoteAddScreenState extends State<QuoteAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteTextController = TextEditingController();
  final _sectionTitleController = TextEditingController();
  final _pageNumberController = TextEditingController();
  final _noteController = TextEditingController();
  final AppDatabase _db = AppDatabase();

  XFile? _sourceImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _quoteTextController.dispose();
    _sectionTitleController.dispose();
    _pageNumberController.dispose();
    _noteController.dispose();
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
          _quoteTextController.text = data.text!;
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

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // テキスト正規化
      final normalizedText =
          TextNormalizer.normalizeQuoteText(_quoteTextController.text);
      final normalizedSectionTitle =
          TextNormalizer.normalizeSectionTitle(_sectionTitleController.text);
      final normalizedPageNumber =
          TextNormalizer.normalizePageNumber(_pageNumberController.text);

      // データベースに保存（画像は保存しない）
      final noteText = _noteController.text.trim();
      await _db.quotesDao.insertQuote(
        QuotesCompanion.insert(
          entryId: widget.entryId,
          quoteText: normalizedText,
          sectionTitle: Value(normalizedSectionTitle),
          pageOrLoc: Value(normalizedPageNumber),
          note: Value(noteText.isEmpty ? null : noteText),
          sourceImagePath: const Value(null),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('引用メモを保存しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('引用メモを追加'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveQuote,
              tooltip: '保存',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 書籍名表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.book, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.bookTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 引用テキスト入力（メイン）
            TextFormField(
              controller: _quoteTextController,
              decoration: InputDecoration(
                labelText: '引用テキスト *',
                hintText: 'iOSライブテキストでコピーしたテキストを貼り付け',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
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
              maxLines: 10,
              minLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '引用テキストを入力してください';
                }
                return null;
              },
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
                            style: Theme.of(context).textTheme.titleSmall,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
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
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Text(
              '※ 貼り付け後、不要な改行や空白は自動で整形されます',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),

            // 小項目／小タイトル（任意）
            TextFormField(
              controller: _sectionTitleController,
              decoration: const InputDecoration(
                labelText: '小項目／章名（任意）',
                hintText: '例: 第1章 序論、導入部分など',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // ページ番号（任意）
            TextFormField(
              controller: _pageNumberController,
              decoration: const InputDecoration(
                labelText: 'ページ番号（任意）',
                hintText: '例: 123, p.45, 100-105',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.text,
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // 解釈メモ（任意）
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '解釈メモ（任意）',
                hintText: 'この引用に対するあなたの考察や気づき',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveQuote,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '引用メモを保存'),
            ),
          ],
        ),
      ),
    );
  }
}
