import 'dart:convert';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_client.dart';
import '../../core/integrations/notion_export_service.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/spot_messages_table.dart';
import '../shared/surface_field.dart';
import 'spot_edit_screen.dart';

class SpotDetailScreen extends StatefulWidget {
  final int spotId;

  const SpotDetailScreen({super.key, required this.spotId});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _chatController = TextEditingController();
  Spot? _spot;
  List<SpotVisit> _visits = [];
  List<SpotLink> _links = [];
  List<SpotMessage> _messages = [];
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
    super.dispose();
  }

  Future<void> _load() async {
    final spot = await _db.spotsDao.getSpotById(widget.spotId);
    final visits = await _db.spotsDao.getVisits(widget.spotId);
    final links = await _db.spotsDao.getLinks(widget.spotId);
    final messages = await _db.spotsDao.getMessages(widget.spotId);
    if (!mounted) return;
    setState(() {
      _spot = spot;
      _visits = visits;
      _links = links;
      _messages = messages;
      _isLoading = false;
    });
  }

  List<String> _decodeJsonList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    } catch (_) {
      return raw
          .split(RegExp(r'[\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  Future<void> _addVisit() async {
    final companion = TextEditingController();
    final order = TextEditingController();
    final situation = TextEditingController();
    final impression = TextEditingController();
    final conversation = TextEditingController();
    double rating = 3;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('訪問記録を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SurfaceField(label: '誰と行ったか', controller: companion),
                  const SizedBox(height: 12),
                  SurfaceField(label: '何を頼んだか', controller: order),
                  const SizedBox(height: 12),
                  SurfaceField(label: '場面', controller: situation),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '印象',
                    controller: impression,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SurfaceField(
                    label: '会話メモ',
                    controller: conversation,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Text('満足度 ${rating.round()}'),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) => setStateDialog(() => rating = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || _spot == null) {
      companion.dispose();
      order.dispose();
      situation.dispose();
      impression.dispose();
      conversation.dispose();
      return;
    }
    await _db.spotsDao.insertVisit(
      SpotVisitsCompanion.insert(
        spotId: _spot!.id,
        visitedAt: DateTime.now(),
        companionNote: drift.Value(
          companion.text.trim().isEmpty ? null : companion.text.trim(),
        ),
        orderNote: drift.Value(
          order.text.trim().isEmpty ? null : order.text.trim(),
        ),
        situation: drift.Value(
          situation.text.trim().isEmpty ? null : situation.text.trim(),
        ),
        impression: drift.Value(
          impression.text.trim().isEmpty ? null : impression.text.trim(),
        ),
        conversationNote: drift.Value(
          conversation.text.trim().isEmpty ? null : conversation.text.trim(),
        ),
        rating: drift.Value(rating.round()),
      ),
    );
    await _db.spotsDao.touchSpot(_spot!.id);
    await _load();
    companion.dispose();
    order.dispose();
    situation.dispose();
    impression.dispose();
    conversation.dispose();
  }

  Future<void> _sendMessage() async {
    final spot = _spot;
    final text = _chatController.text.trim();
    if (spot == null || text.isEmpty || _isSending) return;
    await _db.spotsDao.insertMessage(
      SpotMessagesCompanion.insert(
        spotId: spot.id,
        role: drift.Value(SpotMessageRole.user),
        content: text,
      ),
    );
    _chatController.clear();
    await _db.spotsDao.touchSpot(spot.id);
    await _load();
    if (!AIClient.isConfigured) return;
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
あなたはスポットアーカイブの編集者です。
店や場所を、再訪・紹介しやすい形に整理する補助だけをしてください。
'''),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text('''
スポット: ${spot.name}
概要: ${spot.summary ?? ''}
雰囲気: ${spot.atmosphere ?? ''}
良い点: ${spot.strengths ?? ''}
微妙な点: ${spot.weaknesses ?? ''}
向いている相手: ${spot.recommendedFor ?? ''}
訪問履歴件数: ${_visits.length}

これまでの対話:
$transcript

依頼:
$text
'''),
            ],
          ),
        ],
      );
      await _db.spotsDao.insertMessage(
        SpotMessagesCompanion.insert(
          spotId: spot.id,
          role: drift.Value(SpotMessageRole.assistant),
          content: reply,
        ),
      );
      await _db.spotsDao.touchSpot(spot.id);
      await _load();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteSpot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スポットを削除しますか？'),
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
    if (ok != true) return;
    await _db.spotsDao.deleteSpot(widget.spotId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _exportToNotion() async {
    if (_isExporting) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final service = NotionExportService(_db);
      await service.exportSpot(widget.spotId);
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

  Widget _section(String label, String? value) {
    if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final spot = _spot;
    if (spot == null) {
      return const Scaffold(body: Center(child: Text('スポットが見つかりません')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('スポット詳細'),
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
                  builder: (_) => SpotEditScreen(spotId: spot.id),
                ),
              );
              await _load();
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(onPressed: _deleteSpot, icon: const Icon(Icons.delete)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVisit,
        backgroundColor: AppPalette.archive,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.history_toggle_off),
        label: const Text('訪問記録'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // ── スポット写真 ──
          if ((spot.photoPath ?? '').isNotEmpty &&
              File(spot.photoPath!).existsSync())
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(spot.photoPath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((spot.genre ?? '').isNotEmpty)
                      _InfoChip(label: spot.genre!),
                    if ((spot.area ?? '').isNotEmpty)
                      _InfoChip(label: spot.area!),
                    _InfoChip(label: '作業${spot.workFriendly ?? '-'}'),
                    _InfoChip(label: '会話${spot.conversationFriendly ?? '-'}'),
                    ..._decodeJsonList(
                      spot.tags,
                    ).map((e) => _InfoChip(label: e)),
                  ],
                ),
                if ((spot.mapUrl ?? '').isNotEmpty ||
                    (spot.websiteUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if ((spot.mapUrl ?? '').isNotEmpty)
                        OutlinedButton(
                          onPressed: () => _openUrl(spot.mapUrl!),
                          child: const Text('地図を開く'),
                        ),
                      if ((spot.websiteUrl ?? '').isNotEmpty)
                        OutlinedButton(
                          onPressed: () => _openUrl(spot.websiteUrl!),
                          child: const Text('公式サイト'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section('一言説明', spot.summary),
          _section('雰囲気', spot.atmosphere),
          _section('良い点', spot.strengths),
          _section('微妙な点', spot.weaknesses),
          _section('向いている相手・場面', spot.recommendedFor),
          _section('向かない相手・場面', spot.avoidFor),
          _section('営業情報メモ', spot.businessHoursNote),
          _section('支払いメモ', spot.paymentNote),
          _section('喫煙ポリシー', spot.smokingPolicy),
          _section('アクセスメモ', spot.accessNote),
          SurfaceCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '実用情報',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '1人向き: ${spot.soloFriendly ?? '-'} / 友人向き: ${spot.friendFriendly ?? '-'} / デート向き: ${spot.dateFriendly ?? '-'}',
                ),
                const SizedBox(height: 6),
                Text(
                  '作業向き: ${spot.workFriendly ?? '-'} / 会話向き: ${spot.conversationFriendly ?? '-'}',
                ),
                const SizedBox(height: 6),
                Text(
                  '静かさ: ${spot.quietnessLevel ?? '-'} / 混みやすさ: ${spot.crowdednessLevel ?? '-'}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Wi-Fi: ${spot.hasWifi == null ? '未設定' : (spot.hasWifi! ? 'あり' : 'なし')} / 電源: ${spot.hasPower == null ? '未設定' : (spot.hasPower! ? 'あり' : 'なし')}',
                ),
              ],
            ),
          ),
          if (_decodeJsonList(spot.snsUrls).isNotEmpty)
            SurfaceCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SNS・リンク',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final url in _decodeJsonList(spot.snsUrls))
                    InkWell(
                      onTap: () => _openUrl(url),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          url,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  for (final link in _links)
                    InkWell(
                      onTap: () => _openUrl(link.url),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          link.label ?? link.url,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          SurfaceCard(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '訪問履歴',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_visits.isEmpty) const Text('まだ訪問記録がありません。'),
                for (final visit in _visits) ...[
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(visit.visitedAt),
                    style: theme.textTheme.labelLarge,
                  ),
                  if ((visit.photoPath ?? '').isNotEmpty &&
                      File(visit.photoPath!).existsSync()) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(visit.photoPath!),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if ((visit.companionNote ?? '').isNotEmpty)
                    Text('誰と: ${visit.companionNote}'),
                  if ((visit.orderNote ?? '').isNotEmpty)
                    Text('注文: ${visit.orderNote}'),
                  if ((visit.situation ?? '').isNotEmpty)
                    Text('場面: ${visit.situation}'),
                  if ((visit.impression ?? '').isNotEmpty)
                    Text('印象: ${visit.impression}'),
                  if ((visit.conversationNote ?? '').isNotEmpty)
                    Text('会話: ${visit.conversationNote}'),
                  const Divider(height: 24),
                ],
              ],
            ),
          ),
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
                    alignment: message.role == SpotMessageRole.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.role == SpotMessageRole.user
                            ? AppPalette.soften(AppPalette.archive, 0.78)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(message.content),
                    ),
                  ),
                ],
                SurfaceField(
                  label: '依頼',
                  hintText: '初対面向き？ 友人に勧める一言は？ など',
                  controller: _chatController,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.archive,
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
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.soften(AppPalette.archive, 0.84),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
