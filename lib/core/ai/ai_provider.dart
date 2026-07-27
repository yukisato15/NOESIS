import 'package:dart_openai/dart_openai.dart';
import 'ai_mode.dart';

/// 全てのAIプロバイダー（Local LLM, OpenAI, Gemini等）が実装する共通インターフェース
abstract class AIProvider {
  /// プロバイダー識別名
  String get name;

  /// プロバイダーが現在利用可能か（APIキーの有無やモデルのロード状態）
  bool get isAvailable;

  /// チャット対話生成
  Future<String> chat({
    required List<OpenAIChatCompletionChoiceMessageModel> messages,
  });

  /// JSON Schema に従った構造化データ生成
  Future<Map<String, dynamic>> generateStructured({
    required String prompt,
    required Map<String, dynamic> jsonSchema,
    AIMode mode = AIMode.standard,
  });
}
