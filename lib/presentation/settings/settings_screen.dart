import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_config_service.dart';
import '../../core/ai/local_llm_model_info.dart';
import '../../core/ai/local_model_downloader.dart';
import '../../core/integrations/notion_client.dart';
import '../../core/theme/app_palette.dart';
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

          // ── データバックアップ & 復元 ────────────────────────
          _SectionHeader(label: 'バックアップ & 復元'),
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
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'データ保存・全復元',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'アプリ全体のデータをファイルアプリへバックアップ保存、または既存のバックアップファイルから全復元します。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportBackup,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: Text(_isBusy ? '処理中...' : 'バックアップ作成'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _importBackup,
                          icon: const Icon(Icons.file_open_rounded, size: 18),
                          label: Text(_isBusy ? '処理中...' : 'データを復元'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── データファイル出力 (CSV / TXT) ─────────────────────
          _SectionHeader(label: 'ファイル出力 (CSV / TXT)'),
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
                  Row(
                    children: [
                      const Icon(Icons.table_chart_outlined, color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Excel / テキストデータ出力',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '対話・辞書・読書・日常メモ等のデータを表計算ソフトやテキストで閲覧可能な形式で書き出します。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // メインの一括出力アクション
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBusy ? null : _exportAllCsv,
                          icon: const Icon(Icons.table_view_outlined, size: 18),
                          label: const Text('全データ CSV'),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportAllText,
                          icon: const Icon(Icons.text_snippet_outlined, size: 18),
                          label: const Text('全データ TXT'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  Text(
                    '個別データの出力',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportDialoguesCsv,
                          icon: const Icon(Icons.forum_outlined, size: 16),
                          label: const Text('対話 CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _exportDictionariesCsv,
                          icon: const Icon(Icons.menu_book_outlined, size: 16),
                          label: const Text('辞書 CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
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
          _SectionHeader(label: 'AI設定 (ローカルLLM / API切替)'),
          const _AISettingsCard(),
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

// ── AI設定インタラクティブカード ──────────────────────────

class _AISettingsCard extends StatefulWidget {
  const _AISettingsCard();

  @override
  State<_AISettingsCard> createState() => _AISettingsCardState();
}

class _AISettingsCardState extends State<_AISettingsCard> {
  AIConfigService? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AIConfigService.getInstance();
    if (mounted) {
      setState(() {
        _config = config;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeProvider(AIProviderType type) async {
    if (_config == null) return;
    await _config!.setProviderType(type);
    await AIClient.initialize();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIプロバイダーを「${type.label}」に変更しました')),
      );
    }
  }

  Future<void> _editApiKey(AIProviderType type) async {
    if (_config == null) return;
    final isOpenAI = type == AIProviderType.openAI;
    final currentKey =
        isOpenAI ? _config!.openAIApiKey : _config!.geminiApiKey;
    final controller = TextEditingController(text: currentKey);

    final newKey = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${type.label} Key 設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'お持ちの ${isOpenAI ? "OpenAI" : "Gemini"} API キーを入力してください。',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API キー',
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (newKey != null) {
      if (isOpenAI) {
        await _config!.setOpenAIApiKey(newKey);
      } else {
        await _config!.setGeminiApiKey(newKey);
      }
      await AIClient.initialize();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APIキーを更新しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Theme.of(context);
    final currentType = _config!.providerType;
    final activeProviderName = AIClient.instance.providerName;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  '現在のAIエンジン',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activeProviderName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AIProviderType>(
              isExpanded: true,
              initialValue: currentType,
              decoration: const InputDecoration(
                labelText: '使用するAIプロバイダー',
              ),
              items: AIProviderType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) _changeProvider(val);
              },
            ),
            const SizedBox(height: 8),
            Text(
              currentType.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // プロバイダー固有の設定
            if (currentType == AIProviderType.localLlm) ...[
              DropdownButtonFormField<LocalModelPreset>(
                isExpanded: true,
                initialValue: _config!.activeModelPreset,
                decoration: const InputDecoration(
                  labelText: '使用するローカルモデル (品質/速度)',
                ),
                items: LocalModelPreset.values
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset,
                        child: Text(
                          '${preset.name} (${preset.sizeDescription})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (preset) async {
                  if (preset != null) {
                    await _config!.setActiveModelPreset(preset);
                    await AIClient.initialize();
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('モデルを「${preset.name}」に変更しました')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.thinking, 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _config!.activeModelPreset.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '推奨用途: ${_config!.activeModelPreset.recommendedFor}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _config!.isQualityPriorityMode,
                onChanged: (val) async {
                  await _config!.setQualityPriorityMode(val);
                  if (mounted) setState(() {});
                },
                title: const Text('タスク別クオリティ自動最適化'),
                subtitle: const Text('思考対話や高度解説時に、高品質3Bモデルへ自動ルーティングします'),
              ),
            ] else if (currentType == AIProviderType.openAI) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key, color: Colors.amber),
                title: const Text('OpenAI API キー (BYOK)'),
                subtitle: Text(
                  _config!.openAIApiKey.isNotEmpty
                      ? 'キー設定済み (...${_config!.openAIApiKey.length > 6 ? _config!.openAIApiKey.substring(_config!.openAIApiKey.length - 4) : ""})'
                      : '未設定 (設定しない場合は.envが使用されます)',
                ),
                trailing: OutlinedButton(
                  onPressed: () => _editApiKey(AIProviderType.openAI),
                  child: const Text('編集'),
                ),
              ),
            ] else if (currentType == AIProviderType.gemini) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key, color: Colors.purple),
                title: const Text('Gemini API キー (BYOK)'),
                subtitle: Text(
                  _config!.geminiApiKey.isNotEmpty
                      ? 'キー設定済み'
                      : '未設定 (設定しない場合はOpenAIが使用されます)',
                ),
                trailing: OutlinedButton(
                  onPressed: () => _editApiKey(AIProviderType.gemini),
                  child: const Text('編集'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

