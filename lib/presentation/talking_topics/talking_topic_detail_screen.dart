import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_client.dart';
import '../../core/integrations/notion_export_service.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/talking_topic_messages_table.dart';
import '../../data/local/tables/talking_topic_sources_table.dart';
import '../shared/surface_field.dart';
import 'talking_topic_edit_screen.dart';

class TalkingTopicDetailScreen extends StatefulWidget {
  final int topicId;

  const TalkingTopicDetailScreen({super.key, required this.topicId});

  @override
  State<TalkingTopicDetailScreen> createState() =>
      _TalkingTopicDetailScreenState();
}

class _TalkingTopicDetailScreenState extends State<TalkingTopicDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _usageSituationController =
      TextEditingController();
  final TextEditingController _usageReactionController =
      TextEditingController();
  final TextEditingController _usageTargetController = TextEditingController();

  TalkingTopic? _topic;
  List<TalkingTopicSource> _sources = [];
  List<TalkingTopicUsage> _usages = [];
  List<TalkingTopicMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    _chatController.dispose();
    _usageSituationController.dispose();
    _usageReactionController.dispose();
    _usageTargetController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final topic = await _db.talkingTopicsDao.getTopicById(widget.topicId);
    final sources = await _db.talkingTopicsDao.getSources(widget.topicId);
    final usages = await _db.talkingTopicsDao.getUsages(widget.topicId);
    final messages = await _db.talkingTopicsDao.getMessages(widget.topicId);
    if (!mounted) {
      return;
    }
    setState(() {
      _topic = topic;
      _sources = sources;
      _usages = usages;
      _messages = messages;
      _isLoading = false;
    });
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

  List<String> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _sendMessage() async {
    final topic = _topic;
    final text = _chatController.text.trim();
    if (topic == null || text.isEmpty || _isSending) {
      return;
    }
    await _db.talkingTopicsDao.insertMessage(
      TalkingTopicMessagesCompanion.insert(
        topicId: topic.id,
        role: drift.Value(TalkingTopicMessageRole.user),
        content: text,
      ),
    );
    _chatController.clear();
    await _db.talkingTopicsDao.touchTopic(topic.id);
    await _load();

    if (!AIClient.isConfigured) {
      return;
    }
    setState(() => _isSending = true);
    try {
      final transcript = _messages
          .map((m) => '${m.role.name}: ${m.content}')
          .join('\n');
      final reply = await AIClient.instance.chat(
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text('''
あなたは「雑学・小ネタを会話で使える形に磨く編集者」です。
以下の話材を、自然な会話向けに改善する補助だけをしてください。
- 短く言い換える
- 導入を整える
- 面白さを出す
- 相手に返す質問を考える
- 話しすぎない形に削る
'''),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text('''
話材タイトル: ${topic.title}
フック: ${topic.hook ?? ''}
核心: ${topic.corePoint ?? ''}
本文: ${topic.body ?? ''}
会話設計:
- 30秒版: ${topic.delivery30s ?? ''}
- 1分版: ${topic.delivery1m ?? ''}
- カジュアル版: ${topic.deliveryCasual ?? ''}

これまでの対話:
$transcript

今回の依頼:
$text
'''),
            ],
          ),
        ],
      );
      await _db.talkingTopicsDao.insertMessage(
        TalkingTopicMessagesCompanion.insert(
          topicId: topic.id,
          role: drift.Value(TalkingTopicMessageRole.assistant),
          content: reply,
        ),
      );
      await _db.talkingTopicsDao.touchTopic(topic.id);
      await _load();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _addUsage() async {
    if (_topic == null) {
      return;
    }
    if (_usageSituationController.text.trim().isEmpty &&
        _usageReactionController.text.trim().isEmpty) {
      return;
    }
    await _db.talkingTopicsDao.insertUsage(
      TalkingTopicUsagesCompanion.insert(
        topicId: _topic!.id,
        usedAt: DateTime.now(),
        targetPersonNote: drift.Value(_nullOrText(_usageTargetController.text)),
        situation: drift.Value(_nullOrText(_usageSituationController.text)),
        reactionNote: drift.Value(_nullOrText(_usageReactionController.text)),
      ),
    );
    _usageTargetController.clear();
    _usageSituationController.clear();
    _usageReactionController.clear();
    await _db.talkingTopicsDao.touchTopic(_topic!.id);
    await _load();
  }

  Future<void> _deleteTopic() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('話材を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    await _db.talkingTopicsDao.deleteTopic(widget.topicId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _nullOrText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _exportToNotion() async {
    if (_isExporting) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final service = NotionExportService(_db);
      await service.exportTalkingTopic(widget.topicId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notionへ送信しました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Notion送信に失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final topic = _topic;
    if (topic == null) {
      return const Scaffold(body: Center(child: Text('話材が見つかりません')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('話材詳細'),
        actions: [
          IconButton(
            onPressed: _isExporting ? null : _exportToNotion,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TalkingTopicEditScreen(topicId: topic.id),
                ),
              );
              await _load();
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(onPressed: _deleteTopic, icon: const Icon(Icons.delete)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((topic.hook ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(topic.hook!, style: theme.textTheme.titleMedium),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((topic.genre ?? '').isNotEmpty) _chip(topic.genre!),
                    _chip('信頼度 ${topic.credibilityScore}'),
                    ..._decodeTags(topic.tags).map(_chip),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('核心', topic.corePoint),
          _section('詳細説明', topic.body),
          _section('オチ・驚きポイント', topic.twist),
          _section('使いどころ', topic.useCase),
          _section('向いている相手・場面', topic.bestFor),
          _section('向かない相手・場面', topic.avoidFor),
          _section('30秒版', topic.delivery30s),
          _section('1分版', topic.delivery1m),
          _section('3分版', topic.delivery3m),
          _section('カジュアル版', topic.deliveryCasual),
          _section('知的版', topic.deliveryIntellectual),
          _section('ユーモア版', topic.deliveryHumorous),
          _section('返し質問', topic.followUpQuestion),
          _section('滑った時の逃がし方', topic.escapeLine),
          _section('出典・メモ', topic.sourceNote),
          if (_decodeList(topic.referenceUrls).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '参考URL',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final url in _decodeList(topic.referenceUrls)) ...[
                      InkWell(
                        onTap: () => _openUrl(url),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            url,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (_sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '抽出元',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final source in _sources) ...[
                    Text(
                      '${source.sourceArchiveType.label}${source.sourceTitle == null ? '' : ' / ${source.sourceTitle}'}',
                    ),
                    if ((source.sourceExcerpt ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(source.sourceExcerpt!),
                      ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '使用履歴',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '誰に・どんな相手に',
                  controller: _usageTargetController,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '場面',
                  controller: _usageSituationController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '反応・結果',
                  controller: _usageReactionController,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addUsage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.talkingTopic,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('使用履歴を追加'),
                ),
                for (final usage in _usages) ...[
                  const Divider(height: 24),
                  Text(DateFormat('yyyy/MM/dd HH:mm').format(usage.usedAt)),
                  if ((usage.targetPersonNote ?? '').isNotEmpty)
                    Text('相手: ${usage.targetPersonNote}'),
                  if ((usage.situation ?? '').isNotEmpty)
                    Text('場面: ${usage.situation}'),
                  if ((usage.reactionNote ?? '').isNotEmpty)
                    Text('反応: ${usage.reactionNote}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AIとの対話',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final message in _messages) ...[
                  Align(
                    alignment: message.role == TalkingTopicMessageRole.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.role == TalkingTopicMessageRole.user
                            ? AppPalette.soften(AppPalette.talkingTopic, 0.78)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.content),
                    ),
                  ),
                ],
                SurfaceField(
                  label: '依頼',
                  hintText: 'もっと短く、初対面向けに、笑い寄りに など',
                  controller: _chatController,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.talkingTopic,
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('AIに相談'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, String? value) {
    if ((value ?? '').trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(value!),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
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
