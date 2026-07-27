import 'ai_client.dart';

enum AIMode {
  standard, // 通常モード
  withSearch, // 検索付きモード
  reasoning, // 推論強化モード
}

extension AIModeExtension on AIMode {
  String get label {
    switch (this) {
      case AIMode.standard:
        return '標準';
      case AIMode.withSearch:
        return 'Web検索';
      case AIMode.reasoning:
        return '推論';
    }
  }

  String get description {
    final providerName = AIClient.instance.providerName;
    switch (this) {
      case AIMode.standard:
        return '$providerName（通常モード）';
      case AIMode.withSearch:
        return '$providerName + Web検索（+0.7円/回）';
      case AIMode.reasoning:
        return '$providerName（思考・推論強化）';
    }
  }
}
