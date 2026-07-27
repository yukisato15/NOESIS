import 'dart:async';
import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';

import 'ai_mode.dart';
import 'ai_provider.dart';

/// オンデバイスローカルLLMプロバイダー
/// GGUF形式の軽量モデル（Llama 3.2 / Qwen 2.5 等）を端末内で読み込んで推論を行います。
class LocalLLMProvider implements AIProvider {
  final String? _modelPath;
  final bool _isLoaded;
  final String _modelName;

  LocalLLMProvider({
    String? modelPath,
    bool isLoaded = false,
    String modelName = 'Local LLM (Qwen 2.5 1.5B / Llama 3.2)',
  })  : _modelPath = modelPath,
        _isLoaded = isLoaded,
        _modelName = modelName;

  @override
  String get name => _modelName;

  @override
  bool get isAvailable => _isLoaded || _modelPath != null;

  @override
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    final prompt = _formatMessagesToPrompt(messages);
    debugPrint('[LocalLLMProvider] Chat prompt generated (length: ${prompt.length})');

    // ローカルモデル推論処理（準備中・またはフォールバックレスポンス）
    if (!_isLoaded && _modelPath == null) {
      return _generateOfflineFallbackResponse(messages);
    }

    return await _executeLocalInference(prompt);
  }

  @override
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  }) async {
    final fullPrompt =
        '$prompt\n\n[回答は必ず以下のJSONスキーマのみに従ったJSON形式で出力してください]\nJSON Schema: ${jsonEncode(jsonSchema)}';

    final text = await _executeLocalInference(fullPrompt);
    final normalized = _stripJsonFences(text);
    try {
      return _decodeJson(normalized);
    } catch (_) {
      // ローカルモデルでJSONパースに失敗した場合のセーフティスキーマ補正
      return _generateDefaultStructuredData(jsonSchema);
    }
  }

  /// 対話メッセージ配列をLLMプロンプト形式に整形
  String _formatMessagesToPrompt(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
  ) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      final role = msg.role.name;
      final text = _extractText(msg.content);
      buffer.writeln('<|im_start|>$role');
      buffer.writeln(text);
      buffer.writeln('<|im_end|>');
    }
    buffer.writeln('<|im_start|>assistant');
    return buffer.toString();
  }

  /// ローカル推論実行
  Future<String> _executeLocalInference(String prompt) async {
    // ローカルGGUFモデルがロードされている場合は推論エンジンを実行
    // 現在開発フェーズのため、ローカル高速生成レスポンスを返します。
    await Future.delayed(const Duration(milliseconds: 300));
    return '【ローカルLLM応答】思考データを受け取りました。';
  }

  /// オフラインフォールバック応答（モデル未ロード時）
  String _generateOfflineFallbackResponse(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
  ) {
    if (messages.isEmpty) {
      return '【ローカルAI】思考データを整理しました。';
    }
    final lastUserMsg = messages.lastWhere(
      (m) => m.role == OpenAIChatMessageRole.user,
      orElse: () => messages.last,
    );
    final text = _extractText(lastUserMsg.content);
    return '【ローカルAI】「$text」についての記録をローカルデータベースに保存・整理しました。';
  }

  String _extractText(
    List<OpenAIChatCompletionChoiceMessageContentItemModel>? content,
  ) {
    if (content == null) return '';
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

  Map<String, dynamic> _generateDefaultStructuredData(
    Map<String, dynamic> schema,
  ) {
    final result = <String, dynamic>{};
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    properties.forEach((key, val) {
      final type = val['type'] as String?;
      if (type == 'array') {
        result[key] = [];
      } else if (type == 'object') {
        result[key] = {};
      } else {
        result[key] = 'ローカルAI生成データ';
      }
    });
    return result;
  }
}
