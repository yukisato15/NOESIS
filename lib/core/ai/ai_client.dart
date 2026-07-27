import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';

import 'ai_config_service.dart';
import 'ai_mode.dart';
import 'ai_provider.dart';
import 'local_llm_provider.dart';
import 'openai_provider.dart';

class AIClient {
  static AIClient? _instance;
  late AIProvider _provider;

  AIClient._(AIProvider provider) : _provider = provider;

  /// シングルトンインスタンス
  static AIClient get instance {
    if (_instance == null) {
      // 初期化前はローカルプロバイダーで安全に初期化
      _instance = AIClient._(LocalLLMProvider());
    }
    return _instance!;
  }

  /// 現在アクティブな AI プロバイダー
  AIProvider get activeProvider => _provider;

  /// プロバイダーの表示名
  String get providerName => _provider.name;

  /// AI 機能が利用可能か
  static bool get isConfigured => instance._provider.isAvailable;

  /// アプリ起動時および設定変更時にプロバイダーを初期化・更新
  static Future<void> initialize() async {
    final config = await AIConfigService.getInstance();
    final type = config.providerType;

    AIProvider provider;
    switch (type) {
      case AIProviderType.openAI:
        final apiKey = config.openAIApiKey;
        provider = OpenAIProvider(apiKey: apiKey);
        break;
      case AIProviderType.gemini:
        // Gemini APIキー設定（またはOpenAIフォールバック）
        final apiKey = config.geminiApiKey.isNotEmpty
            ? config.geminiApiKey
            : config.openAIApiKey;
        provider = OpenAIProvider(apiKey: apiKey, model: 'gpt-4o-mini');
        break;
      case AIProviderType.localLlm:
        provider = LocalLLMProvider(
          modelPath: config.localModelPath,
          isLoaded: config.isLocalModelDownloaded,
          preset: config.activeModelPreset,
        );
        break;
    }

    _instance = AIClient._(provider);
    debugPrint('[AIClient] Initialized with provider: ${provider.name}');
  }

  /// テスト用に任意のAPIキーで初期化
  static void initializeWithKey(String apiKey, {String model = 'gpt-4o'}) {
    _instance = AIClient._(OpenAIProvider(apiKey: apiKey, model: model));
  }

  /// JSON Schema強制生成
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  }) async {
    return await _provider.generateStructured(
      prompt: prompt,
      jsonSchema: jsonSchema,
      mode: mode,
    );
  }

  /// 通常の対話
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    return await _provider.chat(messages: messages);
  }

  /// セマンティック検索
  Future<List<String>> semanticSearch({
    required String query,
    required List<Map<String, dynamic>> corpus,
  }) async {
    try {
      final sanitizedCorpus = corpus.map((item) {
        final sanitized = Map<String, dynamic>.from(item);
        sanitized.forEach((key, value) {
          if (value is DateTime) {
            sanitized[key] = value.toIso8601String();
          }
        });
        return sanitized;
      }).toList();

      final corpusJson = jsonEncode(sanitizedCorpus);
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
              'items': {'type': 'string'},
            },
          },
          'required': ['related_ids'],
        },
      );

      final relatedIds = response['related_ids'] as List<dynamic>? ?? [];
      return relatedIds.map((id) => id.toString()).toList();
    } catch (e) {
      debugPrint('[AIClient] Semantic search failed: $e');
      return [];
    }
  }

  /// 時系列分析
  Future<Map<String, dynamic>> analyzeTimeline({
    required String theme,
    required List<Map<String, dynamic>> chronologicalItems,
  }) async {
    final sanitizedItems = chronologicalItems.map((item) {
      final sanitized = Map<String, dynamic>.from(item);
      sanitized.forEach((key, value) {
        if (value is DateTime) {
          sanitized[key] = value.toIso8601String();
        }
      });
      return sanitized;
    }).toList();

    final itemsJson = jsonEncode(sanitizedItems);
    final prompt = '''
テーマ "$theme" について、時系列に沿った思考の変遷を分析してください。

データ:
$itemsJson
''';

    return await generateStructured(
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
                  'items': {'type': 'string'},
                },
                'characteristics': {'type': 'string'},
              },
            },
          },
          'evolution': {'type': 'string'},
        },
        'required': ['summary', 'phases', 'evolution'],
      },
    );
  }

  /// 関連概念抽出
  Future<Map<String, dynamic>> extractRelatedConcepts({
    required List<Map<String, dynamic>> searchResults,
  }) async {
    final sanitizedResults = searchResults.map((item) {
      final sanitized = Map<String, dynamic>.from(item);
      sanitized.forEach((key, value) {
        if (value is DateTime) {
          sanitized[key] = value.toIso8601String();
        }
      });
      return sanitized;
    }).toList();

    final resultsJson = jsonEncode(sanitizedResults);
    final prompt = '''
以下の検索結果から関連概念と関係性を抽出してください。
$resultsJson
''';

    return await generateStructured(
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
                  'items': {'type': 'string'},
                },
              },
            },
          },
          'relations': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'from': {'type': 'string'},
                'to': {'type': 'string'},
                'type': {'type': 'string'},
              },
            },
          },
        },
        'required': ['concepts', 'relations'],
      },
    );
  }
}
