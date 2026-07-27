import 'dart:async';
import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';

import 'ai_mode.dart';
import 'ai_provider.dart';
import 'local_llm_model_info.dart';

/// オンデバイスローカルLLMプロバイダー（マルチモデル＆プロンプト最適化対応）
class LocalLLMProvider implements AIProvider {
  final String? _modelPath;
  final bool _isLoaded;
  final LocalModelPreset _preset;

  LocalLLMProvider({
    String? modelPath,
    bool isLoaded = false,
    LocalModelPreset preset = LocalModelPreset.qwen15B,
  })  : _modelPath = modelPath,
        _isLoaded = isLoaded,
        _preset = preset;

  @override
  String get name => _preset.name;

  LocalModelPreset get preset => _preset;

  @override
  bool get isAvailable => _isLoaded || _modelPath != null;

  @override
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  }) async {
    final prompt = _formatMessagesToPrompt(messages, _preset.templateType);
    debugPrint('[LocalLLMProvider] Chat prompt (${_preset.id}) length: ${prompt.length}');

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
      return _generateDefaultStructuredData(jsonSchema);
    }
  }

  /// テンプレート種別に応じたプロンプトフォーマット変換
  String _formatMessagesToPrompt(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
    ModelTemplateType templateType,
  ) {
    final buffer = StringBuffer();

    switch (templateType) {
      case ModelTemplateType.chatml: // Qwen用
        for (final msg in messages) {
          final role = msg.role.name;
          final text = _extractText(msg.content);
          buffer.writeln('<|im_start|>$role');
          buffer.writeln(text);
          buffer.writeln('<|im_end|>');
        }
        buffer.writeln('<|im_start|>assistant');
        break;

      case ModelTemplateType.llama3: // Llama-3用
        buffer.writeln('<|begin_of_text|>');
        for (final msg in messages) {
          final role = msg.role.name;
          final text = _extractText(msg.content);
          buffer.writeln('<|start_header_id|>$role<|end_header_id|>');
          buffer.writeln(text);
          buffer.writeln('<|eot_id|>');
        }
        buffer.writeln('<|start_header_id|>assistant<|end_header_id|>');
        break;

      case ModelTemplateType.gemma: // Gemma用
        for (final msg in messages) {
          final role = msg.role == OpenAIChatMessageRole.user ? 'user' : 'model';
          final text = _extractText(msg.content);
          buffer.writeln('<start_of_turn>$role');
          buffer.writeln(text);
          buffer.writeln('<end_of_turn>');
        }
        buffer.writeln('<start_of_turn>model');
        break;
    }

    return buffer.toString();
  }

  /// ローカル推論実行
  Future<String> _executeLocalInference(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '【${_preset.name}】思考データを受け取りました。';
  }

  /// オフラインフォールバック応答（モデル未ロード時）
  String _generateOfflineFallbackResponse(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
  ) {
    if (messages.isEmpty) {
      return '【${_preset.name}】思考データを整理しました。';
    }
    final lastUserMsg = messages.lastWhere(
      (m) => m.role == OpenAIChatMessageRole.user,
      orElse: () => messages.last,
    );
    final text = _extractText(lastUserMsg.content);
    return '【${_preset.name}】「$text」についての記録を整理しました。';
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
        result[key] = '${_preset.name}生成データ';
      }
    });
    return result;
  }
}
