import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/podcast_episodes_table.dart';

/// 音声コンテンツ登録画面（読書モジュールの「本を追加」に相当）
class AudioContentAddScreen extends StatefulWidget {
  const AudioContentAddScreen({super.key});

  @override
  State<AudioContentAddScreen> createState() => _AudioContentAddScreenState();
}

class _AudioContentAddScreenState extends State<AudioContentAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppDatabase _db = AppDatabase();

  // URL
  final _urlController = TextEditingController();
  bool _urlLoading = false;
  String? _urlInfo;
  String? _urlError;

  // 必須項目
  final _titleController = TextEditingController();
  final _programController = TextEditingController();

  // 任意項目
  final _speakerController = TextEditingController();
  final _genreController = TextEditingController();
  final _publishedDateController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _ratingController = TextEditingController();
  final _relatedUrlController = TextEditingController();
  final _reviewSummaryController = TextEditingController();

  bool _isSaving = false;
  bool _isCompletingWithAI = false;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _programController.dispose();
    _speakerController.dispose();
    _genreController.dispose();
    _publishedDateController.dispose();
    _synopsisController.dispose();
    _ratingController.dispose();
    _relatedUrlController.dispose();
    _reviewSummaryController.dispose();
    _db.close();
    super.dispose();
  }

  // ─── URL から情報を取得 ──────────────────────────────────────

  Future<void> _fetchFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _urlLoading = true;
      _urlInfo = null;
      _urlError = null;
    });

    try {
      if (_isYouTubeUrl(url)) {
        await _fetchYouTubeInfo(url);
      } else {
        await _fetchGenericPageInfo(url);
      }
    } catch (e) {
      if (mounted) setState(() => _urlError = 'ページ取得失敗: $e');
    } finally {
      if (mounted) setState(() => _urlLoading = false);
    }
  }

  bool _isYouTubeUrl(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  Future<void> _fetchYouTubeInfo(String url) async {
    final videoId = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})')
            .firstMatch(url)
            ?.group(1) ??
        RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})').firstMatch(url)?.group(1);

    if (videoId == null) {
      setState(() => _urlError = 'YouTubeのビデオIDを取得できませんでした。');
      return;
    }

    final res = await http.get(
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept-Language': 'ja,en;q=0.9',
      },
    ).timeout(const Duration(seconds: 15));

    final body = res.body;

    String unescape(String s) => s
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\"', '"');

    if (_titleController.text.isEmpty) {
      final m = RegExp(r'"title":"([^"]+)"').firstMatch(body);
      if (m != null) _titleController.text = unescape(m.group(1)!);
    }
    if (_programController.text.isEmpty) {
      final m = RegExp(r'"author":"([^"]+)"').firstMatch(body);
      if (m != null) _programController.text = unescape(m.group(1)!);
    }

    if (mounted) {
      setState(() => _urlInfo = 'タイトルと番組名を取得しました。「AIで情報を補完」ボタンで詳細情報を自動入力できます。');
    }
  }

  Future<void> _fetchGenericPageInfo(String url) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 15));
    final body = res.body;

    if (_titleController.text.isEmpty) {
      final m = RegExp(r'<title>([^<]+)</title>').firstMatch(body);
      if (m != null) _titleController.text = m.group(1)!.trim();
    }

    if (mounted) {
      setState(() => _urlInfo = 'ページ情報を取得しました。「AIで情報を補完」ボタンで詳細情報を自動入力できます。');
    }
  }

  // ─── AI 補完 ──────────────────────────────────────────────────

  Future<void> _completeWithAI() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    setState(() => _isCompletingWithAI = true);

    try {
      final title = _titleController.text.trim();
      final program = _programController.text.trim();
      final url = _urlController.text.trim();

      final prompt = '''
あなたは音声コンテンツ（YouTube動画、ポッドキャスト、ラジオなど）のデータベースアシスタントです。
以下のコンテンツについて、知っている情報をJSON形式で返してください。

タイトル: $title
${program.isNotEmpty ? '番組名・チャンネル: $program' : ''}
${url.isNotEmpty ? 'URL: $url' : ''}

必ず以下のJSON形式で返してください：
{
  "speaker": "話者・出演者名",
  "genre": "ジャンル（例: 教育、エンタメ、テクノロジー、言語学、経済など）",
  "published_date": "配信日（YYYY-MM-DD形式、わからなければ空文字）",
  "synopsis": "このコンテンツの内容を100-200文字で説明",
  "rating": "一般的な評価や評判（例: 視聴者から高評価など）",
  "related_url": "関連URL（公式サイト・チャンネルURLなど）",
  "review_summary": "このコンテンツに対する一般的な評価を50-100文字で"
}

重要:
- 知っている情報だけを記入してください
- 確信がない場合は空文字列 "" を返してください
- 創作や推測は避けてください
''';

      final schema = {
        'type': 'object',
        'properties': {
          'speaker': {'type': 'string'},
          'genre': {'type': 'string'},
          'published_date': {'type': 'string'},
          'synopsis': {'type': 'string'},
          'rating': {'type': 'string'},
          'related_url': {'type': 'string'},
          'review_summary': {'type': 'string'},
        },
        'required': [
          'speaker',
          'genre',
          'published_date',
          'synopsis',
          'rating',
          'related_url',
          'review_summary',
        ],
      };

      Map<String, dynamic> result;
      final canSearch =
          SearchClient.isInitialized && SearchClient.instance.isAvailable;

      if (canSearch) {
        try {
          result = await AIClient.instance.generateStructured(
            prompt: prompt,
            jsonSchema: schema,
            mode: AIMode.withSearch,
          );
        } catch (_) {
          result = await AIClient.instance.generateStructured(
            prompt: prompt,
            jsonSchema: schema,
            mode: AIMode.standard,
          );
        }
      } else {
        result = await AIClient.instance.generateStructured(
          prompt: prompt,
          jsonSchema: schema,
          mode: AIMode.standard,
        );
      }

      if (!mounted) return;

      setState(() {
        _setIfNotEmpty(_speakerController, result['speaker']);
        _setIfNotEmpty(_genreController, result['genre']);
        _setIfNotEmpty(_publishedDateController, result['published_date']);
        _setIfNotEmpty(_synopsisController, result['synopsis']);
        _setIfNotEmpty(_ratingController, result['rating']);
        _setIfNotEmpty(_relatedUrlController, result['related_url']);
        _setIfNotEmpty(_reviewSummaryController, result['review_summary']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIによる情報補完が完了しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI補完に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompletingWithAI = false);
    }
  }

  void _setIfNotEmpty(TextEditingController ctrl, dynamic value) {
    if (value != null && value.toString().trim().isNotEmpty) {
      ctrl.text = value.toString().trim();
    }
  }

  // ─── 保存 ──────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _db.ensurePodcastEpisodesColumns();

      // ソース種別を URL から推定
      final url = _urlController.text.trim();
      final sourceType = _isYouTubeUrl(url)
          ? EpisodeSourceType.youtube
          : url.isNotEmpty
              ? EpisodeSourceType.podcast
              : EpisodeSourceType.recording;

      // 配信日パース
      DateTime? publishedAt;
      final dateStr = _publishedDateController.text.trim();
      if (dateStr.isNotEmpty) {
        publishedAt = DateTime.tryParse(dateStr);
      }

      await _db.podcastEpisodesDao.insertEpisode(
        PodcastEpisodesCompanion.insert(
          title: _titleController.text.trim(),
          sourceType: Value(sourceType),
          sourceUrl: Value(url.isEmpty ? null : url),
          programName: Value(_programController.text.trim().isEmpty
              ? null
              : _programController.text.trim()),
          speaker: Value(_speakerController.text.trim().isEmpty
              ? null
              : _speakerController.text.trim()),
          genre: Value(_genreController.text.trim().isEmpty
              ? null
              : _genreController.text.trim()),
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
          publishedAt: Value(publishedAt),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('音声コンテンツを登録しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声コンテンツを追加'),
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
              onPressed: _save,
              tooltip: '登録',
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
                        Icon(Icons.lightbulb_outline,
                            size: 20, color: AppPalette.listening),
                        const SizedBox(width: 8),
                        Text('AI補完機能',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'URLを貼り付けて「URLから情報を取得」を押すか、\n'
                      'タイトルを入力後「AIで情報を補完」ボタンを押すと\n'
                      '話者・ジャンル・概要などを自動入力できます',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // URL入力
            _PasteField(
              controller: _urlController,
              label: 'URL（YouTube・ポッドキャスト等）',
              hint: 'https://youtu.be/...',
              icon: Icons.link,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _urlLoading ? null : _fetchFromUrl,
                icon: _urlLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: Text(_urlLoading ? '取得中...' : 'URLから情報を取得'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.listening,
                  side: BorderSide(color: AppPalette.listening),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (_urlInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(_urlInfo!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.blue[700])),
              ),
            ],
            if (_urlError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(_urlError!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.red[700])),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // 必須項目
            Text('必須項目',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _PasteField(
              controller: _titleController,
              label: 'タイトル *',
              hint: '例: 女性だけに売れまくったドイツの本とは？',
              icon: Icons.headphones,
              required: true,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _programController,
              label: '番組名・チャンネル名',
              hint: '例: ゆる言語学ラジオ',
              icon: Icons.podcasts,
            ),

            const SizedBox(height: 20),

            // AI補完ボタン
            FilledButton.icon(
              onPressed: _isCompletingWithAI ? null : _completeWithAI,
              icon: _isCompletingWithAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label:
                  Text(_isCompletingWithAI ? 'AI補完中...' : 'AIで情報を補完'),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.listening,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // 任意項目
            Text('任意項目（AI補完可能）',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _PasteField(
              controller: _speakerController,
              label: '話者・出演者',
              hint: '例: 水野太貴・堀元見',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _genreController,
              label: 'ジャンル',
              hint: '例: 言語学・教育',
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _publishedDateController,
              label: '配信日',
              hint: '例: 2024-03-15',
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _synopsisController,
              label: 'あらすじ・概要',
              hint: 'このコンテンツの内容を説明',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _ratingController,
              label: '評価',
              hint: '例: 視聴者から高評価',
              icon: Icons.star_outline,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _relatedUrlController,
              label: '関連URL',
              hint: '例: https://channel.com/...',
              icon: Icons.open_in_new_outlined,
            ),
            const SizedBox(height: 12),
            _PasteField(
              controller: _reviewSummaryController,
              label: '一般的なレビュー要約',
              hint: 'このコンテンツの評判・感想',
              icon: Icons.rate_review_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // 登録ボタン
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.listening,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('音声コンテンツを登録',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Paste 付きテキストフィールド ─────────────────────────────────

class _PasteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool required;

  const _PasteField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
        suffixIcon: _PasteButton(controller: controller),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label を入力してください' : null
          : null,
    );
  }
}

class _PasteButton extends StatelessWidget {
  final TextEditingController controller;

  const _PasteButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.content_paste_outlined, size: 18),
      tooltip: 'ペースト',
      onPressed: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) {
          controller.text = data!.text!;
        }
      },
    );
  }
}
