import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/podcast_episodes_table.dart';
import 'audio_content_add_screen.dart';
import 'episode_detail_screen.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();

  List<PodcastEpisode> _episodes = [];
  List<PodcastEpisode> _filtered = [];
  List<String> _programs = [];
  String? _selectedProgram;
  EpisodeSourceType? _selectedType;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final episodes = await _db.podcastEpisodesDao.getAllEpisodes();
    final programs = await _db.podcastEpisodesDao.getAllProgramNames();
    if (!mounted) return;
    setState(() {
      _episodes = episodes;
      _programs = programs;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _episodes.where((e) {
        final matchQuery = query.isEmpty ||
            e.title.toLowerCase().contains(query) ||
            (e.programName?.toLowerCase().contains(query) ?? false) ||
            (e.speaker?.toLowerCase().contains(query) ?? false) ||
            (e.transcript?.toLowerCase().contains(query) ?? false);
        final matchProgram =
            _selectedProgram == null || e.programName == _selectedProgram;
        final matchType =
            _selectedType == null || e.sourceType == _selectedType;
        return matchQuery && matchProgram && matchType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('音声記録'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '音声コンテンツを追加',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AudioContentAddScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索（タイトル・番組名・トランスクリプト）',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          // フィルターチップ（ソース種別）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'すべて',
                  selected: _selectedType == null,
                  onTap: () {
                    setState(() => _selectedType = null);
                    _applyFilter();
                  },
                ),
                for (final type in EpisodeSourceType.values)
                  _FilterChip(
                    label: type.label,
                    selected: _selectedType == type,
                    onTap: () {
                      setState(() =>
                          _selectedType = _selectedType == type ? null : type);
                      _applyFilter();
                    },
                  ),
              ],
            ),
          ),
          // 番組フィルター
          if (_programs.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  for (final program in _programs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(program),
                        selected: _selectedProgram == program,
                        onSelected: (v) {
                          setState(() =>
                              _selectedProgram = v ? program : null);
                          _applyFilter();
                        },
                        backgroundColor: AppPalette.soften(
                            AppPalette.listening, 0.85),
                        selectedColor: AppPalette.soften(
                            AppPalette.listening, 0.5),
                        labelStyle: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyState(
                        hasData: _episodes.isNotEmpty,
                        onAdd: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AudioContentAddScreen()),
                          );
                          _load();
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final ep = _filtered[i];
                          return _EpisodeCard(
                            episode: ep,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EpisodeDetailScreen(episodeId: ep.id),
                                ),
                              );
                              _load();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppPalette.listening,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AudioContentAddScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── フィルターチップ ────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.listening
                : AppPalette.soften(AppPalette.listening, 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : AppPalette.listening,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── エピソードカード ────────────────────────────────────────

class _EpisodeCard extends StatelessWidget {
  final PodcastEpisode episode;
  final VoidCallback onTap;

  const _EpisodeCard({required this.episode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy/MM/dd');
    final hasTranscript =
        episode.transcript != null && episode.transcript!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.listening, 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    _sourceIcon(episode.sourceType),
                    color: AppPalette.listening,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (episode.programName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        episode.programName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.listening,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppPalette.soften(
                                AppPalette.listening, 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            episode.sourceType.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppPalette.listening,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasTranscript)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '文字起こし済',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          fmt.format(episode.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    if (episode.summary != null &&
                        episode.summary!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        episode.summary!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary
                              .withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _sourceIcon(EpisodeSourceType type) {
    switch (type) {
      case EpisodeSourceType.youtube:
        return Icons.smart_display_outlined;
      case EpisodeSourceType.podcast:
        return Icons.podcasts;
      case EpisodeSourceType.file:
        return Icons.audio_file_outlined;
      case EpisodeSourceType.recording:
        return Icons.mic_outlined;
      case EpisodeSourceType.text:
        return Icons.text_fields;
    }
  }
}

// ─── 空状態 ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasData;
  final VoidCallback onAdd;

  const _EmptyState({required this.hasData, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_outlined,
              size: 64,
              color: AppPalette.listening.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasData ? '検索結果がありません' : '音声記録がありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasData
                  ? '別のキーワードで試してください'
                  : 'ポッドキャスト・YouTube・音声ファイルなどを\n文字起こしして記録できます',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                height: 1.6,
              ),
            ),
            if (!hasData) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('追加する'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.listening,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
