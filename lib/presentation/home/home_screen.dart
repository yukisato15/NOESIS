import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/archive_targets_table.dart';
import '../archive/archive_target_add_screen.dart';
import '../archive/archive_target_detail_screen.dart';
import '../archive/archive_target_list_screen.dart';
import '../code/code_entry_add_screen.dart';
import '../code/code_entry_detail_screen.dart';
import '../code/code_entry_list_screen.dart';
import '../daily/daily_memo_add_screen.dart';
import '../daily/daily_memo_detail_screen.dart';
import '../daily/daily_memo_screen.dart';
import '../dictionary/dictionary_entry_detail_screen.dart';
import '../dictionary/dictionary_entry_edit_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../listening/episode_add_screen.dart';
import '../listening/listening_screen.dart';
import '../reading/book_add_screen.dart';
import '../reading/book_detail_screen.dart';
import '../reading/books_list_screen.dart';
import '../records/records_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../spots/spot_detail_screen.dart';
import '../spots/spot_edit_screen.dart';
import '../spots/spot_list_screen.dart';
import '../talking_topics/talking_topic_detail_screen.dart';
import '../talking_topics/talking_topic_list_screen.dart';
import '../thinking/concept_dictionary_add_screen.dart';
import '../thinking/concept_dictionary_list_screen.dart';
import '../thinking/concept_memo_detail_screen.dart';
import '../thinking/philosophical_dialogue_detail_screen.dart';
import '../thinking/philosophical_dialogue_list_screen.dart';

// ─── ホーム画面 ────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _homeSections(context, _db);

    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'NOESIS',
            style: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              tooltip: 'データ書き出し',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '設定',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.colorScheme.surface, AppPalette.backgroundWarm],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SearchScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TabBar(
                        isScrollable: true,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.secondary
                            .withValues(alpha: 0.6),
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          for (final s in sections) Tab(text: s.tabLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final s in sections)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: s.isDashboard
                              ? _RecordsDashboard(db: _db)
                              : _HomeFeaturedCard(section: s, db: _db),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 検索ボタン ────────────────────────────────────────────

class _SearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.search,
          color: theme.colorScheme.secondary.withValues(alpha: 0.8),
        ),
        label: Text(
          '全体を検索',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary.withValues(alpha: 0.8),
          ),
        ),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

// ─── セクションモデル ──────────────────────────────────────

enum _SectionKind {
  dictionary,
  reading,
  listening,
  concept,
  dialogue,
  daily,
  talkingTopic,
  archive,
  spot,
  code,
}

class _HomeSection {
  final String tabLabel;
  final String title;
  final String headline;
  final String description;
  final String subtleNote;
  final List<String> tags;
  final IconData icon;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback? onAdd;
  final String? addLabel;
  final _SectionKind? kind; // null → チップなし（記録タブなど）
  final bool isDashboard;

  const _HomeSection({
    required this.tabLabel,
    required this.title,
    required this.headline,
    required this.description,
    required this.subtleNote,
    required this.tags,
    required this.icon,
    required this.accent,
    required this.onOpen,
    this.onAdd,
    this.addLabel,
    this.kind,
    this.isDashboard = false,
  });
}

// ─── フィーチャーカード（通常タブ）────────────────────────

class _HomeFeaturedCard extends StatelessWidget {
  final _HomeSection section;
  final AppDatabase db;

  const _HomeFeaturedCard({
    required this.section,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addActionLabel = section.addLabel;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アクセントバッジ
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.soften(section.accent, 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(section.icon, size: 18, color: section.accent),
                          const SizedBox(width: 8),
                          Text(
                            section.title,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: section.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      section.headline,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      section.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in section.tags)
                          Chip(
                            label: Text(tag),
                            backgroundColor: AppPalette.soften(
                              section.accent,
                              0.3,
                            ),
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: section.accent,
                              fontWeight: FontWeight.w600,
                            ),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                      ],
                    ),
                    // 直近チップ
                    if (section.kind != null)
                      _RecentChipsRow(kind: section.kind!, db: db),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: section.onOpen,
                          style: FilledButton.styleFrom(
                            backgroundColor: section.accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('開く'),
                        ),
                        if (section.onAdd != null &&
                            addActionLabel != null) ...[
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: section.onAdd,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: section.accent,
                              side: BorderSide(color: section.accent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(addActionLabel),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.subtleNote,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── 直近チップ行 ──────────────────────────────────────────

class _ChipItem {
  final String label;
  final VoidCallback onTap;
  const _ChipItem({required this.label, required this.onTap});
}

class _RecentChipsRow extends StatefulWidget {
  final _SectionKind kind;
  final AppDatabase db;
  const _RecentChipsRow({required this.kind, required this.db});

  @override
  State<_RecentChipsRow> createState() => _RecentChipsRowState();
}

class _RecentChipsRowState extends State<_RecentChipsRow> {
  late Future<List<_ChipItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ChipItem>> _load() async {
    final db = widget.db;
    switch (widget.kind) {
      case _SectionKind.dictionary:
        final rows = await (db.select(db.dictionaryEntries)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.headword,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DictionaryEntryDetailScreen(
                      dictionaryId: e.dictionaryId,
                      entryId: e.id,
                    ),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.reading:
        final rows = await (db.select(db.books)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookDetailScreen(bookId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.concept:
        final rows = await (db.select(db.conceptMemos)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title ?? e.content,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConceptMemoDetailScreen(memoId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.dialogue:
        final rows = await (db.select(db.philosophicalDialogues)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PhilosophicalDialogueDetailScreen(dialogueId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.daily:
        final rows = await (db.select(db.dailyMemos)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title ?? e.content,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DailyMemoDetailScreen(memoId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.talkingTopic:
        final rows = await (db.select(db.talkingTopics)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TalkingTopicDetailScreen(topicId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.archive:
        final rows = await (db.select(db.archiveTargets)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(6))
            .get();
        final personRows = rows
            .where((r) => r.targetType == ArchiveTargetType.person)
            .take(3)
            .toList();
        return personRows
            .map(
              (e) => _ChipItem(
                label: e.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ArchiveTargetDetailScreen(targetId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.spot:
        final rows = await (db.select(db.spots)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SpotDetailScreen(spotId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.code:
        final rows = await (db.select(db.codeEntries)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.updatedAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CodeEntryDetailScreen(entryId: e.id),
                  ),
                ),
              ),
            )
            .toList();

      case _SectionKind.listening:
        final rows = await (db.select(db.podcastEpisodes)
              ..orderBy([
                (t) => drift.OrderingTerm(
                  expression: t.createdAt,
                  mode: drift.OrderingMode.desc,
                ),
              ])
              ..limit(3))
            .get();
        return rows
            .map(
              (e) => _ChipItem(
                label: e.title,
                onTap: () {},
              ),
            )
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<_ChipItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              '最近',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items) ...[
                    ActionChip(
                      label: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: item.onTap,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── 記録ダッシュボード ────────────────────────────────────

class _DashboardData {
  final int todayCount;
  final List<int> weekCounts; // 7要素、古い順
  final List<DictionaryEntry> reviewWords;
  const _DashboardData({
    required this.todayCount,
    required this.weekCounts,
    required this.reviewWords,
  });
}

class _RecordsDashboard extends StatefulWidget {
  final AppDatabase db;
  const _RecordsDashboard({required this.db});

  @override
  State<_RecordsDashboard> createState() => _RecordsDashboardState();
}

class _RecordsDashboardState extends State<_RecordsDashboard> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final db = widget.db;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 今日の合計
    final todayCount = await _countDayEntries(
      db,
      todayStart,
      todayStart.add(const Duration(days: 1)),
    );

    // 過去7日間の日別カウント
    final weekCounts = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      weekCounts.add(
        await _countDayEntries(db, day, day.add(const Duration(days: 1))),
      );
    }

    // 復習候補（最も長く更新されていない辞書エントリ）
    final reviewWords = await (db.select(db.dictionaryEntries)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.asc,
            ),
          ])
          ..limit(5))
        .get();

    return _DashboardData(
      todayCount: todayCount,
      weekCounts: weekCounts,
      reviewWords: reviewWords,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.soften(AppPalette.thinking, 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: AppPalette.thinking,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'レコード',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppPalette.thinking,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (data != null)
                        Text(
                          '今日 ${data.todayCount} 件',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: data.todayCount > 0
                                ? AppPalette.thinking
                                : theme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 週間アクティビティ
                  Text(
                    '過去7日間',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WeeklyBar(
                    counts: data?.weekCounts ??
                        List.filled(7, 0),
                    accent: AppPalette.thinking,
                  ),
                  const SizedBox(height: 20),

                  // 復習候補
                  if (data != null && data.reviewWords.isNotEmpty) ...[
                    Text(
                      '復習候補（しばらく触っていないことば）',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final word in data.reviewWords) ...[
                            ActionChip(
                              label: Text(
                                word.headword,
                                maxLines: 1,
                              ),
                              onPressed: () =>
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DictionaryEntryDetailScreen(
                                            dictionaryId: word.dictionaryId,
                                            entryId: word.id,
                                          ),
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ボタン
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RecordsScreen(),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppPalette.thinking,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('記録を見る'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// 週間アクティビティバー（7日分のドット）
class _WeeklyBar extends StatelessWidget {
  final List<int> counts;
  final Color accent;
  const _WeeklyBar({required this.counts, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = ['月', '火', '水', '木', '金', '土', '日'];
    final maxCount = counts.isEmpty ? 1 : counts.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = DateTime.now().subtract(Duration(days: 6 - i));
        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;
        final count = i < counts.length ? counts[i] : 0;
        final ratio = maxCount == 0 ? 0.0 : count / maxCount;

        return Expanded(
          child: Column(
            children: [
              // バー
              Container(
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: count == 0 ? 4 : 4 + (28 * ratio),
                    decoration: BoxDecoration(
                      color: count == 0
                          ? theme.colorScheme.outline.withValues(alpha: 0.15)
                          : isToday
                              ? accent
                              : accent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[day.weekday - 1],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isToday
                      ? accent
                      : theme.colorScheme.secondary.withValues(alpha: 0.6),
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              if (count > 0)
                Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── セクション一覧 ────────────────────────────────────────

List<_HomeSection> _homeSections(BuildContext context, AppDatabase db) {
  return [
    _HomeSection(
      tabLabel: '辞書',
      title: '辞書アーカイブ',
      headline: '言葉を、研ぎ澄ます。',
      description: '用語の定義や関連語を育てて、知識の芯を残す。',
      subtleNote: '定義・類義語・タグ',
      tags: const ['一般', '英語', 'IT用語'],
      icon: Icons.menu_book_outlined,
      accent: AppPalette.dictionaryGeneral,
      kind: _SectionKind.dictionary,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DictionaryScreen()),
      ),
      onAdd: () => _showDictionaryEntryPicker(context),
      addLabel: '辞書を追加',
    ),
    _HomeSection(
      tabLabel: '読書',
      title: '読書アーカイブ',
      headline: '本から引き出す。',
      description: '本文の抜粋と考えを分けて、学びを深く定着させる。',
      subtleNote: '書籍・メモ・抜粋',
      tags: const ['書籍', 'メモ', '要約'],
      icon: Icons.auto_stories_outlined,
      accent: AppPalette.reading,
      kind: _SectionKind.reading,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BooksListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BookAddScreen()),
      ),
      addLabel: '本を追加',
    ),
    _HomeSection(
      tabLabel: '音声',
      title: '音声記録',
      headline: '聴いた知識を、残す。',
      description:
          'ポッドキャスト・YouTube・録音などを文字起こしし、クリップや要約で知識として蓄える。',
      subtleNote: 'Whisper・字幕取得・AI要約',
      tags: const ['ポッドキャスト', 'YouTube', '文字起こし'],
      icon: Icons.headphones_outlined,
      accent: AppPalette.listening,
      kind: _SectionKind.listening,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ListeningScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EpisodeAddScreen()),
      ),
      addLabel: '音声を追加',
    ),
    _HomeSection(
      tabLabel: '概念',
      title: '概念辞書',
      headline: '思考の骨格を作る。',
      description: '概念同士の関係性を整理し、理解の輪郭をはっきりさせる。',
      subtleNote: '概念・関連・対比',
      tags: const ['概念', '構造', '対比'],
      icon: Icons.scatter_plot_outlined,
      accent: AppPalette.thinking,
      kind: _SectionKind.concept,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConceptDictionaryListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConceptDictionaryAddScreen()),
      ),
      addLabel: '概念を追加',
    ),
    _HomeSection(
      tabLabel: '対話',
      title: '哲学的対話',
      headline: '問いを掘り下げる。',
      description: '選んだ思考スタイルと対話し、視点を広げる。',
      subtleNote: '対話ログ・要約',
      tags: const ['対話', '問い', '視点'],
      icon: Icons.forum_outlined,
      accent: AppPalette.thinking,
      kind: _SectionKind.dialogue,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PhilosophicalDialogueListScreen(),
        ),
      ),
      onAdd: () async {
        final localDb = AppDatabase();
        final id = await localDb.philosophicalDialoguesDao.createDialogue(
          PhilosophicalDialoguesCompanion.insert(title: '無題の対話'),
        );
        localDb.close();
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhilosophicalDialogueDetailScreen(
              dialogueId: id,
              isDraft: true,
            ),
          ),
        );
      },
      addLabel: '対話を追加',
    ),
    _HomeSection(
      tabLabel: '日常',
      title: '日常メモ',
      headline: '日々の気づきを残す。',
      description: '短い思考や出来事を、軽く記録して流れを掴む。',
      subtleNote: '短文・タスク・記録',
      tags: const ['メモ', '習慣', '記録'],
      icon: Icons.edit_note,
      accent: AppPalette.daily,
      kind: _SectionKind.daily,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyMemoScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DailyMemoAddScreen()),
      ),
      addLabel: 'メモを追加',
    ),
    _HomeSection(
      tabLabel: '話材',
      title: '話材アーカイブ',
      headline: '雑談の引き出しを育てる。',
      description: '会話で使える小ネタや雑学を整えて、話しやすい形で貯める。',
      subtleNote: '小ネタ・雑学・話し方',
      tags: const ['雑談', '雑学', '小話'],
      icon: Icons.record_voice_over_outlined,
      accent: AppPalette.talkingTopic,
      kind: _SectionKind.talkingTopic,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TalkingTopicListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TalkingTopicListScreen()),
      ),
      addLabel: '話材を見る',
    ),
    _HomeSection(
      tabLabel: '知人',
      title: '知人アーカイブ',
      headline: '人を、理解する。',
      description: '知人との記録や観察を残して、あとから人物理解を深める。',
      subtleNote: '知人・観察・関係',
      tags: const ['知人', '人物理解', '記録'],
      icon: Icons.person_search_outlined,
      accent: AppPalette.archive,
      kind: _SectionKind.archive,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ArchiveTargetListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ArchiveTargetAddScreen()),
      ),
      addLabel: '知人を追加',
    ),
    _HomeSection(
      tabLabel: 'スポット',
      title: 'スポットアーカイブ',
      headline: '場所を、使いこなす。',
      description: '店や場所の雰囲気、使いどころ、訪問履歴を残して再訪しやすくする。',
      subtleNote: '場所・店・訪問履歴',
      tags: const ['喫茶店', 'バー', '店', 'スポット'],
      icon: Icons.place_outlined,
      accent: AppPalette.archive,
      kind: _SectionKind.spot,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SpotListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SpotEditScreen()),
      ),
      addLabel: 'スポットを追加',
    ),
    _HomeSection(
      tabLabel: 'ITコード',
      title: 'ITコード学習',
      headline: 'コードを理解する。',
      description: '画像から学びを抽出し、AIで構造理解を深める。',
      subtleNote: 'OCR・構造解析',
      tags: const ['OCR', 'AI解説', '知識'],
      icon: Icons.code,
      accent: AppPalette.code,
      kind: _SectionKind.code,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CodeEntryListScreen()),
      ),
      onAdd: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CodeEntryAddScreen()),
      ),
      addLabel: 'コードを追加',
    ),
    // 記録タブ — ダッシュボード専用（チップなし）
    _HomeSection(
      tabLabel: '記録',
      title: 'レコード',
      headline: '積み上げを眺める。',
      description: 'カレンダーで記録を振り返り、復習やクイズに繋げる。',
      subtleNote: 'カレンダー・復習',
      tags: const [],
      icon: Icons.calendar_month_outlined,
      accent: AppPalette.thinking,
      isDashboard: true,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecordsScreen()),
      ),
    ),
  ];
}

// ─── ヘルパー ──────────────────────────────────────────────

Future<int> _countDayEntries(
  AppDatabase db,
  DateTime start,
  DateTime end,
) async {
  Future<int> countRows<T extends drift.Table>(
    drift.TableInfo<T, dynamic> table,
    drift.Expression<DateTime> column,
  ) async {
    final countColumn = table.$primaryKey.first.count();
    final row = await (db.selectOnly(table)
          ..addColumns([countColumn])
          ..where(
            column.isBiggerOrEqualValue(start) &
                column.isSmallerThanValue(end),
          ))
        .getSingle();
    return row.read(countColumn) ?? 0;
  }

  var total = 0;
  total += await countRows(db.dictionaryEntries, db.dictionaryEntries.createdAt);
  total += await countRows(db.readingMemos, db.readingMemos.createdAt);
  total += await countRows(db.dailyMemos, db.dailyMemos.createdAt);
  total += await countRows(db.conceptMemos, db.conceptMemos.createdAt);
  total += await countRows(
    db.philosophicalDialogues,
    db.philosophicalDialogues.createdAt,
  );
  total += await countRows(db.codeEntries, db.codeEntries.createdAt);
  total += await countRows(db.books, db.books.createdAt);
  total += await countRows(db.archiveTargets, db.archiveTargets.createdAt);
  total += await countRows(db.spots, db.spots.createdAt);
  return total;
}

// ─── 辞書選択ボトムシート ──────────────────────────────────

Future<void> _showDictionaryEntryPicker(BuildContext context) async {
  final db = AppDatabase();
  List<DictionaryDefinition> dictionaries = [];
  try {
    dictionaries = await db.dictionariesDao.getAllDictionaries();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('辞書一覧の取得に失敗しました')),
      );
    }
  } finally {
    db.close();
  }

  if (!context.mounted) return;

  if (dictionaries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('辞書がまだありません')),
    );
    return;
  }

  final selectedId = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'どの辞書に追加しますか？',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dictionaries.map((dict) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(dict.name),
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(dict.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '横にスクロールして選択',
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(sheetContext)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    },
  );

  if (selectedId == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DictionaryEntryEditScreen(dictionaryId: selectedId),
    ),
  );
}
