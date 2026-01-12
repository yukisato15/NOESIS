import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../data/local/database.dart';

/// 本の登録画面
/// 書名・著者名は必須入力、その他の情報はAIで自動補完可能
class BookAddScreen extends ConsumerStatefulWidget {
  const BookAddScreen({super.key});

  @override
  ConsumerState<BookAddScreen> createState() => _BookAddScreenState();
}

class _BookAddScreenState extends ConsumerState<BookAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppDatabase _db = AppDatabase();

  // 必須項目
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();

  // 任意項目（AI補完可能）
  final _genreController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publishedDateController = TextEditingController();
  final _isbnController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _ratingController = TextEditingController();
  final _relatedUrlController = TextEditingController();
  final _reviewSummaryController = TextEditingController();

  bool _isSaving = false;
  bool _isCompletingWithAI = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _publisherController.dispose();
    _publishedDateController.dispose();
    _isbnController.dispose();
    _synopsisController.dispose();
    _ratingController.dispose();
    _relatedUrlController.dispose();
    _reviewSummaryController.dispose();
    _db.close();
    super.dispose();
  }

  /// AIで書籍情報を自動補完
  Future<void> _completeWithAI() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('書名と著者名を入力してください')),
      );
      return;
    }

    setState(() {
      _isCompletingWithAI = true;
    });

    try {
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();

      final prompt = '''
書籍の情報を補完してください。

書名: $title
著者: $author

以下の情報を調査して、正確な情報を返してください：
- genre: ジャンル（例: 小説、ビジネス書、哲学書、自己啓発、技術書など）
- publisher: 出版社
- published_date: 出版年月日（YYYY-MM-DD形式、分からない場合はYYYY形式でも可）
- isbn: ISBN（ISBN-10またはISBN-13）
- synopsis: あらすじ・概要（200文字程度）
- rating: 一般的な評価（例: 4.5/5.0、または簡単な評価コメント）
- related_url: 関連URL（Amazon、出版社の公式ページなど、実在するURLのみ）
- review_summary: 一般的なレビュー要約（100文字程度）

情報が見つからない項目は空文字列 "" を返してください。
''';

      final schema = {
        'type': 'object',
        'properties': {
          'genre': {'type': 'string'},
          'publisher': {'type': 'string'},
          'published_date': {'type': 'string'},
          'isbn': {'type': 'string'},
          'synopsis': {'type': 'string'},
          'rating': {'type': 'string'},
          'related_url': {'type': 'string'},
          'review_summary': {'type': 'string'},
        },
        'required': [
          'genre',
          'publisher',
          'published_date',
          'isbn',
          'synopsis',
          'rating',
          'related_url',
          'review_summary'
        ],
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: schema,
        mode: AIMode.withSearch, // Web検索を使用して情報を取得
      );

      if (mounted) {
        setState(() {
          if (result['genre'] != null && result['genre'].toString().isNotEmpty) {
            _genreController.text = result['genre'].toString();
          }
          if (result['publisher'] != null &&
              result['publisher'].toString().isNotEmpty) {
            _publisherController.text = result['publisher'].toString();
          }
          if (result['published_date'] != null &&
              result['published_date'].toString().isNotEmpty) {
            _publishedDateController.text = result['published_date'].toString();
          }
          if (result['isbn'] != null && result['isbn'].toString().isNotEmpty) {
            _isbnController.text = result['isbn'].toString();
          }
          if (result['synopsis'] != null &&
              result['synopsis'].toString().isNotEmpty) {
            _synopsisController.text = result['synopsis'].toString();
          }
          if (result['rating'] != null &&
              result['rating'].toString().isNotEmpty) {
            _ratingController.text = result['rating'].toString();
          }
          if (result['related_url'] != null &&
              result['related_url'].toString().isNotEmpty) {
            _relatedUrlController.text = result['related_url'].toString();
          }
          if (result['review_summary'] != null &&
              result['review_summary'].toString().isNotEmpty) {
            _reviewSummaryController.text = result['review_summary'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AIによる情報補完が完了しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI補完に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingWithAI = false;
        });
      }
    }
  }

  /// 書籍を保存
  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final companion = BooksCompanion.insert(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: Value(_genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim()),
        publisher: Value(_publisherController.text.trim().isEmpty
            ? null
            : _publisherController.text.trim()),
        publishedDate: Value(_publishedDateController.text.trim().isEmpty
            ? null
            : _publishedDateController.text.trim()),
        isbn: Value(_isbnController.text.trim().isEmpty
            ? null
            : _isbnController.text.trim()),
        synopsis: Value(_synopsisController.text.trim().isEmpty
            ? null
            : _synopsisController.text.trim()),
        rating: Value(_ratingController.text.trim().isEmpty
            ? null
            : _ratingController.text.trim()),
        relatedUrl: Value(_relatedUrlController.text.trim().isEmpty
            ? null
            : _relatedUrlController.text.trim()),
        reviewSummary: Value(_reviewSummaryController.text.trim().isEmpty
            ? null
            : _reviewSummaryController.text.trim()),
      );

      await _db.booksDao.insertBook(companion);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('書籍を登録しました')),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本を追加'),
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
              onPressed: _saveBook,
              tooltip: '保存',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 説明カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI補完機能',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '書名と著者名を入力後、「AIで情報を補完」ボタンを押すと、\n'
                      'ジャンル・出版社・ISBN・あらすじなどを自動入力できます',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 必須項目
            Text(
              '必須項目',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '書名 *',
                hintText: '例: 銃・病原菌・鉄',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '書名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '著者名 *',
                hintText: '例: ジャレド・ダイアモンド',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '著者名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // AI補完ボタン
            FilledButton.icon(
              onPressed: _isCompletingWithAI ? null : _completeWithAI,
              icon: _isCompletingWithAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isCompletingWithAI ? 'AI補完中...' : 'AIで情報を補完'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // 任意項目
            Text(
              '任意項目（AI補完可能）',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'ジャンル',
                hintText: '例: 歴史、科学、ノンフィクション',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _publisherController,
              decoration: const InputDecoration(
                labelText: '出版社',
                hintText: '例: 草思社',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _publishedDateController,
              decoration: const InputDecoration(
                labelText: '出版年月日',
                hintText: '例: 2000-10-02 または 2000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                hintText: '例: 978-4-7942-0337-1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _synopsisController,
              decoration: const InputDecoration(
                labelText: 'あらすじ・概要',
                hintText: 'この本の内容について',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: '評価',
                hintText: '例: 4.5/5.0、名著、必読書など',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _relatedUrlController,
              decoration: const InputDecoration(
                labelText: '関連URL',
                hintText: '例: Amazonリンク、出版社ページなど',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reviewSummaryController,
              decoration: const InputDecoration(
                labelText: '一般的なレビュー要約',
                hintText: '世間での評価や読者の感想など',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.rate_review),
              ),
              maxLines: 4,
              minLines: 2,
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveBook,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? '保存中...' : '書籍を登録'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
