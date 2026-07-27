import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/talking_topics_table.dart';
import '../shared/surface_field.dart';
import 'talking_topic_detail_screen.dart';
import 'talking_topic_edit_screen.dart';
import 'talking_topic_extract_screen.dart';

class TalkingTopicListScreen extends StatefulWidget {
  const TalkingTopicListScreen({super.key});

  @override
  State<TalkingTopicListScreen> createState() => _TalkingTopicListScreenState();
}

class _TalkingTopicListScreenState extends State<TalkingTopicListScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();

  List<TalkingTopic> _topics = [];
  List<TalkingTopic> _filtered = [];
  String? _genreFilter;
  bool _isLoading = true;
  bool _isGeneratingIdea = false;

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
    final topics = await _db.talkingTopicsDao.getAllTopics();
    if (!mounted) {
      return;
    }
    setState(() {
      _topics = topics;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = _topics.where((topic) {
      if (_genreFilter != null && _genreFilter != topic.genre) {
        return false;
      }
      final bag = [
        topic.title,
        topic.hook ?? '',
        topic.corePoint ?? '',
        topic.genre ?? '',
        topic.tags ?? '',
      ].join('\n').toLowerCase();
      if (keyword.isNotEmpty && !bag.contains(keyword)) {
        return false;
      }
      return true;
    }).toList();
    setState(() => _filtered = filtered);
  }

  List<String> _genres() {
    final genres =
        _topics
            .map((e) => e.genre?.trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return genres;
  }

  List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('話材アーカイブ'),
        actions: [
          IconButton(
            onPressed: _isGeneratingIdea ? null : _generateIdeaWithAi,
            icon: _isGeneratingIdea
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lightbulb_outline),
            tooltip: 'AIで話材を考える',
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TalkingTopicExtractScreen(),
                ),
              );
              await _load();
            },
            icon: const Icon(Icons.auto_awesome),
            tooltip: '他アーカイブから抽出',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TalkingTopicEditScreen()),
          );
          await _load();
        },
        backgroundColor: AppPalette.talkingTopic,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('話材を追加'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SurfaceField(
                    label: '検索',
                    controller: _searchController,
                    hintText: 'タイトル、フック、ジャンル、タグ',
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('すべて'),
                          selected: _genreFilter == null,
                          onSelected: (_) {
                            setState(() => _genreFilter = null);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        for (final genre in _genres()) ...[
                          FilterChip(
                            label: Text(genre),
                            selected: _genreFilter == genre,
                            onSelected: (_) {
                              setState(() => _genreFilter = genre);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    SurfaceCard(
                      child: Text(
                        'まだ話材がありません。手入力するか、他アーカイブから抽出できます。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  for (final topic in _filtered) ...[
                    GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TalkingTopicDetailScreen(topicId: topic.id),
                          ),
                        );
                        await _load();
                      },
                      child: SurfaceCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((topic.hook ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                topic.hook!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if ((topic.genre ?? '').isNotEmpty)
                                  _MetaChip(label: topic.genre!),
                                _MetaChip(label: _toneLabel(topic.tone)),
                                _MetaChip(
                                  label: _difficultyLabel(topic.difficulty),
                                ),
                                ..._decodeTags(
                                  topic.tags,
                                ).take(3).map((e) => _MetaChip(label: e)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _toneLabel(TalkingTopicTone tone) {
    switch (tone) {
      case TalkingTopicTone.light:
        return '軽い';
      case TalkingTopicTone.balanced:
        return '中間';
      case TalkingTopicTone.intellectual:
        return '知的';
      case TalkingTopicTone.funny:
        return '面白め';
    }
  }

  String _difficultyLabel(TalkingTopicDifficulty difficulty) {
    switch (difficulty) {
      case TalkingTopicDifficulty.easy:
        return '軽い';
      case TalkingTopicDifficulty.medium:
        return '普通';
      case TalkingTopicDifficulty.deep:
        return '深い';
    }
  }

  Future<void> _generateIdeaWithAi() async {
    if (!AIClient.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI設定が未構成です')));
      return;
    }

    final themeController = TextEditingController();
    final audienceController = TextEditingController();
    bool useWebResearch = SearchClient.canUseWebSearch;
    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('AIで話材を考える'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SurfaceField(
                    label: 'テーマ',
                    hintText: '例: 宇宙、江戸文化、コーヒー、動物',
                    controller: themeController,
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '想定相手・場面（任意）',
                    hintText: '例: 初対面、飲み会、知的雑談',
                    controller: audienceController,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Webリサーチあり')),
                      ButtonSegment(value: false, label: Text('Webリサーチなし')),
                    ],
                    selected: {useWebResearch},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      final selected = selection.first;
                      if (selected && !SearchClient.canUseWebSearch) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Webリサーチは検索設定が必要です')),
                        );
                        return;
                      }
                      setStateDialog(() => useWebResearch = selected);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('生成'),
                ),
              ],
            );
          },
        );
      },
    );
    final theme = themeController.text.trim();
    final audience = audienceController.text.trim();
    themeController.dispose();
    audienceController.dispose();

    if (choice != true || theme.isEmpty) {
      return;
    }

    setState(() => _isGeneratingIdea = true);
    try {
      final mode = useWebResearch ? AIMode.withSearch : AIMode.standard;
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは「会話で使える雑学・小ネタ」を作る編集者です。
${useWebResearch ? '必ず Web 検索結果で確認できる事実だけを使って、話材を1件作ってください。' : 'Web検索は使わず、一般知識ベースで話材を1件作ってください。確信が低い内容は断定しないでください。'}

テーマ: $theme
想定相手・場面: ${audience.isEmpty ? '未指定' : audience}

重要ルール:
- ハルシネーション禁止
- ${useWebResearch ? '検索結果で裏づけできた事実だけを書く' : '不確かな内容は断定しない'}
- ${useWebResearch ? '根拠が弱い場合は can_generate=false を返す' : '推測が混じる場合は source_note にその旨を書く'}
- 誇張しない
- 雑談で使える自然な話材にする
- source_note には、根拠にしたURLや出典名を短くまとめる
- citations には URL または出典名を配列で返す

作る内容:
- can_generate
- title
- hook
- core_point
- body
- twist
- use_case
- genre
- tags
- best_for
- avoid_for
- delivery_30s
- delivery_1m
- delivery_casual
- follow_up_question
- escape_line
- source_note
- citations
- credibility_score
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'can_generate': {'type': 'boolean'},
            'title': {'type': 'string'},
            'hook': {'type': 'string'},
            'core_point': {'type': 'string'},
            'body': {'type': 'string'},
            'twist': {'type': 'string'},
            'use_case': {'type': 'string'},
            'genre': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'best_for': {'type': 'string'},
            'avoid_for': {'type': 'string'},
            'delivery_30s': {'type': 'string'},
            'delivery_1m': {'type': 'string'},
            'delivery_casual': {'type': 'string'},
            'follow_up_question': {'type': 'string'},
            'escape_line': {'type': 'string'},
            'source_note': {'type': 'string'},
            'citations': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'credibility_score': {'type': 'integer'},
          },
          'required': ['can_generate', 'source_note', 'credibility_score'],
        },
        mode: mode,
      );

      if (result['can_generate'] != true) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('根拠が足りないため話材化を見送りました')));
        return;
      }

      final citations = (result['citations'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      final sourceNote = (result['source_note'] ?? '').toString();
      final combinedSourceNote = citations.isEmpty
          ? sourceNote
          : ([sourceNote, ...citations].where((e) => e.isNotEmpty).join('\n'));

      if (!mounted) {
        return;
      }

      final draft = InitialTalkingTopicDraft(
        title: (result['title'] ?? theme).toString(),
        hook: (result['hook'] ?? '').toString(),
        corePoint: (result['core_point'] ?? '').toString(),
        body: (result['body'] ?? '').toString(),
        twist: (result['twist'] ?? '').toString(),
        useCase: (result['use_case'] ?? '').toString(),
        genre: (result['genre'] ?? '').toString(),
        tags: (result['tags'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        bestFor: (result['best_for'] ?? '').toString(),
        avoidFor: (result['avoid_for'] ?? '').toString(),
        delivery30s: (result['delivery_30s'] ?? '').toString(),
        delivery1m: (result['delivery_1m'] ?? '').toString(),
        deliveryCasual: (result['delivery_casual'] ?? '').toString(),
        followUpQuestion: (result['follow_up_question'] ?? '').toString(),
        escapeLine: (result['escape_line'] ?? '').toString(),
        sourceNote: combinedSourceNote,
        referenceUrls: citations
            .where((e) => e.startsWith('http://') || e.startsWith('https://'))
            .toList(),
        credibilityScore: ((result['credibility_score'] as int?) ?? 70),
        rawSource:
            '${useWebResearch ? 'AI web research topic seed' : 'AI local topic seed'}: $theme',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TalkingTopicEditScreen(initialDraft: draft),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI生成に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingIdea = false);
      }
    }
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.soften(AppPalette.talkingTopic, 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
