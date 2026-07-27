import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NotionClient {
  NotionClient._();

  static const _baseUrl = 'https://api.notion.com/v1';
  static const _version = '2022-06-28';

  static String? get _apiKey => dotenv.env['NOTION_API_KEY']?.trim();

  static bool get isConfigured => (_apiKey ?? '').isNotEmpty;

  static Future<String> getTitlePropertyName(String databaseId) async {
    final response = await _request('GET', '/databases/$databaseId');
    final properties = response['properties'] as Map<String, dynamic>? ?? {};
    for (final entry in properties.entries) {
      final property = entry.value as Map<String, dynamic>;
      if ((property['type'] ?? '').toString() == 'title') {
        return entry.key;
      }
    }
    throw Exception('Notion database title property not found');
  }

  static Future<void> createPage({
    required String databaseId,
    required String title,
    required List<Map<String, dynamic>> children,
  }) async {
    final titleProperty = await getTitlePropertyName(databaseId);
    await _request(
      'POST',
      '/pages',
      body: {
        'parent': {'database_id': databaseId},
        'properties': {
          titleProperty: {
            'title': [
              {
                'text': {'content': title},
              },
            ],
          },
        },
        'children': children,
      },
    );
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('NOTION_API_KEY is not configured');
    }
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Notion-Version': _version,
      'Content-Type': 'application/json',
    };
    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const {}),
        );
        break;
      default:
        throw Exception('Unsupported method: $method');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Notion API error: ${response.statusCode} ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
