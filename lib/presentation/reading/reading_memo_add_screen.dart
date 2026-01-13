import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/text_normalizer.dart';
import '../../core/widgets/live_text_image_view.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/local/tables/reading_memos_table.dart';

/// 読書メモ追加画面
/// タブで3種類のメモを切り替えて登録: 本文抜粋、思考メモ、感想
class ReadingMemoAddScreen extends ConsumerStatefulWidget {
  final int bookId;
  final String bookTitle;

  const ReadingMemoAddScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  ConsumerState<ReadingMemoAddScreen> createState() => _ReadingMemoAddScreenState();
}

class _ReadingMemoAddScreenState extends ConsumerState<ReadingMemoAddScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _excerptController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _sectionTitleController = TextEditingController();
  final _pageNumberController = TextEditingController();

  late TabController _tabController;
  XFile? _sourceImage;
  bool _isSaving = false;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _excerptController.dispose();
    _thoughtController.dispose();
    _sectionTitleController.dispose();
    _pageNumberController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  MemoType get _currentMemoType {
    switch (_tabController.index) {
      case 0:
        return MemoType.excerpt;
      case 1:
        return MemoType.thought;
      case 2:
        return MemoType.review;
      default:
        return MemoType.excerpt;
    }
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

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        setState(() {
          controller.text = data.text!;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final memoType = _currentMemoType;

      // テキスト正規化
      final normalizedExcerpt = memoType == MemoType.excerpt
          ? TextNormalizer.normalizeQuoteText(_excerptController.text)
          : null;
      final normalizedThought =
          TextNormalizer.normalizeQuoteText(_thoughtController.text);
      final normalizedSectionTitle =
          TextNormalizer.normalizeSectionTitle(_sectionTitleController.text);
      final normalizedPageNumber =
          TextNormalizer.normalizePageNumber(_pageNumberController.text);

      // データベースに保存
      await _db.readingMemosDao.insertMemo(
        ReadingMemosCompanion.insert(
          bookId: widget.bookId,
          type: memoType,
          excerptText: Value(normalizedExcerpt),
          thoughtText: normalizedThought,
          content: Value(normalizedThought), // 下位互換性のため
          sectionTitle: Value((normalizedSectionTitle ?? '').isEmpty
              ? null
              : normalizedSectionTitle),
          pageNumber: Value(
              (normalizedPageNumber ?? '').isEmpty ? null : normalizedPageNumber),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('読書メモを保存しました')),
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

  Widget _buildExcerptTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 本文抜粋フィールド
        TextFormField(
          controller: _excerptController,
          decoration: const InputDecoration(
            labelText: '本文抜粋 *',
            hintText: 'iOSライブテキストでコピーした本文を貼り付け',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 6,
          minLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '本文抜粋を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),

        // 入力補助ボタン（本文抜粋用）
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('カメラ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickSourceImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('ギャラリー'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pasteFromClipboard(_excerptController),
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('貼り付け'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 画像プレビュー
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
          const SizedBox(height: 16),
        ],

        Text(
          '※ 貼り付け後、不要な改行や空白は自動で整形されます',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 24),

        // 思考メモフィールド
        TextFormField(
          controller: _thoughtController,
          decoration: const InputDecoration(
            labelText: '思考メモ *',
            hintText: '抜粋した本文に対する自分の考えや気づきを記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          minLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '思考メモを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        _buildCommonFields(),
      ],
    );
  }

  Widget _buildThoughtTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 思考メモフィールドのみ
        TextFormField(
          controller: _thoughtController,
          decoration: const InputDecoration(
            labelText: '思考メモ *',
            hintText: '読書中に浮かんだ考えや疑問を自由に記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 12,
          minLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '思考メモを入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        _buildCommonFields(),
      ],
    );
  }

  Widget _buildReviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 感想フィールド
        TextFormField(
          controller: _thoughtController,
          decoration: const InputDecoration(
            labelText: '感想 *',
            hintText: '書籍全体や特定の部分に対する感想を記録',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 12,
          minLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '感想を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        _buildCommonFields(),
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
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
        const SizedBox(height: 32),

        // 保存ボタン
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveMemo,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? '保存中...' : '読書メモを保存'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('読書メモを追加'),
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
              onPressed: _saveMemo,
              tooltip: '保存',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.format_quote),
              text: '本文抜粋',
            ),
            Tab(
              icon: Icon(Icons.lightbulb_outline),
              text: '思考メモ',
            ),
            Tab(
              icon: Icon(Icons.rate_review),
              text: '感想',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 書籍名表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.book, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.bookTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),

          // タブコンテンツ
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExcerptTab(),
                  _buildThoughtTab(),
                  _buildReviewTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
