import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';

import 'ai_mode.dart';
import 'ai_provider.dart';
import 'search_client.dart';

class OpenAIProvider implements AIProvider {
  final String _apiKey;
  final String _model;

  OpenAIProvider({required String apiKey, String model = 'gpt-4o'})
    : _apiKey = apiKey,
      _model = model {
    if (_apiKey.isNotEmpty) {
      OpenAI.apiKey = _apiKey;
      OpenAI.requestsTimeOut = const Duration(minutes: 3);
    }
  }

  @override
  String get name => 'OpenAI ($model)';

  String get model => _model;

  @override
  bool get isAvailable => _apiKey.isNotEmpty;

  @override
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    _ensureAvailable();
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
      throw Exception('OpenAI chat failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  }) async {
    _ensureAvailable();
    try {
      String enhancedPrompt = prompt;

      if (mode == AIMode.withSearch) {
        _ensureSearchConfigured();
        final searchQuery = _extractSearchQuery(prompt);
        final searchResults = await SearchClient.instance.search(
          searchQuery,
          maxResults: 5,
        );
        final searchContext = SearchClient.instance.formatSearchResults(
          searchResults,
        );
        enhancedPrompt = '$prompt\n\n$searchContext';
      }

      final modelToUse = mode == AIMode.reasoning ? 'o1-mini' : _model;

      final response = await OpenAI.instance.chat.create(
        model: modelToUse,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                '$enhancedPrompt\n\nPlease respond in JSON format matching this schema: ${jsonSchema.toString()}',
              ),
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
      throw Exception('OpenAI generation failed: $e');
    }
  }

  void _ensureAvailable() {
    if (!isAvailable) {
      throw Exception('OpenAI APIキーが設定されていません。');
    }
  }

  void _ensureSearchConfigured() {
    if (!SearchClient.isInitialized || !SearchClient.instance.isAvailable) {
      throw Exception('Web検索機能が設定されていません。');
    }
  }

  String _extractSearchQuery(String prompt) {
    final lines = prompt.split('\n');
    String? title;
    String? author;

    for (final line in lines) {
      if (line.contains('書名:')) {
        title = line.split(':').last.trim();
      } else if (line.contains('著者:')) {
        author = line.split(':').last.trim();
      } else if (line.contains('概念名:') || line.contains('見出し語:')) {
        return line.split(':').last.trim();
      }
    }

    if (title != null && author != null) {
      return '$title $author';
    } else if (title != null) {
      return title;
    } else if (author != null) {
      return author;
    }

    return prompt.substring(0, prompt.length > 50 ? 50 : prompt.length);
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
    normalized = normalized.replaceAll(RegExp(r'```\w*\s*'), '');
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
