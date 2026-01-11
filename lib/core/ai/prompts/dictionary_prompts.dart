class DictionaryPrompts {
  /// 一般辞書エントリのAI一次生成
  static String generateGeneralEntry(String headword) {
    return '''
あなたは優秀な辞書編集者です。以下の見出し語について、構造化された辞書エントリを日本語で生成してください。

見出し語: $headword

以下のJSON形式で出力してください:
{
  "reading": "よみがな（ひらがな）",
  "genre": "ジャンル（例: 哲学、科学、日常語など）",
  "definition": "明確で簡潔な定義",
  "etymology": "語源や由来の説明",
  "examples": ["例文1", "例文2"],
  "synonyms": ["類義語1", "類義語2"],
  "antonyms": ["対義語1", "対義語2"],
  "related": ["関連語1", "関連語2"],
  "usage_note": "使用上の注意点やニュアンス",
  "reference_urls": ["参考URL1", "参考URL2"]
}

※ 該当しない項目は空の配列 [] または空文字列 "" で返してください。
※ reference_urlsは実在する信頼できるソースのみを含めてください（https）。
※ Wikipediaや公的機関・公式サイトの日本語ページを優先し、example.comなどのプレースホルダは使用しないでください。
''';
  }

  /// IT用語辞書エントリのAI一次生成
  static String generateTechEntry(String headword) {
    return '''
あなたは優秀なIT技術辞書の編集者です。以下の技術用語について、構造化された辞書エントリを生成してください。

見出し語: $headword

以下のJSON形式で出力してください:
{
  "reading": "よみがな（カタカナまたはひらがな）",
  "genre": "技術分野（例: データベース、ネットワーク、プログラミング言語など）",
  "definition": "技術的に正確な定義",
  "etymology": "用語の由来や歴史",
  "examples": ["実用例1（コード例やユースケース）", "実用例2"],
  "synonyms": ["同義の技術用語1", "同義の技術用語2"],
  "antonyms": ["対比される技術用語1"],
  "related": ["関連技術用語1", "関連技術用語2"],
  "usage_note": "実務での使い方や注意点、設定例など",
  "reference_urls": ["公式ドキュメントURL", "技術記事URL"]
}

※ コード例を含める場合は、簡潔で実用的なものにしてください。
※ 該当しない項目は空の配列 [] または空文字列 "" で返してください。
※ reference_urls は公式ドキュメント・RFC・Wikipedia等の安定したURLの日本語ページを優先し、example.comなどのプレースホルダは使用しないでください（https）。
''';
  }

  /// 英語辞書エントリのAI一次生成
  static String generateEnglishEntry(String headword) {
    return '''
あなたは優秀な英語辞書の編集者です。以下の英単語について、日本語中心で構造化された辞書エントリを生成してください。

見出し語: $headword

以下のJSON形式で出力してください:
{
  "reading": "カタカナ読み",
  "genre": "品詞（名詞/動詞/形容詞/副詞 など）",
  "definition": "日本語での明確な定義",
  "etymology": "語源・由来・歴史的背景を日本語で詳しく（長文可）",
  "examples": ["英文 — 日本語訳", "英文 — 日本語訳"],
  "synonyms": ["英単語（日本語訳）", "英単語（日本語訳）"],
  "antonyms": ["英単語（日本語訳）", "英単語（日本語訳）"],
  "related": ["英単語（日本語訳）", "英単語（日本語訳）"],
  "usage_note": "日本語でのニュアンス・用法・注意点",
  "reference_urls": ["参考URL1", "参考URL2"]
}

※ 該当しない項目は空の配列 [] または空文字列 "" で返してください。
※ 語源は「ゆる言語学ラジオ」的に、背景・由来・歴史的文脈を丁寧に。ただし不確かな情報や推測は避け、必要なら「〜とされる」「〜に由来する可能性がある」と明示してください。
※ 例文は「英文 — 日本語訳」の1行形式にしてください。
※ 類義語・対義語・関連語は「英単語（日本語訳）」の形式にしてください。
※ reference_urls は信頼できる辞書・語源・百科事典のURLを1〜3件必ず含めてください（https）。
※ WikipediaやWiktionaryなど安定した情報源の日本語ページを優先し、example.comなどのプレースホルダは使用しないでください。
''';
  }

  /// 読書メモから辞書エントリへの昇格
  static String promoteFromReadingNote({
    required String title,
    required String body,
    required String bookTitle,
  }) {
    return '''
あなたは優秀な知識編集者です。以下の読書メモから、辞書エントリとして抽出できる概念や用語を特定し、辞書フォーマットに変換してください。

書籍名: $bookTitle
メモタイトル: $title
メモ本文:
$body

以下のJSON形式で出力してください:
{
  "headword": "抽出した見出し語または概念名",
  "reading": "よみがな",
  "genre": "ジャンル",
  "definition": "読書メモから抽出した定義",
  "etymology": "語源や由来（分かれば）",
  "examples": ["読書メモから抽出した例文や具体例"],
  "synonyms": ["類義語"],
  "antonyms": ["対義語"],
  "related": ["関連概念"],
  "usage_note": "読書メモから得られた使用上の注意点や洞察",
  "reference_urls": ["$bookTitle"]
}

※ 読書メモの内容を活かしつつ、辞書エントリとして成立する構造化データを生成してください。
''';
  }

  /// 辞書エントリについてAIに質問（会話モード）
  static String askAboutEntry({
    required String headword,
    required String definition,
    required String question,
  }) {
    return '''
あなたは辞書編集アシスタントです。以下の辞書エントリについて、ユーザーの質問に答えてください。

見出し語: $headword
定義: $definition

ユーザーの質問: $question

※ 簡潔で分かりやすく回答してください。必要に応じて例を挙げてください。
''';
  }
}
