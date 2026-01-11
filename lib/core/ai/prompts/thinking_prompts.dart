import 'package:dart_openai/dart_openai.dart';

import '../models/ai_chat_message.dart';
import '../thinking_styles/thinking_style.dart';

class ThinkingPrompts {
  /// 概念メモのAI一次生成
  static String generateConceptMemo(String conceptName) {
    return '''
あなたは優秀な哲学者・思想家です。以下の概念について、深く考察した内容を生成してください。

概念名: $conceptName

以下のJSON形式で出力してください:
{
  "title": "$conceptName",
  "content": "この概念についての深い考察（3〜5段落程度）",
  "key_points": ["重要ポイント1", "重要ポイント2", "重要ポイント3"],
  "related_concepts": ["関連概念1", "関連概念2"],
  "questions": ["この概念から生まれる問い1", "この概念から生まれる問い2"]
}

※ contentは思索的で深みのある内容にしてください。
※ 具体例や比喩を使って、概念を多角的に説明してください。
''';
  }

  /// 概念メモ要約
  static String summarizeConceptMemo(String content) {
    return '''以下の概念メモを要約してください。

# 要件
- 核心的な思考内容を3〜5文で要約
- キーワード・概念を明示
- 思考の流れを保持

# 概念メモ
$content''';
  }

  /// 概念抽出
  static String extractConcepts(String content) {
    return '''以下の概念メモから、独立した概念を抽出してください。

# 要件
- 概念として独立可能な単位を抽出
- 各概念に定義・説明を付与
- 概念間の関係を明示

# 概念メモ
$content''';
  }

  /// 概念メモについてAIに質問
  static String askAboutConcept({
    required String conceptTitle,
    required String content,
    required String question,
  }) {
    return '''
あなたは思索パートナーです。以下の概念メモについて、ユーザーの質問に答えてください。

概念: $conceptTitle
内容: $content

ユーザーの質問: $question

※ 深く考察し、多角的な視点から回答してください。
※ 具体例や関連する概念にも言及してください。
''';
  }

  /// AI対話（思考スタイル適用）
  static List<OpenAIChatCompletionChoiceMessageModel> buildChatMessages({
    required ThinkingStyle style,
    required String memoContent,
    required List<AIChatMessage> history,
  }) {
    final messages = <OpenAIChatCompletionChoiceMessageModel>[
      // System message
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            style.systemPrompt,
          ),
        ],
      ),
      // Initial context
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            '以下の概念メモについて対話してください:\n\n$memoContent',
          ),
        ],
      ),
    ];

    // Add history
    for (final msg in history) {
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: msg.role == 'user'
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(msg.content),
          ],
        ),
      );
    }

    return messages;
  }
}
