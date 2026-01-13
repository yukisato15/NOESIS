/// 学習レベル
enum LearningLevel {
  /// 初心者（プログラミングを始めたばかり）
  beginner,

  /// 中級者（基本は理解している）
  intermediate,

  /// 上級者（実務経験あり、深い知識を求める）
  advanced,
}

extension LearningLevelExtension on LearningLevel {
  int get value {
    switch (this) {
      case LearningLevel.beginner:
        return 1;
      case LearningLevel.intermediate:
        return 2;
      case LearningLevel.advanced:
        return 3;
    }
  }

  String get displayName {
    switch (this) {
      case LearningLevel.beginner:
        return '初心者';
      case LearningLevel.intermediate:
        return '中級者';
      case LearningLevel.advanced:
        return '上級者';
    }
  }

  String get description {
    switch (this) {
      case LearningLevel.beginner:
        return 'プログラミングを始めたばかり';
      case LearningLevel.intermediate:
        return '基本的な文法は理解している';
      case LearningLevel.advanced:
        return '実務経験あり、深い知識を学びたい';
    }
  }

  String get guidanceNote {
    switch (this) {
      case LearningLevel.beginner:
        return '基礎からゆっくり、わかりやすく説明します';
      case LearningLevel.intermediate:
        return '実践的な使い方やパターンを学びます';
      case LearningLevel.advanced:
        return '内部実装や最適化、アーキテクチャを深掘りします';
    }
  }

  static LearningLevel fromValue(int value) {
    switch (value) {
      case 1:
        return LearningLevel.beginner;
      case 2:
        return LearningLevel.intermediate;
      case 3:
        return LearningLevel.advanced;
      default:
        return LearningLevel.beginner;
    }
  }
}
