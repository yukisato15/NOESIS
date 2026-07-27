enum LocalModelPreset {
  qwen15B(
    id: 'qwen2.5-1.5b-instruct',
    name: 'Qwen 2.5 1.5B (標準・高速)',
    sizeDescription: '約 1.1 GB',
    downloadUrl:
        'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    description: '日本語理解とスピードのバランスが最も良い標準モデル。メモ分類・タグ付けに最適。',
    templateType: ModelTemplateType.chatml,
    recommendedFor: '日常メモ整理・高速検索・標準対話',
  ),
  qwen3B(
    id: 'qwen2.5-3b-instruct',
    name: 'Qwen 2.5 3B (高品質・思考対話向け)',
    sizeDescription: '約 1.9 GB',
    downloadUrl:
        'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
    fileName: 'qwen2.5-3b-instruct-q4_k_m.gguf',
    description: '最高レベルの日本語表現力と論理的推論力。哲学対話や深いAI解説に最適。',
    templateType: ModelTemplateType.chatml,
    recommendedFor: '哲学対話・AI高度解説・深い思考整理',
  ),
  llama3B(
    id: 'llama-3.2-3b-instruct',
    name: 'Llama 3.2 3B (高速・構造化データ向け)',
    sizeDescription: '約 2.0 GB',
    downloadUrl:
        'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    fileName: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    description: 'Meta開発。JSON形式などの構造化データの出力精度が非常に高い。',
    templateType: ModelTemplateType.llama3,
    recommendedFor: 'JSON構造化抽出・分析レポート・データ整形',
  ),
  gemma2B(
    id: 'gemma-2-2b-it',
    name: 'Gemma 2 2B (概念抽出・分析向け)',
    sizeDescription: '約 1.6 GB',
    downloadUrl:
        'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
    fileName: 'gemma-2-2b-it-Q4_K_M.gguf',
    description: 'Google開発。論理的な概念マッピングや分析に強い。',
    templateType: ModelTemplateType.gemma,
    recommendedFor: '概念ノード抽出・時系列分析',
  );

  final String id;
  final String name;
  final String sizeDescription;
  final String downloadUrl;
  final String fileName;
  final String description;
  final ModelTemplateType templateType;
  final String recommendedFor;

  const LocalModelPreset({
    required this.id,
    required this.name,
    required this.sizeDescription,
    required this.downloadUrl,
    required this.fileName,
    required this.description,
    required this.templateType,
    required this.recommendedFor,
  });
}

enum ModelTemplateType {
  chatml,
  llama3,
  gemma,
}
