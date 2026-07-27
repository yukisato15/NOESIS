import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ai/ai_client.dart';
import '../../core/integrations/notion_client.dart';
import '../../core/utils/data_backup_service.dart';
import '../../core/utils/data_export_service.dart';
import '../../core/utils/spot_photo_service.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/archive_targets_table.dart';
import '../archive/archive_target_detail_screen.dart';
import '../code/code_entry_detail_screen.dart';
import '../daily/daily_memo_detail_screen.dart';
import '../dictionary/dictionary_entry_detail_screen.dart';
import '../reading/book_detail_screen.dart';
import '../reading/reading_memo_detail_screen.dart';
import '../search/search_screen.dart';
import '../spots/spot_detail_screen.dart';
import '../thinking/concept_memo_detail_screen.dart';
import '../thinking/philosophical_dialogue_detail_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppDatabase _db = AppDatabase();
  late Future<_QuickInfo> _quickInfoFuture;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _quickInfoFuture = _loadQuickInfo(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  // ── バックアップ ────────────────────────────────
  Future<void> _exportBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _isBusy = true);
    try {
      final file = await DataBackupService.exportDatabase();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NOESISのバックアップファイルです',
        sharePositionOrigin: box == null
            ? null
            : (box.localToGlobal(Offset.zero) & box.size),
      );
      messenger.showSnackBar(const SnackBar(content: Text('バックアップを書き出しました')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('書き出しに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _importBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (picked == null) return;
    final file = picked.files.single;
    final fileName = file.name.toLowerCase();
    final isDbFile =
        (file.extension?.toLowerCase() == 'db') || fileName.endsWith('.db');
    if (!isDbFile) {
      messenger.showSnackBar(
        const SnackBar(content: Text('拡張子が .db のバックアップを選択してください')),
      );
      return;
    }
    var path = file.path;
    if ((path == null || path.isEmpty) && file.bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/${file.name}';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(file.bytes!);
      path = tempPath;
    }
    if (path == null || path.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ファイルを読み込めませんでした')),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップを復元'),
        content: const Text(
          '端末のデータをバックアップで上書きします。\n復元後はアプリを再起動してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('復元'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    try {
      await DataBackupService.importDatabase(path);
      messenger.showSnackBar(
        const SnackBar(content: Text('復元が完了しました。アプリを再起動してください。')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportDialoguesCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _isBusy = true);
    try {
      final file = await DataExportService.exportDialoguesCsv();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NOESIS 対話データ（CSV）',
        sharePositionOrigin: box == null
            ? null
            : (box.localToGlobal(Offset.zero) & box.size),
      );
      messenger.showSnackBar(const SnackBar(content: Text('対話CSVを書き出しました')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('対話CSVの書き出しに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportDictionariesCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _isBusy = true);
    try {
      final file = await DataExportService.exportDictionariesCsv();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NOESIS 辞書データ（CSV）',
        sharePositionOrigin: box == null
            ? null
            : (box.localToGlobal(Offset.zero) & box.size),
      );
      messenger.showSnackBar(const SnackBar(content: Text('辞書CSVを書き出しました')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('辞書CSVの書き出しに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportAllCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _isBusy = true);
    try {
      final files = await DataExportService.exportAllCsv();
      await Share.shareXFiles(
        files.map((f) => XFile(f.path)).toList(),
        text: 'NOESIS 全アーカイブデータ（CSV）',
        sharePositionOrigin: box == null
            ? null
            : (box.localToGlobal(Offset.zero) & box.size),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('CSVを書き出しました（${files.length}ファイル）')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('CSV書き出しに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _exportAllText() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _isBusy = true);
    try {
      final file = await DataExportService.exportAllText();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'NOESIS エクスポート一覧（TXT）',
        sharePositionOrigin: box == null
            ? null
            : (box.localToGlobal(Offset.zero) & box.size),
      );
      messenger.showSnackBar(const SnackBar(content: Text('TXTを書き出しました')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('TXT書き出しに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── 最近触った場所ナビゲーション ──────────────────
  Future<void> _openRecentItem(BuildContext context, _RecentItem item) async {
    switch (item.kind) {
      case _ItemKind.dictionaryEntry:
        if (item.secondaryId == null) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DictionaryEntryDetailScreen(
            dictionaryId: item.secondaryId!,
            entryId: item.primaryId,
          ),
        ));
      case _ItemKind.readingMemo:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReadingMemoDetailScreen(
            memoId: item.primaryId,
            bookTitle: '読書メモ',
          ),
        ));
      case _ItemKind.dailyMemo:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DailyMemoDetailScreen(memoId: item.primaryId),
        ));
      case _ItemKind.conceptMemo:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConceptMemoDetailScreen(memoId: item.primaryId),
        ));
      case _ItemKind.dialogue:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              PhilosophicalDialogueDetailScreen(dialogueId: item.primaryId),
        ));
      case _ItemKind.codeEntry:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CodeEntryDetailScreen(entryId: item.primaryId),
        ));
      case _ItemKind.book:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: item.primaryId),
        ));
      case _ItemKind.archiveTarget:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ArchiveTargetDetailScreen(targetId: item.primaryId),
        ));
      case _ItemKind.spot:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SpotDetailScreen(spotId: item.primaryId),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── 最近触った場所 ──────────────────────────
          _SectionHeader(label: '最近触った場所'),
          FutureBuilder<_QuickInfo>(
            future: _quickInfoFuture,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final recent = info?.recent;
              return _SettingsTile(
                icon: Icons.history,
                title: recent == null
                    ? 'まだ記録がありません'
                    : '${recent.subtitle}・${recent.title}',
                subtitle: recent == null
                    ? null
                    : _formatDate(recent.updatedAt),
                onTap: recent == null
                    ? null
                    : () => _openRecentItem(context, recent),
              );
            },
          ),
          const SizedBox(height: 16),

          // ── 今日の入口 ──────────────────────────────
          _SectionHeader(label: '今日の入口'),
          FutureBuilder<_QuickInfo>(
            future: _quickInfoFuture,
            builder: (context, snapshot) {
              final count = snapshot.data?.todayCount ?? 0;
              return _SettingsTile(
                icon: Icons.calendar_today,
                title: '今日の記録 $count 件',
                subtitle: '全カテゴリの今日の入力数',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // ── データ書き出し ──────────────────────────
          _SectionHeader(label: 'データ書き出し'),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'バックアップをファイルアプリに保存し、必要なときに復元できます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportBackup,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_isBusy ? '処理中...' : '書き出し'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _importBackup,
                          icon: const Icon(Icons.file_open),
                          label: Text(_isBusy ? '処理中...' : '復元'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportDialoguesCsv,
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text('対話CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportDictionariesCsv,
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('辞書CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _exportAllCsv,
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('全CSV'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isBusy ? null : _exportAllText,
                      icon: const Icon(Icons.text_snippet_outlined),
                      label: const Text('全TXT（CSV一覧）'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '全CSVは対話・辞書・概念辞書・読書・日常・ITコードを出力します。CSVはExcelでも開けます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Notion連携 ───────────────────────────────
          _SectionHeader(label: 'Notion連携'),
          _SettingsTile(
            icon: Icons.link,
            title: 'Notion API キー',
            subtitle: NotionClient.isConfigured
                ? '設定済み（.env の NOTION_API_KEY）'
                : '未設定 — .env に NOTION_API_KEY を追加してください',
            trailing: Icon(
              NotionClient.isConfigured
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: NotionClient.isConfigured ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),

          // ── AI設定 ───────────────────────────────────
          _SectionHeader(label: 'AI設定'),
          _SettingsTile(
            icon: Icons.smart_toy_outlined,
            title: 'OpenAI API キー',
            subtitle: AIClient.isConfigured
                ? '設定済み（.env の OPENAI_API_KEY）'
                : '未設定 — .env に OPENAI_API_KEY を追加してください',
            trailing: Icon(
              AIClient.isConfigured
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              color: AIClient.isConfigured ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          _SettingsTile(
            icon: Icons.search,
            title: 'Google 検索',
            subtitle: (dotenv.env['GOOGLE_API_KEY'] ?? '').isNotEmpty
                ? '設定済み（GOOGLE_API_KEY / GOOGLE_SEARCH_ENGINE_ID）'
                : '未設定 — .env に GOOGLE_API_KEY を追加すると AI 検索が強化されます',
            trailing: Icon(
              (dotenv.env['GOOGLE_API_KEY'] ?? '').isNotEmpty
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: (dotenv.env['GOOGLE_API_KEY'] ?? '').isNotEmpty
                  ? Colors.green
                  : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),

          // ── ストレージ ────────────────────────────────
          _SectionHeader(label: 'ストレージ'),
          FutureBuilder<int>(
            future: SpotPhotoService.totalBytes(),
            builder: (context, snapshot) {
              final bytes = snapshot.data ?? 0;
              final mb = (bytes / 1024 / 1024).toStringAsFixed(1);
              return _SettingsTile(
                icon: Icons.photo_library_outlined,
                title: 'スポット写真',
                subtitle: '$mb MB 使用中',
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── データクラス ────────────────────────────────────────

class _QuickInfo {
  final _RecentItem? recent;
  final int todayCount;
  const _QuickInfo({required this.recent, required this.todayCount});
}

class _RecentItem {
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final _ItemKind kind;
  final int primaryId;
  final int? secondaryId;

  const _RecentItem({
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.kind,
    required this.primaryId,
    this.secondaryId,
  });
}

enum _ItemKind {
  dictionaryEntry,
  readingMemo,
  dailyMemo,
  conceptMemo,
  dialogue,
  codeEntry,
  book,
  archiveTarget,
  spot,
}

// ── データ読み込み ───────────────────────────────────────

Future<_QuickInfo> _loadQuickInfo(AppDatabase db) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  final candidates = <_RecentItem>[];

  Future<void> addCandidate<T>({
    required Future<T?> query,
    required _RecentItem? Function(T) map,
  }) async {
    final row = await query;
    if (row != null) {
      final item = map(row);
      if (item != null) candidates.add(item);
    }
  }

  await addCandidate(
    query: (db.select(db.dictionaryEntries)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) {
      return _RecentItem(
        title: e.headword,
        subtitle: '辞書',
        updatedAt: e.updatedAt,
        kind: _ItemKind.dictionaryEntry,
        primaryId: e.id,
        secondaryId: e.dictionaryId,
      );
    },
  );

  await addCandidate(
    query: (db.select(db.readingMemos)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.createdAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.thoughtText,
      subtitle: '読書メモ',
      updatedAt: e.createdAt,
      kind: _ItemKind.readingMemo,
      primaryId: e.id,
      secondaryId: e.bookId,
    ),
  );

  await addCandidate(
    query: (db.select(db.dailyMemos)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.title ?? e.content,
      subtitle: '日常メモ',
      updatedAt: e.updatedAt,
      kind: _ItemKind.dailyMemo,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.conceptMemos)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.title ?? e.content,
      subtitle: '概念メモ',
      updatedAt: e.updatedAt,
      kind: _ItemKind.conceptMemo,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.philosophicalDialogues)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.title,
      subtitle: '哲学的対話',
      updatedAt: e.updatedAt,
      kind: _ItemKind.dialogue,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.codeEntries)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.title,
      subtitle: 'ITコード学習',
      updatedAt: e.updatedAt,
      kind: _ItemKind.codeEntry,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.books)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.title,
      subtitle: '読書アーカイブ',
      updatedAt: e.updatedAt,
      kind: _ItemKind.book,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.archiveTargets)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ]))
        .get()
        .then(
          (rows) => rows
              .where((r) => r.targetType == ArchiveTargetType.person)
              .cast<ArchiveTarget?>()
              .firstWhere((_) => true, orElse: () => null),
        ),
    map: (e) => _RecentItem(
      title: e.name,
      subtitle: '知人アーカイブ',
      updatedAt: e.updatedAt,
      kind: _ItemKind.archiveTarget,
      primaryId: e.id,
    ),
  );

  await addCandidate(
    query: (db.select(db.spots)
          ..orderBy([
            (t) => drift.OrderingTerm(
              expression: t.updatedAt,
              mode: drift.OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull(),
    map: (e) => _RecentItem(
      title: e.name,
      subtitle: 'スポットアーカイブ',
      updatedAt: e.updatedAt,
      kind: _ItemKind.spot,
      primaryId: e.id,
    ),
  );

  _RecentItem? recent;
  for (final c in candidates) {
    if (recent == null || c.updatedAt.isAfter(recent.updatedAt)) {
      recent = c;
    }
  }

  final todayCount = await _countTodayEntries(db, todayStart, tomorrowStart);
  return _QuickInfo(recent: recent, todayCount: todayCount);
}

Future<int> _countTodayEntries(
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

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  return '${dt.month}/${dt.day}';
}

// ── 汎用ウィジェット ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
