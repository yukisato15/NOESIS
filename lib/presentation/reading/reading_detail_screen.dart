import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/entries_table.dart';
import 'package:intl/intl.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts/dictionary_prompts.dart';
import '../dictionary/dictionary_detail_screen.dart';
import 'quote_add_screen.dart';

class ReadingDetailScreen extends StatefulWidget {
  final int entryId;

  const ReadingDetailScreen({super.key, required this.entryId});

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final AIClient _aiClient = AIClient.instance;
  Entry? _entry;
  List<Quote> _quotes = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isPromoting = false;

  Future<T?> _runWithLoading<T>(Future<T?> Function() action) async {
    if (!mounted) {
      return null;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await action();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _bookController;
  late TextEditingController _genreController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _bookController = TextEditingController();
    _genreController = TextEditingController();
    _loadEntry();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bookController.dispose();
    _genreController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() {
      _isLoading = true;
    });

    final entry = await _db.entriesDao.getEntryById(widget.entryId);
    final quotes = await _db.quotesDao.getQuotesByEntryId(widget.entryId);

    if (entry != null) {
      setState(() {
        _entry = entry;
        _quotes = quotes;
        _titleController.text = entry.title;
        _bodyController.text = entry.body;
        _bookController.text = entry.reading ?? '';
        _genreController.text = entry.genre ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty ||
        _bookController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトル、本文、書籍名を入力してください')),
      );
      return;
    }

    await _runWithLoading(() async {
      try {
        final updatedEntry = _entry!.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          reading: _bookController.text.trim(),
          genre: drift.Value(_genreController.text.trim().isNotEmpty
              ? _genreController.text.trim()
              : null),
          updatedAt: DateTime.now(),
        );

        await _db.entriesDao.updateEntry(updatedEntry);

        if (!mounted) {
          return;
        }

        setState(() {
          _entry = updatedEntry;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存に失敗しました')),
          );
        }
      }
    });
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この読書ノートを削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runWithLoading(() async {
        try {
          await _db.entriesDao.deleteEntry(widget.entryId);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('削除に失敗しました')),
            );
          }
        }
      });
    }
  }

  Future<void> _promoteToDictionary() async {
    setState(() {
      _isPromoting = true;
    });

    try {
      final prompt = DictionaryPrompts.promoteFromReadingNote(
        title: _entry!.title,
        body: _entry!.body,
        bookTitle: _entry!.reading ?? '不明な書籍',
      );

      final jsonSchema = {
        "type": "object",
        "properties": {
          "headword": {"type": "string"},
          "reading": {"type": "string"},
          "genre": {"type": "string"},
          "definition": {"type": "string"},
          "etymology": {"type": "string"},
          "examples": {"type": "array", "items": {"type": "string"}},
          "synonyms": {"type": "array", "items": {"type": "string"}},
          "antonyms": {"type": "array", "items": {"type": "string"}},
          "related": {"type": "array", "items": {"type": "string"}},
          "usage_note": {"type": "string"},
          "reference_urls": {"type": "array", "items": {"type": "string"}},
        },
      };

      final result = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: jsonSchema,
      );

      // 辞書エントリとして保存
      final dictionaryEntry = EntriesCompanion(
        type: const drift.Value(EntryType.dictionary),
        title: drift.Value(result['headword'] ?? _entry!.title),
        body: drift.Value(result['definition'] ?? _entry!.body),
        genre: drift.Value(result['genre']),
        domain: const drift.Value(DictionaryDomain.general),
        reading: drift.Value(result['reading'] ?? ''),
        readingSource: const drift.Value('ai'),
      );

      final newEntryId = await _db.entriesDao.createEntry(dictionaryEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('辞書エントリとして昇格しました')),
        );

        // 辞書エントリ詳細画面へ遷移
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DictionaryDetailScreen(entryId: newEntryId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('昇格に失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isPromoting = false;
      });
    }
  }

  Future<void> _navigateToAddQuote() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QuoteAddScreen(
          entryId: widget.entryId,
          bookTitle: _entry!.reading ?? '書籍名未設定',
        ),
      ),
    );

    if (result == true) {
      // Reload quotes after adding a new one
      _loadEntry();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: const Center(child: Text('読書ノートが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編集' : _entry!.title),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _titleController.text = _entry!.title;
                  _bodyController.text = _entry!.body;
                  _bookController.text = _entry!.reading ?? '';
                  _genreController.text = _entry!.genre ?? '';
                  _isEditing = false;
                });
              },
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.reading, 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '読書ノート',
                  style: TextStyle(
                    color: AppPalette.reading,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '更新: ${dateFormat.format(_entry!.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.soften(AppPalette.reading, 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book, color: AppPalette.reading),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableContextText(
                        text: _entry!.reading ?? '書籍名未設定',
                        maxLines: 2,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppPalette.reading,
                        ),
                      ),
                      if (_entry!.genre != null) ...[
                        const SizedBox(height: 4),
                        SelectableContextText(
                          text: _entry!.genre!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SelectableContextText(
            text: _entry!.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SelectableContextText(
            text: _entry!.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          _buildQuotesSection(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isPromoting ? null : _promoteToDictionary,
            icon: _isPromoting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isPromoting ? 'AI変換中...' : '辞書エントリとして昇格',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.dictionaryGeneral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _bookController,
            decoration: const InputDecoration(
              labelText: '書籍名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.menu_book),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _genreController,
            decoration: const InputDecoration(
              labelText: 'ジャンル（任意）',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: '本文',
              hintText: 'メモや感想を入力',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 15,
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_quote, color: AppPalette.reading, size: 28),
            const SizedBox(width: 8),
            Text(
              '引用メモ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppPalette.reading,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _navigateToAddQuote,
              icon: const Icon(Icons.add),
              label: const Text('追加'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.reading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_quotes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppPalette.soften(AppPalette.reading, 0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.format_quote, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    '引用メモがまだありません',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'iOS Live Textで書籍からテキストをコピーして追加',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _quotes.map((quote) => _buildQuoteCard(quote)).toList(),
          ),
      ],
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppPalette.soften(AppPalette.reading, 0.95),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to quote detail/edit screen
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quote.sectionTitle != null && quote.sectionTitle!.isNotEmpty) ...[
                SelectableContextText(
                  text: quote.sectionTitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppPalette.reading,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(
                      color: AppPalette.reading,
                      width: 3,
                    ),
                  ),
                ),
                child: SelectableContextText(
                  text: quote.quoteText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (quote.pageOrLoc != null && quote.pageOrLoc!.isNotEmpty) ...[
                    Icon(Icons.bookmark_border, size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    SelectableContextText(
                      text: quote.pageOrLoc!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(quote.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
