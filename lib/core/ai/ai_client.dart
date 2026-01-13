import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_mode.dart';
import 'search_client.dart';

class AIClient {
  static AIClient? _instance;
  final String _model;

  AIClient._({String model = 'gpt-4o'}) : _model = model;

  /// シングルトンインスタンスを取得
  static AIClient get instance {
    if (_instance == null) {
      throw Exception('AIClient not initialized. Call AIClient.initialize() first.');
    }
    return _instance!;
  }

  /// アプリ起動時に初期化（main.dartから呼ぶ）
  static void initialize() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    OpenAI.apiKey = apiKey;
    _instance = AIClient._();
  }

  /// テスト用に任意のAPIキーで初期化
  static void initializeWithKey(String apiKey, {String model = 'gpt-4o'}) {
    OpenAI.apiKey = apiKey;
    _instance = AIClient._(model: model);
  }

  /// JSON Schema強制生成（Responses API相当）
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  }) async {
    try {
      String enhancedPrompt = prompt;

      // Web検索モードの場合、検索結果を追加
      if (mode == AIMode.withSearch) {
        final searchQuery = _extractSearchQuery(prompt);
        print('[AIClient] 検索クエリ: $searchQuery');

        final searchResults = await SearchClient.instance.search(
          searchQuery,
          maxResults: 5,
        );
        print('[AIClient] 検索結果件数: ${searchResults.length}件');

        final searchContext = SearchClient.instance.formatSearchResults(searchResults);
        enhancedPrompt = '$prompt\n\n$searchContext';
      }

      // 推論モードの場合、o1-miniを使用
      final modelToUse = mode == AIMode.reasoning ? 'o1-mini' : _model;

      final response = await OpenAI.instance.chat.create(
        model: modelToUse,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  '$enhancedPrompt\n\nPlease respond in JSON format matching this schema: ${jsonSchema.toString()}'),
            ],
          ),
        ],
      );

      final content = response.choices.first.message.content;
      if (content == null || content.isEmpty) {
        throw Exception('AI response is empty');
      }

      final text = _extractText(content);
      final normalized = _stripJsonFences(text);
      return _decodeJson(normalized);
    } catch (e) {
      throw Exception('AI generation failed: $e');
    }
  }

  /// プロンプトから検索クエリを抽出（簡易実装）
  String _extractSearchQuery(String prompt) {
    final lines = prompt.split('\n');
    String? title;
    String? author;

    // 書籍検索の場合：「書名:」と「著者:」を抽出
    for (final line in lines) {
      if (line.contains('書名:')) {
        title = line.split(':').last.trim();
      } else if (line.contains('著者:')) {
        author = line.split(':').last.trim();
      } else if (line.contains('概念名:') || line.contains('見出し語:')) {
        return line.split(':').last.trim();
      }
    }

    // 書名と著者が両方ある場合は組み合わせる
    if (title != null && author != null) {
      return '$title $author';
    } else if (title != null) {
      return title;
    } else if (author != null) {
      return author;
    }

    // 見つからない場合は最初の50文字を使用
    return prompt.substring(0, prompt.length > 50 ? 50 : prompt.length);
  }

  /// 通常の対話（AI精査用）
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    try {
      final response = await OpenAI.instance.chat.create(
        model: _model,
        messages: messages,
      );

      final content = response.choices.first.message.content;
      if (content == null || content.isEmpty) {
        return '';
      }

      return _extractText(content);
    } catch (e) {
      throw Exception('AI chat failed: $e');
    }
  }

  /// セマンティック検索: 意味的に類似したコンテンツをAIで抽出
  Future<List<String>> semanticSearch({
    required String query,
    required List<Map<String, dynamic>> corpus,
  }) async {
    try {
      final corpusJson = jsonEncode(corpus);
      final prompt = '''
あなたは意味検索のエキスパートです。
以下のクエリに意味的に関連するアイテムのIDを抽出してください。

クエリ: "$query"

コーパス（検索対象）:
$corpusJson

意味的に関連する順に、関連度が高い順にIDを返してください。
関連度が低いもの（スコア30%以下）は除外してください。

出力はJSON形式で以下のスキーマに従ってください:
{
  "related_ids": ["id1", "id2", "id3"]
}
''';

      final response = await generateStructured(
        prompt: prompt,
        jsonSchema: {
          'type': 'object',
          'properties': {
            'related_ids': {
              'type': 'array',
              'items': {'type': 'string'}
            }
          },
          'required': ['related_ids']
        },
      );

      final relatedIds = response['related_ids'] as List<dynamic>;
      return relatedIds.map((id) => id.toString()).toList();
    } catch (e) {
      throw Exception('Semantic search failed: $e');
    }
  }

  /// 時系列分析: 思考の変遷を分析
  Future<Map<String, dynamic>> analyzeTimeline({
    required String theme,
    required List<Map<String, dynamic>> chronologicalItems,
  }) async {
    try {
      final itemsJson = jsonEncode(chronologicalItems);
      final prompt = '''
あなたは思考分析のエキスパートです。
以下のテーマについて、時系列に沿った思考の変遷を分析してください。

テーマ: "$theme"

時系列データ:
$itemsJson

分析結果を以下のJSON形式で返してください:
{
  "summary": "思考の変遷の要約",
  "phases": [
    {
      "period": "期間の説明",
      "items": ["id1", "id2"],
      "characteristics": "この時期の特徴"
    }
  ],
  "evolution": "思考がどう進化したかの分析"
}
''';

      final response = await generateStructured(
        prompt: prompt,
        jsonSchema: {
          'type': 'object',
          'properties': {
            'summary': {'type': 'string'},
            'phases': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'period': {'type': 'string'},
                  'items': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  },
                  'characteristics': {'type': 'string'}
                }
              }
            },
            'evolution': {'type': 'string'}
          },
          'required': ['summary', 'phases', 'evolution']
        },
      );

      return response;
    } catch (e) {
      throw Exception('Timeline analysis failed: $e');
    }
  }

  /// 関連概念抽出: 検索結果から関連する概念を抽出
  Future<Map<String, dynamic>> extractRelatedConcepts({
    required List<Map<String, dynamic>> searchResults,
  }) async {
    try {
      final resultsJson = jsonEncode(searchResults);
      final prompt = '''
あなたは概念抽出のエキスパートです。
以下の検索結果から、関連する概念とその関係性を抽出してください。

検索結果:
$resultsJson

以下のJSON形式で、概念マップデータを返してください:
{
  "concepts": [
    {
      "id": "concept_id",
      "label": "概念名",
      "category": "カテゴリ",
      "item_ids": ["関連するアイテムID"]
    }
  ],
  "relations": [
    {
      "from": "concept_id1",
      "to": "concept_id2",
      "type": "関係性の種類（例: 包含、対比、派生）"
    }
  ]
}
''';

      final response = await generateStructured(
        prompt: prompt,
        jsonSchema: {
          'type': 'object',
          'properties': {
            'concepts': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'string'},
                  'label': {'type': 'string'},
                  'category': {'type': 'string'},
                  'item_ids': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  }
                }
              }
            },
            'relations': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'from': {'type': 'string'},
                  'to': {'type': 'string'},
                  'type': {'type': 'string'}
                }
              }
            }
          },
          'required': ['concepts', 'relations']
        },
      );

      return response;
    } catch (e) {
      throw Exception('Concept extraction failed: $e');
    }
  }

  String _extractText(
    List<OpenAIChatCompletionChoiceMessageContentItemModel> content,
  ) {
    return content
        .whereType<OpenAIChatCompletionChoiceMessageContentItemModel>()
        .map((item) => (item as dynamic).text?.toString() ?? '')
        .join('\n')
        .trim();
  }

  String _stripJsonFences(String text) {
    var normalized = text.trim();
    normalized = normalized.replaceAll(RegExp(r'```\\w*\\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'```'), '');
    return normalized.trim();
  }

  Map<String, dynamic> _decodeJson(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        final sliced = text.substring(start, end + 1);
        return jsonDecode(sliced) as Map<String, dynamic>;
      }
      rethrow;
    }
  }
}
