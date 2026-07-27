import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/models/ai_chat_message.dart';
import '../../core/ai/prompts/thinking_prompts.dart';
import '../../core/ai/thinking_styles/thinking_style.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/book_ai_entries_table.dart';
import 'reading_memo_add_screen.dart';
import 'reading_memo_detail_screen.dart';

/// 本の詳細画面
/// 書籍のメタデータと、その書籍に紐づく読書メモの一覧を表示
class BookDetailScreen extends ConsumerStatefulWidget {
  final int bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  late final TabController _tabController;
  Book? _book;
  List<ReadingMemo> _memos = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isAiProcessing = false;
  ThinkingStyle _selectedThinkingStyle = ThinkingStyle.socrates;
  List<BookAiEntry> _overallAiEntries = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _publishedDateController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _synopsisController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _relatedUrlController = TextEditingController();
  final TextEditingController _reviewSummaryController = TextEditingController();
  final TextEditingController _overallQuestionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _showQuestionComposer = false;
  String? _coverImagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    _overallQuestionController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadData({bool showPageLoader = true}) async {
    if (showPageLoader && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final book = await _db.booksDao.getBookById(widget.bookId);
      final memos = await _db.readingMemosDao.getMemosByBookId(widget.bookId);
      final aiEntries =
          await _db.bookAiEntriesDao.getEntriesByBookId(widget.bookId);

      if (mounted) {
        setState(() {
          _book = book;
          _memos = memos;
          _overallAiEntries = aiEntries;
          _isLoading = false;
        });
        _syncControllersFromBook();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _syncControllersFromBook() {
    if (_book == null) {
      return;
    }
    _titleController.text = _book!.title;
    _authorController.text = _book!.author;
    _genreController.text = _book!.genre ?? '';
    _publisherController.text = _book!.publisher ?? '';
    _publishedDateController.text = _book!.publishedDate ?? '';
    _isbnController.text = _book!.isbn ?? '';
    _synopsisController.text = _book!.synopsis ?? '';
    _ratingController.text = _book!.rating ?? '';
    _relatedUrlController.text = _book!.relatedUrl ?? '';
    _reviewSummaryController.text = _book!.reviewSummary ?? '';
    _coverImagePath = _book!.coverImagePath;
  }

  Future<void> _saveEdits() async {
    if (_book == null) return;

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    if (title.isEmpty || author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('書名と著者名は必須です')),
      );
      return;
    }

    final updated = _book!.copyWith(
      title: title,
      author: author,
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
      coverImagePath: Value(await _persistCoverImage()),
      updatedAt: DateTime.now(),
    );

    try {
      await _db.booksDao.updateBook(updated);
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _coverImagePath == null || _coverImagePath!.isEmpty
                  ? '書籍情報を更新しました'
                  : '書籍情報を更新しました（表紙も保存済み）',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 55,
      maxWidth: 480,
    );
    if (file == null || !mounted) return;
    setState(() => _coverImagePath = file.path);
  }

  Future<String?> _persistCoverImage() async {
    if (_coverImagePath == null || _coverImagePath!.isEmpty) {
      return _book?.coverImagePath;
    }
    final source = File(_coverImagePath!);
    if (!await source.exists()) return _book?.coverImagePath;

    final docsDir = await getApplicationDocumentsDirectory();
    final coverDir = Directory('${docsDir.path}/book_covers');
    if (!await coverDir.exists()) {
      await coverDir.create(recursive: true);
    }
    if (_coverImagePath!.startsWith(coverDir.path)) {
      return _coverImagePath;
    }

    final extension = _coverImagePath!.contains('.')
        ? _coverImagePath!.substring(_coverImagePath!.lastIndexOf('.'))
        : '.jpg';
    final outputPath =
        '${coverDir.path}/cover_${widget.bookId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    return source.copy(outputPath).then((file) => file.path);
  }

  bool get _hasMissingSavedCover {
    final path = _book?.coverImagePath;
    if (path == null || path.isEmpty) {
      return false;
    }
    return !File(path).existsSync();
  }

  void _cancelEdit() {
    _syncControllersFromBook();
    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('書籍を削除'),
        content: const Text(
          'この書籍とすべての読書メモを削除しますか？\n'
          'この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // メモを削除
      for (final memo in _memos) {
        await _db.readingMemosDao.deleteMemo(memo.id);
      }
      // 書籍を削除
      await _db.booksDao.deleteBook(widget.bookId);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('書籍を削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteMemo(ReadingMemo memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _db.readingMemosDao.deleteMemo(memo.id);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを削除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  String _buildBookAiSourceText() {
    if (_book == null) return '';
    final buffer = StringBuffer()
      ..writeln('書名: ${_book!.title}')
      ..writeln('著者: ${_book!.author}');
    if (_book!.genre?.isNotEmpty == true) {
      buffer.writeln('ジャンル: ${_book!.genre}');
    }
    if (_book!.synopsis?.isNotEmpty == true) {
      buffer.writeln('\n概要:\n${_book!.synopsis}');
    }
    if (_memos.isNotEmpty) {
      buffer.writeln('\n読書メモ:');
      for (final memo in _memos) {
        if (memo.sectionTitle?.isNotEmpty == true) {
          buffer.writeln('- セクション: ${memo.sectionTitle}');
        }
        if (memo.excerptText?.isNotEmpty == true) {
          buffer.writeln('  本文抜粋: ${memo.excerptText}');
        }
        buffer.writeln('  思考メモ: ${memo.content ?? memo.thoughtText}');
      }
    }
    return buffer.toString().trim();
  }

  BookAiEntry? _latestEntry(AggregateAiEntryType type) {
    for (final entry in _overallAiEntries.reversed) {
      if (entry.entryType == type) {
        return entry;
      }
    }
    return null;
  }

  List<BookAiEntry> get _qaEntries => _overallAiEntries
      .where((entry) => entry.entryType == AggregateAiEntryType.qa)
      .toList();

  Future<void> _deleteAiEntry(BookAiEntry entry) async {
    await _db.bookAiEntriesDao.deleteEntryById(entry.id);
    await _loadData(showPageLoader: false);
  }

  Future<void> _deleteAiEntriesByType(AggregateAiEntryType type) async {
    await _db.bookAiEntriesDao.deleteEntriesByType(widget.bookId, type);
    await _loadData(showPageLoader: false);
  }

  Future<void> _generateOverallSummary() async {
    final sourceText = _buildBookAiSourceText();
    if (sourceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIが参照できる本文がありません')),
      );
      return;
    }
    setState(() => _isAiProcessing = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt: '''
以下の書籍情報と読書メモ全体を要約してください。
- 全体像を2文以内で整理
- 重要ポイントを3〜5個にまとめる

【対象】
$sourceText
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'summary': {'type': 'string'},
            'key_points': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
          'required': ['summary', 'key_points'],
        },
      );
      final formatted = '''
## 全体要約

${result['summary']}

## 重要ポイント

${(result['key_points'] as List).map((e) => '• $e').join('\n')}
''';
      await _db.bookAiEntriesDao.insertEntry(
        BookAiEntriesCompanion.insert(
          bookId: widget.bookId,
          entryType: AggregateAiEntryType.summary,
          content: formatted,
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );
      await _loadData(showPageLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI全体要約に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  Future<void> _generateOverallAnalysis() async {
    final sourceText = _buildBookAiSourceText();
    if (sourceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIが参照できる本文がありません')),
      );
      return;
    }
    setState(() => _isAiProcessing = true);
    try {
      final result = await AIClient.instance.chat(
        messages: ThinkingPrompts.buildChatMessages(
          style: _selectedThinkingStyle,
          memoContent: sourceText,
          history: [
            AIChatMessage(
              role: 'user',
              content:
                  'この書籍と読書メモ全体を分析し、重要な論点、前提、次に深めるべき問いを整理してください。',
            ),
          ],
        ),
      );
      await _db.bookAiEntriesDao.insertEntry(
        BookAiEntriesCompanion.insert(
          bookId: widget.bookId,
          entryType: AggregateAiEntryType.analysis,
          content: result.trim(),
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );
      await _loadData(showPageLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI分析に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  Future<void> _askAboutBook() async {
    final sourceText = _buildBookAiSourceText();
    if (sourceText.isEmpty) return;
    final question = _overallQuestionController.text.trim();
    if (question.isEmpty) return;

    setState(() => _isAiProcessing = true);
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
      await _db.bookAiEntriesDao.insertEntry(
        BookAiEntriesCompanion.insert(
          bookId: widget.bookId,
          entryType: AggregateAiEntryType.qa,
          content: '## 質問\n$question\n\n## 回答\n$answer',
          question: Value(question),
          thinkingStyleName: Value(_selectedThinkingStyle.name),
        ),
      );
      _overallQuestionController.clear();
      if (mounted) {
        setState(() => _showQuestionComposer = false);
      }
      await _loadData(showPageLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI質問に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAiProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('書籍詳細')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('書籍詳細')),
        body: const Center(
          child: Text('書籍が見つかりませんでした'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('書籍詳細'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEdits,
              tooltip: '保存',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'キャンセル',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _syncControllersFromBook();
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBook,
              tooltip: '書籍を削除',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppPalette.reading,
              unselectedLabelColor:
                  theme.colorScheme.secondary.withValues(alpha: 0.6),
              indicatorColor: AppPalette.reading,
              tabs: const [
                Tab(text: '情報'),
                Tab(text: '読書メモ'),
                Tab(text: 'AI全体要約'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(theme),
                _buildMemoTab(theme),
                _buildOverallAiTab(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReadingMemoAddScreen(
                bookId: widget.bookId,
                bookTitle: _book!.title,
              ),
            ),
          );
          if (result == true && mounted) {
            _loadData();
          }
        },
        backgroundColor: AppPalette.reading,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('メモを追加'),
      ),
    );
  }

  Widget _buildInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing && _hasMissingSavedCover) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC97A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE86A00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '表紙ファイルが見つかりません',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFFE86A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'この本には表紙パスが残っていますが、元画像ファイルが端末内に存在しません。'
                    ' 古いビルドで未保存だったか、アプリ保存領域の切り替わりで見失った可能性があります。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFE86A00),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isEditing)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _BookCoverCard(imagePath: _coverImagePath, title: _book!.title),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '表紙画像は一覧のアイコンにも使います。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _pickCoverImage,
                      child: Text(_coverImagePath == null ? '追加' : '変更'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Center(
              child: _BookCoverCard(
                imagePath: _book!.coverImagePath,
                title: _book!.title,
                width: 112,
                height: 156,
                radius: 18,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isEditing) ...[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '書名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '著者名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'ジャンル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _publisherController,
              decoration: const InputDecoration(
                labelText: '出版社',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _publishedDateController,
              decoration: const InputDecoration(
                labelText: '出版年月日',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _synopsisController,
              decoration: const InputDecoration(
                labelText: 'あらすじ・概要',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(
                labelText: '評価',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relatedUrlController,
              decoration: const InputDecoration(
                labelText: '関連URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewSummaryController,
              decoration: const InputDecoration(
                labelText: 'レビュー要約',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              minLines: 2,
            ),
          ] else ...[
            SelectableContextText(
              text: _book!.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableContextText(
                    text: _book!.author,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            if (_book!.genre?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(_book!.genre!),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 16),
            if (_book!.publisher?.isNotEmpty == true)
              _buildInfoRow('出版社', _book!.publisher!),
            if (_book!.publishedDate?.isNotEmpty == true)
              _buildInfoRow('出版日', _book!.publishedDate!),
            if (_book!.isbn?.isNotEmpty == true)
              _buildInfoRow('ISBN', _book!.isbn!),
            if (_book!.synopsis?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'あらすじ',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SelectableContextText(text: _book!.synopsis!),
            ],
            if (_book!.rating?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildInfoRow('評価', _book!.rating!),
            ],
            if (_book!.relatedUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildInfoRow('関連URL', _book!.relatedUrl!, isUrl: true),
            ],
            if (_book!.reviewSummary?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'レビュー要約',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SelectableContextText(text: _book!.reviewSummary!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMemoTab(ThemeData theme) {
    if (_memos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'メモがありません',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memos.length,
      itemBuilder: (context, index) {
        final memo = _memos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReadingMemoDetailScreen(
                    memoId: memo.id,
                    bookTitle: _book!.title,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memo.sectionTitle?.isNotEmpty == true)
                        Expanded(
                          child: Text(
                            memo.sectionTitle!,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppPalette.reading,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (memo.pageNumber?.isNotEmpty == true)
                        Chip(
                          label: Text('p.${memo.pageNumber}'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteMemo(memo);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('削除'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert, size: 20),
                        tooltip: 'メニュー',
                      ),
                    ],
                  ),
                  if (memo.excerptText?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      '本文抜粋',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppPalette.reading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableContextText(
                      text: memo.excerptText!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((memo.content ?? memo.thoughtText).trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '思考メモ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppPalette.reading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableContextText(
                      text: memo.content ?? memo.thoughtText,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallAiTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '思考キャラクター',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButton<ThinkingStyle>(
                value: _selectedThinkingStyle,
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
                    setState(() => _selectedThinkingStyle = style);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAiProcessing ? null : _generateOverallSummary,
                  icon: const Icon(Icons.summarize_outlined, size: 18),
                  label: const Text('全体要約'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAiProcessing ? null : _generateOverallAnalysis,
                  icon: const Icon(Icons.auto_graph_outlined, size: 18),
                  label: const Text('分析'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isAiProcessing
                      ? null
                      : () {
                          setState(() {
                            _showQuestionComposer = !_showQuestionComposer;
                          });
                        },
                  icon: const Icon(Icons.question_answer_outlined, size: 18),
                  label: const Text('質問'),
                ),
              ),
            ],
          ),
          if (_showQuestionComposer) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _overallQuestionController,
                      decoration: const InputDecoration(
                        hintText: '本と読書メモ全体について質問する',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _overallQuestionController.clear();
                            setState(() => _showQuestionComposer = false);
                          },
                          child: const Text('キャンセル'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _isAiProcessing ? null : _askAboutBook,
                          child: const Text('送信'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_isAiProcessing) ...[
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
          if (_latestEntry(AggregateAiEntryType.summary) != null) ...[
            const SizedBox(height: 20),
            Text(
              '全体要約',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => _deleteAiEntriesByType(
                          AggregateAiEntryType.summary,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                      ),
                    ),
                    SelectableContextText(
                      text: _latestEntry(AggregateAiEntryType.summary)!.content,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_latestEntry(AggregateAiEntryType.analysis) != null) ...[
            const SizedBox(height: 20),
            Text(
              '分析',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => _deleteAiEntriesByType(
                          AggregateAiEntryType.analysis,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '削除',
                      ),
                    ),
                    SelectableContextText(
                      text: _latestEntry(AggregateAiEntryType.analysis)!.content,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_qaEntries.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '質問履歴',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in _qaEntries.reversed)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => _deleteAiEntry(item),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '削除',
                        ),
                      ),
                      SelectableContextText(text: item.content),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isUrl
                ? GestureDetector(
                    onTap: () => _launchUrl(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : SelectableContextText(
                    text: value,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URLを開けませんでした: $urlString')),
        );
      }
    }
  }
}

class _BookCoverCard extends StatelessWidget {
  final String? imagePath;
  final String title;
  final double width;
  final double height;
  final double radius;

  const _BookCoverCard({
    required this.imagePath,
    required this.title,
    this.width = 72,
    this.height = 100,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppPalette.soften(AppPalette.reading, 0.18),
        image: hasImage
            ? DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasImage
          ? null
          : Center(
              child: Text(
                title.isNotEmpty ? title[0] : '?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.reading,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}
