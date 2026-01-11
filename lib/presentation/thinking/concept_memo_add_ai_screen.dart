import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/local/database.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts/thinking_prompts.dart';
import 'package:drift/drift.dart' as drift;

class ConceptMemoAddAIScreen extends StatefulWidget {
  const ConceptMemoAddAIScreen({super.key});

  @override
  State<ConceptMemoAddAIScreen> createState() => _ConceptMemoAddAIScreenState();
}

class _ConceptMemoAddAIScreenState extends State<ConceptMemoAddAIScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _conceptNameController = TextEditingController();

  bool _isGenerating = false;
  Map<String, dynamic>? _generatedData;

  // 編集用コントローラー
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _conceptNameController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    if (_conceptNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('概念名を入力してください')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final prompt = ThinkingPrompts.generateConceptMemo(_conceptNameController.text.trim());

      final jsonSchema = {
        "type": "object",
        "properties": {
          "title": {"type": "string"},
          "content": {"type": "string"},
          "key_points": {"type": "array", "items": {"type": "string"}},
          "related_concepts": {"type": "array", "items": {"type": "string"}},
          "questions": {"type": "array", "items": {"type": "string"}},
        },
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: jsonSchema,
      );

      setState(() {
        _generatedData = result;
        _titleController.text = result['title'] ?? _conceptNameController.text.trim();
        _contentController.text = result['content'] ?? '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI生成が完了しました。内容を確認・編集してください')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成に失敗しました')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    final memo = ConceptMemosCompanion(
      title: drift.Value(_titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null),
      content: drift.Value(_contentController.text.trim()),
    );

    await _db.conceptMemosDao.createConceptMemo(memo);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('概念メモを保存しました')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI概念メモ作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: 概念名入力
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: 概念名を入力',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _conceptNameController,
                      decoration: const InputDecoration(
                        labelText: '概念名',
                        hintText: '例: 自由意志、時間の本質、など',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isGenerating && _generatedData == null,
                    ),
                    const SizedBox(height: 16),
                    if (_generatedData == null)
                      ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateWithAI,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.psychology),
                        label: Text(
                          _isGenerating ? 'AI思索中...' : 'AIで生成',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Step 2: AI生成結果の編集
            if (_generatedData != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Step 2: AI生成結果を編集',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'タイトル',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: '思索内容',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 20,
                      ),
                      const SizedBox(height: 16),

                      // 重要ポイント
                      if (_generatedData!['key_points'] != null &&
                          (_generatedData!['key_points'] as List).isNotEmpty) ...[
                        const Text(
                          '重要ポイント:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_generatedData!['key_points'] as List).map((point) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(point.toString()),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],

                      // 関連概念
                      if (_generatedData!['related_concepts'] != null &&
                          (_generatedData!['related_concepts'] as List).isNotEmpty) ...[
                        const Text(
                          '関連概念:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_generatedData!['related_concepts'] as List)
                              .map((concept) {
                            return Chip(
                              label: Text(concept.toString()),
                              backgroundColor:
                                  theme.colorScheme.secondary.withOpacity(0.12),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 問い
                      if (_generatedData!['questions'] != null &&
                          (_generatedData!['questions'] as List).isNotEmpty) ...[
                        const Text(
                          'この概念から生まれる問い:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_generatedData!['questions'] as List).map((question) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary
                                    .withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: theme.colorScheme.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(question.toString()),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],

                      ElevatedButton.icon(
                        onPressed: _saveMemo,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
