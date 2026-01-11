enum AIMode {
  standard, // 通常のGPT-4o
  withSearch, // 検索付きGPT-4o + Tavily
  reasoning, // o1-mini（推論強化）
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
    switch (this) {
      case AIMode.standard:
        return 'GPT-4o（通常モード）';
      case AIMode.withSearch:
        return 'GPT-4o + Web検索（+0.7円/回）';
      case AIMode.reasoning:
        return 'o1-mini（深い推論）';
    }
  }
}
