import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../code/code_entry_detail_screen.dart';
import '../daily/daily_memo_detail_screen.dart';
import '../dictionary/dictionary_entry_detail_screen.dart';
import '../reading/book_detail_screen.dart';
import '../reading/reading_memo_detail_screen.dart';
import '../search/search_screen.dart';
import '../thinking/concept_memo_detail_screen.dart';
import '../thinking/philosophical_dialogue_detail_screen.dart';
import 'quiz_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final AppDatabase _db = AppDatabase();
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  Map<DateTime, List<_RecordItem>> _itemsByDay = {};
  List<_RecordItem> _recentItems = [];
  List<_RecordItem> _flashWords = [];
  int _flashIndex = 0;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateUtils.dateOnly(now);
    _loadMonthData();
    _startFlashTimer();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _db.close();
    super.dispose();
  }

  void _startFlashTimer() {
    _flashTimer?.cancel();
    _flashTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _flashWords.isEmpty) {
        return;
      }
      setState(() {
        _flashIndex = (_flashIndex + 1) % _flashWords.length;
      });
    });
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1);

    final items = <_RecordItem>[];

    final dictionaries = await _db.dictionariesDao.getAllDictionaries();
    final dictionaryMap = {
      for (final dict in dictionaries) dict.id: dict.name,
    };

    final dictEntries = await (_db.select(_db.dictionaryEntries)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final entry in dictEntries) {
      items.add(_RecordItem(
        title: entry.headword,
        subtitle: dictionaryMap[entry.dictionaryId] ?? '辞書',
        createdAt: entry.createdAt,
        kind: _RecordKind.dictionaryEntry,
        primaryId: entry.id,
        secondaryId: entry.dictionaryId,
      ));
    }

    final readingMemos = await (_db.select(_db.readingMemos)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    final readingBookIds =
        readingMemos.map((memo) => memo.bookId).toSet().toList();
    final readingBooks = readingBookIds.isEmpty
        ? <Book>[]
        : await (_db.select(_db.books)
              ..where((t) => t.id.isIn(readingBookIds)))
            .get();
    final bookMap = {for (final book in readingBooks) book.id: book.title};
    for (final memo in readingMemos) {
      items.add(_RecordItem(
        title: memo.thoughtText.isEmpty ? '読書メモ' : memo.thoughtText,
        subtitle: bookMap[memo.bookId] ?? '読書メモ',
        createdAt: memo.createdAt,
        kind: _RecordKind.readingMemo,
        primaryId: memo.id,
        secondaryId: memo.bookId,
        extraTitle: bookMap[memo.bookId],
      ));
    }

    final dailyMemos = await (_db.select(_db.dailyMemos)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final memo in dailyMemos) {
      items.add(_RecordItem(
        title: memo.title ?? memo.content,
        subtitle: '日常メモ',
        createdAt: memo.createdAt,
        kind: _RecordKind.dailyMemo,
        primaryId: memo.id,
      ));
    }

    final conceptMemos = await (_db.select(_db.conceptMemos)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final memo in conceptMemos) {
      items.add(_RecordItem(
        title: memo.title ?? memo.content,
        subtitle: '概念メモ',
        createdAt: memo.createdAt,
        kind: _RecordKind.conceptMemo,
        primaryId: memo.id,
      ));
    }

    final dialogues = await (_db.select(_db.philosophicalDialogues)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final dialogue in dialogues) {
      items.add(_RecordItem(
        title: dialogue.title.isEmpty ? '無題の対話' : dialogue.title,
        subtitle: '哲学的対話',
        createdAt: dialogue.createdAt,
        kind: _RecordKind.dialogue,
        primaryId: dialogue.id,
      ));
    }

    final codeEntries = await (_db.select(_db.codeEntries)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final entry in codeEntries) {
      items.add(_RecordItem(
        title: entry.title,
        subtitle: 'ITコード学習',
        createdAt: entry.createdAt,
        kind: _RecordKind.codeEntry,
        primaryId: entry.id,
      ));
    }

    final books = await (_db.select(_db.books)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(monthStart) &
              t.createdAt.isSmallerThanValue(monthEnd)))
        .get();
    for (final book in books) {
      items.add(_RecordItem(
        title: book.title,
        subtitle: '読書アーカイブ',
        createdAt: book.createdAt,
        kind: _RecordKind.book,
        primaryId: book.id,
      ));
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentItems = items.take(6).toList();

    final grouped = <DateTime, List<_RecordItem>>{};
    for (final item in items) {
      final day = DateUtils.dateOnly(item.createdAt);
      grouped.putIfAbsent(day, () => []).add(item);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final flashWords = items
        .where((item) => item.kind == _RecordKind.dictionaryEntry)
        .take(30)
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _itemsByDay = grouped;
      _recentItems = recentItems;
      _flashWords = flashWords;
      _flashIndex = 0;
      _isLoading = false;
    });
  }

  Future<void> _openQuiz(_QuizMode mode) async {
    final items = await _loadQuizSourceEntries(mode);
    if (!mounted) {
      return;
    }
    if (items.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クイズに使える辞書データが足りません')),
      );
      return;
    }
    final questions = _buildQuizQuestions(items);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('クイズの作成に失敗しました')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          title: _quizTitle(mode),
          questions: questions,
        ),
      ),
    );
  }

  String _quizTitle(_QuizMode mode) {
    switch (mode) {
      case _QuizMode.dictionary:
        return '辞書クイズ';
      case _QuizMode.todayFive:
        return '今日の5問';
      case _QuizMode.randomReview:
        return 'ランダム復習';
    }
  }

  Future<List<_QuizSourceEntry>> _loadQuizSourceEntries(_QuizMode mode) async {
    final definitionFields = await (_db.select(_db.dictionaryFields)
          ..where((t) => t.fieldKey.equals('definition')))
        .get();
    if (definitionFields.isEmpty) {
      return [];
    }
    final fieldIds = definitionFields.map((f) => f.id).toSet();
    final dictionaryIds = definitionFields.map((f) => f.dictionaryId).toSet();

    DateTime? start;
    DateTime? end;
    if (mode == _QuizMode.todayFive) {
      final today = DateUtils.dateOnly(DateTime.now());
      start = today;
      end = today.add(const Duration(days: 1));
    }

    final entries = await (_db.select(_db.dictionaryEntries)
          ..where((t) => t.dictionaryId.isIn(dictionaryIds.toList()))
          ..where((t) {
            if (start == null || end == null) {
              return const Constant<bool>(true);
            }
            return t.createdAt.isBiggerOrEqualValue(start) &
                t.createdAt.isSmallerThanValue(end);
          }))
        .get();

    if (entries.isEmpty) {
      return [];
    }

    final entryIds = entries.map((e) => e.id).toList();
    final values = await (_db.select(_db.dictionaryEntryValues)
          ..where((t) => t.entryId.isIn(entryIds))
          ..where((t) => t.fieldId.isIn(fieldIds.toList())))
        .get();
    final valueMap = <int, String>{};
    for (final value in values) {
      final text = value.value.trim();
      if (text.isNotEmpty) {
        valueMap[value.entryId] = text;
      }
    }

    return entries
        .where((entry) => valueMap.containsKey(entry.id))
        .map((entry) => _QuizSourceEntry(
              entryId: entry.id,
              headword: entry.headword,
              definition: valueMap[entry.id]!,
            ))
        .toList();
  }

  List<QuizQuestion> _buildQuizQuestions(List<_QuizSourceEntry> source) {
    final rng = Random();
    final pool = [...source];
    pool.shuffle(rng);

    final questions = <QuizQuestion>[];
    final maxCount = pool.length < 5 ? pool.length : 5;
    for (final entry in pool.take(maxCount)) {
      final headword = entry.headword.trim();
      final correct = _sanitizeDefinition(entry.definition, headword);
      if (correct.isEmpty) {
        continue;
      }
      final wrongs = pool
          .where((e) => e.entryId != entry.entryId)
          .map((e) => _sanitizeDefinition(e.definition, headword))
          .where((text) => text.isNotEmpty && !_containsHeadword(text, headword))
          .toList();
      if (wrongs.length < 3) {
        continue;
      }
      wrongs.shuffle(rng);
      final options = <String>[
        correct,
        ...wrongs.take(3),
      ]..shuffle(rng);
      if (options.any((option) => _containsHeadword(option, headword))) {
        continue;
      }
      questions.add(
        QuizQuestion(
          headword: headword,
          correctAnswer: correct,
          options: options,
          entryId: entry.entryId,
        ),
      );
    }
    return questions;
  }

  String _sanitizeDefinition(String text, String headword) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (headword.isEmpty) {
      return trimmed;
    }
    final escaped = RegExp.escape(headword);
    final replaced = trimmed.replaceAll(
      RegExp(escaped, caseSensitive: false),
      '＿＿',
    );
    return replaced.trim();
  }

  bool _containsHeadword(String text, String headword) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || headword.isEmpty) {
      return false;
    }
    return RegExp(RegExp.escape(headword), caseSensitive: false)
        .hasMatch(trimmed);
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = DateUtils.dateOnly(day);
    });
  }

  Future<void> _openItem(_RecordItem item) async {
    switch (item.kind) {
      case _RecordKind.dictionaryEntry:
        if (item.secondaryId == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DictionaryEntryDetailScreen(
              dictionaryId: item.secondaryId!,
              entryId: item.primaryId,
            ),
          ),
        );
        break;
      case _RecordKind.readingMemo:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReadingMemoDetailScreen(
              memoId: item.primaryId,
              bookTitle: item.extraTitle ?? '読書メモ',
            ),
          ),
        );
        break;
      case _RecordKind.dailyMemo:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DailyMemoDetailScreen(memoId: item.primaryId),
          ),
        );
        break;
      case _RecordKind.conceptMemo:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConceptMemoDetailScreen(memoId: item.primaryId),
          ),
        );
        break;
      case _RecordKind.dialogue:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PhilosophicalDialogueDetailScreen(dialogueId: item.primaryId),
          ),
        );
        break;
      case _RecordKind.codeEntry:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CodeEntryDetailScreen(entryId: item.primaryId),
          ),
        );
        break;
      case _RecordKind.book:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(bookId: item.primaryId),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDay = _selectedDay ?? DateUtils.dateOnly(DateTime.now());
    final itemsForDay = _itemsByDay[selectedDay] ?? [];
    final flashItem = _flashWords.isEmpty ? null : _flashWords[_flashIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索へ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: '最近のアイテム',
                          trailing: Text(
                            DateFormat('yyyy/MM').format(_focusedMonth),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_recentItems.isEmpty)
                          _EmptyCard(
                            message: 'まだ記録がありません',
                            icon: Icons.auto_awesome_outlined,
                          )
                        else
                          SizedBox(
                            height: 160,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recentItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = _recentItems[index];
                                return _RecentItemCard(
                                  item: item,
                                  onTap: () => _openItem(item),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: '復習ワード',
                        ),
                        const SizedBox(height: 12),
                        _FlashWordCard(
                          item: flashItem,
                          onTap: flashItem == null
                              ? null
                              : () => _openItem(flashItem),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: 'クイズ & 学習',
                        ),
                        const SizedBox(height: 12),
                        _QuizGrid(onSelect: _openQuiz),
                        const SizedBox(height: 20),
                        _SectionHeader(title: 'カレンダー'),
                        const SizedBox(height: 12),
                        _CalendarCard(
                          month: _focusedMonth,
                          selectedDay: selectedDay,
                          itemsByDay: _itemsByDay,
                          onPrev: () {
                            setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month - 1,
                              );
                              _selectedDay = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month,
                                1,
                              );
                            });
                            _loadMonthData();
                          },
                          onNext: () {
                            setState(() {
                              _focusedMonth = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                              );
                              _selectedDay = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month,
                                1,
                              );
                            });
                            _loadMonthData();
                          },
                          onSelect: _selectDay,
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(
                          title: DateFormat('MM/dd').format(selectedDay),
                          trailing: Text(
                            '${itemsForDay.length} 件',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (itemsForDay.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: _EmptyCard(
                        message: 'この日の記録はありません',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: itemsForDay.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = itemsForDay[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: _RecordItemTile(
                          item: item,
                          onTap: () => _openItem(item),
                        ),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.secondary.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final _RecordItem item;
  final VoidCallback onTap;

  const _RecentItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('MM/dd HH:mm').format(item.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashWordCard extends StatelessWidget {
  final _RecordItem? item;
  final VoidCallback? onTap;

  const _FlashWordCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppPalette.soften(AppPalette.dictionaryGeneral, 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: AppPalette.dictionaryGeneral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item == null ? '辞書の単語がまだありません' : item!.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (item != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizGrid extends StatelessWidget {
  final ValueChanged<_QuizMode> onSelect;

  const _QuizGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttons = [
      (_QuizMode.dictionary, '辞書クイズ', Icons.quiz_outlined),
      (_QuizMode.todayFive, '今日の5問', Icons.flash_on_outlined),
      (_QuizMode.randomReview, 'ランダム復習', Icons.shuffle),
    ];

    return Row(
      children: [
        for (var index = 0; index < buttons.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == buttons.length - 1 ? 0 : 8),
              child: OutlinedButton.icon(
                onPressed: () => onSelect(buttons[index].$1),
                icon: Icon(buttons[index].$3, size: 18),
                label: Text(buttons[index].$2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<DateTime, List<_RecordItem>> itemsByDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  const _CalendarCard({
    required this.month,
    required this.selectedDay,
    required this.itemsByDay,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = firstDay.weekday % 7;
    final totalCells = offset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('yyyy/MM').format(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekdayLabel('日'),
              _WeekdayLabel('月'),
              _WeekdayLabel('火'),
              _WeekdayLabel('水'),
              _WeekdayLabel('木'),
              _WeekdayLabel('金'),
              _WeekdayLabel('土'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(month.year, month.month, dayNumber);
              final isSelected = DateUtils.isSameDay(day, selectedDay);
              final hasItems = itemsByDay.containsKey(DateUtils.dateOnly(day));
              return GestureDetector(
                onTap: () => onSelect(day),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppPalette.soften(AppPalette.thinking, 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppPalette.thinking
                              : theme.colorScheme.secondary,
                        ),
                      ),
                      if (hasItems)
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppPalette.thinking,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _RecordItemTile extends StatelessWidget {
  final _RecordItem item;
  final VoidCallback onTap;

  const _RecordItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: item.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('HH:mm').format(item.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordItem {
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final _RecordKind kind;
  final int primaryId;
  final int? secondaryId;
  final String? extraTitle;

  const _RecordItem({
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.kind,
    required this.primaryId,
    this.secondaryId,
    this.extraTitle,
  });

  IconData get icon {
    switch (kind) {
      case _RecordKind.dictionaryEntry:
        return Icons.menu_book_outlined;
      case _RecordKind.readingMemo:
        return Icons.auto_stories_outlined;
      case _RecordKind.dailyMemo:
        return Icons.edit_note;
      case _RecordKind.conceptMemo:
        return Icons.scatter_plot_outlined;
      case _RecordKind.dialogue:
        return Icons.forum_outlined;
      case _RecordKind.codeEntry:
        return Icons.code;
      case _RecordKind.book:
        return Icons.book_outlined;
    }
  }

  Color get accent {
    switch (kind) {
      case _RecordKind.dictionaryEntry:
        return AppPalette.dictionaryGeneral;
      case _RecordKind.readingMemo:
        return AppPalette.reading;
      case _RecordKind.dailyMemo:
        return AppPalette.daily;
      case _RecordKind.conceptMemo:
        return AppPalette.thinking;
      case _RecordKind.dialogue:
        return AppPalette.thinking;
      case _RecordKind.codeEntry:
        return AppPalette.code;
      case _RecordKind.book:
        return AppPalette.reading;
    }
  }
}

enum _RecordKind {
  dictionaryEntry,
  readingMemo,
  dailyMemo,
  conceptMemo,
  dialogue,
  codeEntry,
  book,
}

enum _QuizMode {
  dictionary,
  todayFive,
  randomReview,
}

class _QuizSourceEntry {
  final int entryId;
  final String headword;
  final String definition;

  const _QuizSourceEntry({
    required this.entryId,
    required this.headword,
    required this.definition,
  });
}
