import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/local/database.dart';
import 'notion_client.dart';

class NotionExportService {
  final AppDatabase db;

  NotionExportService(this.db);

  static bool get isConfigured => NotionClient.isConfigured;

  Future<void> exportSpot(int spotId) async {
    final databaseId = dotenv.env['NOTION_DATABASE_ID_SPOTS']?.trim();
    if (databaseId == null || databaseId.isEmpty) {
      throw Exception('NOTION_DATABASE_ID_SPOTS is not configured');
    }
    final spot = await db.spotsDao.getSpotById(spotId);
    if (spot == null) {
      throw Exception('Spot not found');
    }
    final tags = _decodeList(spot.tags);
    await NotionClient.createPage(
      databaseId: databaseId,
      title: spot.name,
      children: [
        _paragraph('ジャンル: ${spot.genre ?? ''}'),
        _paragraph('エリア: ${spot.area ?? ''}'),
        _paragraph('住所: ${spot.address ?? ''}'),
        _paragraph('一言説明: ${spot.summary ?? ''}'),
        _paragraph('雰囲気: ${spot.atmosphere ?? ''}'),
        _paragraph('良い点: ${spot.strengths ?? ''}'),
        _paragraph('向いている相手・場面: ${spot.recommendedFor ?? ''}'),
        if ((spot.mapUrl ?? '').isNotEmpty) _paragraph('地図URL: ${spot.mapUrl}'),
        if ((spot.websiteUrl ?? '').isNotEmpty)
          _paragraph('公式サイト: ${spot.websiteUrl}'),
        if (tags.isNotEmpty) _paragraph('タグ: ${tags.join(', ')}'),
      ],
    );
  }

  Future<void> exportTalkingTopic(int topicId) async {
    final databaseId = dotenv.env['NOTION_DATABASE_ID_TALKING_TOPICS']?.trim();
    if (databaseId == null || databaseId.isEmpty) {
      throw Exception('NOTION_DATABASE_ID_TALKING_TOPICS is not configured');
    }
    final topic = await db.talkingTopicsDao.getTopicById(topicId);
    if (topic == null) {
      throw Exception('Talking topic not found');
    }
    final tags = _decodeList(topic.tags);
    await NotionClient.createPage(
      databaseId: databaseId,
      title: topic.title,
      children: [
        _paragraph('フック: ${topic.hook ?? ''}'),
        _paragraph('核心: ${topic.corePoint ?? ''}'),
        _paragraph('詳細説明: ${topic.body ?? ''}'),
        _paragraph('使いどころ: ${topic.useCase ?? ''}'),
        _paragraph('30秒版: ${topic.delivery30s ?? ''}'),
        if ((topic.delivery1m ?? '').isNotEmpty)
          _paragraph('1分版: ${topic.delivery1m}'),
        if ((topic.followUpQuestion ?? '').isNotEmpty)
          _paragraph('返し質問: ${topic.followUpQuestion}'),
        if (tags.isNotEmpty) _paragraph('タグ: ${tags.join(', ')}'),
        if ((topic.sourceNote ?? '').isNotEmpty)
          _paragraph('出典メモ: ${topic.sourceNote}'),
        ..._decodeList(
          topic.referenceUrls,
        ).map((url) => _paragraph('参考URL: $url')),
      ],
    );
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
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _paragraph(String text) {
    return {
      'object': 'block',
      'type': 'paragraph',
      'paragraph': {
        'rich_text': [
          {
            'type': 'text',
            'text': {'content': text},
          },
        ],
      },
    };
  }
}
