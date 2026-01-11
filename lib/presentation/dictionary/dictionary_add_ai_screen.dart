import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/local/database.dart';
import '../../data/local/tables/entries_table.dart';
import '../../data/local/tables/entry_appendices_table.dart';
import '../../core/ai/ai_client.dart';
import '../../core/ai/prompts/dictionary_prompts.dart';
import 'package:drift/drift.dart' as drift;
import '../shared/surface_field.dart';

class DictionaryAddAIScreen extends StatefulWidget {
  const DictionaryAddAIScreen({super.key});

  @override
  State<DictionaryAddAIScreen> createState() => _DictionaryAddAIScreenState();
}

class _DictionaryAddAIScreenState extends State<DictionaryAddAIScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _headwordController = TextEditingController();

  DictionaryDomain _selectedDomain = DictionaryDomain.general;
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedData;

  // 編集用コントローラー（AI生成後に使用）
  final TextEditingController _readingController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _definitionController = TextEditingController();
  final TextEditingController _etymologyController = TextEditingController();
  final TextEditingController _usageNoteController = TextEditingController();
  final TextEditingController _synonymsController = TextEditingController();
  final TextEditingController _antonymsController = TextEditingController();
  final TextEditingController _relatedController = TextEditingController();
  final TextEditingController _referenceUrlsController = TextEditingController();

  @override
  void dispose() {
    _headwordController.dispose();
    _readingController.dispose();
    _genreController.dispose();
    _definitionController.dispose();
    _etymologyController.dispose();
    _usageNoteController.dispose();
    _synonymsController.dispose();
    _antonymsController.dispose();
    _relatedController.dispose();
    _referenceUrlsController.dispose();
    _db.close();
    super.dispose();
  }

  String _listToText(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).join('\n');
    }
    return '';
  }

  List<String> _textToList(String text) {
    return text
        .split(RegExp(r'[\n,]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _generateWithAI() async {
    if (_headwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('見出し語を入力してください')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      String prompt;
      switch (_selectedDomain) {
        case DictionaryDomain.general:
          prompt = DictionaryPrompts.generateGeneralEntry(_headwordController.text.trim());
          break;
        case DictionaryDomain.technology:
          prompt = DictionaryPrompts.generateTechEntry(_headwordController.text.trim());
          break;
        case DictionaryDomain.english:
          prompt = DictionaryPrompts.generateEnglishEntry(_headwordController.text.trim());
          break;
      }

      final jsonSchema = {
        "type": "object",
        "properties": {
          "reading": {"type": "string"},
          "genre": {"type": "string"},
          "definition": {"type": "string"},
          "etymology": {"type": "string"},
          "examples": {"type": "array", "items": {"type": "string"}},
          "synonyms": {"type": "array", "items": {"type": "string"}},
          "antonyms": {"type": "array", "items": {"type": "string"}},
          "related": {"type": "array", "items": {"type": "string"}},
          "usage_note": {"type": "string"},
          "reference_urls": {"type": "array", "items": {"type": "string"}},
        },
      };

      final result = await AIClient.instance.generateStructured(
        prompt: prompt,
        jsonSchema: jsonSchema,
      );

      setState(() {
        _generatedData = result;
        _readingController.text = result['reading'] ?? '';
        _genreController.text = result['genre'] ?? '';
        _definitionController.text = result['definition'] ?? '';
        _etymologyController.text = result['etymology'] ?? '';
        _usageNoteController.text = result['usage_note'] ?? '';
        _synonymsController.text = _listToText(result['synonyms']);
        _antonymsController.text = _listToText(result['antonyms']);
        _relatedController.text = _listToText(result['related']);
        _referenceUrlsController.text = _listToText(result['reference_urls']);
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

  Future<void> _saveEntry() async {
    if (_headwordController.text.trim().isEmpty ||
        _definitionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('見出し語と定義は必須です')),
      );
      return;
    }

    // Entryを作成
    final entry = EntriesCompanion(
      type: const drift.Value(EntryType.dictionary),
      title: drift.Value(_headwordController.text.trim()),
      body: drift.Value(_definitionController.text.trim()),
      genre: drift.Value(_genreController.text.trim().isNotEmpty
          ? _genreController.text.trim()
          : null),
      domain: drift.Value(_selectedDomain),
      reading: drift.Value(_readingController.text.trim()),
      readingSource: const drift.Value('ai'),
    );

    final entryId = await _db.entriesDao.createEntry(entry);

    if (_generatedData != null) {
      _generatedData!['reading'] = _readingController.text.trim();
      _generatedData!['genre'] = _genreController.text.trim();
      _generatedData!['definition'] = _definitionController.text.trim();
      _generatedData!['etymology'] = _etymologyController.text.trim();
      _generatedData!['usage_note'] = _usageNoteController.text.trim();
      _generatedData!['synonyms'] = _textToList(_synonymsController.text);
      _generatedData!['antonyms'] = _textToList(_antonymsController.text);
      _generatedData!['related'] = _textToList(_relatedController.text);
      _generatedData!['reference_urls'] =
          _textToList(_referenceUrlsController.text);

      final appendix = EntryAppendicesCompanion(
        entryId: drift.Value(entryId),
        type: const drift.Value(AppendixType.log),
        content: drift.Value(jsonEncode(_generatedData)),
      );
      await _db.into(_db.entryAppendices).insert(appendix);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('辞書エントリを保存しました')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI辞書エントリ作成'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: 見出し語入力とドメイン選択
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: 見出し語入力',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SurfaceField(
                    label: '見出し語',
                    hintText: '例: データベース、Compassion、など',
                    controller: _headwordController,
                    enabled: !_isGenerating && _generatedData == null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '辞書タイプ',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<DictionaryDomain>(
                    segments: const [
                      ButtonSegment(
                        value: DictionaryDomain.general,
                        label: Text('一般'),
                      ),
                      ButtonSegment(
                        value: DictionaryDomain.technology,
                        label: Text('IT'),
                      ),
                      ButtonSegment(
                        value: DictionaryDomain.english,
                        label: Text('英語'),
                      ),
                    ],
                    selected: {_selectedDomain},
                    showSelectedIcon: false,
                    onSelectionChanged: _generatedData == null
                        ? (selection) {
                            setState(() {
                              _selectedDomain = selection.first;
                            });
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (_generatedData == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateWithAI,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _isGenerating ? 'AI生成中...' : 'AIで生成',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Step 2: AI生成結果の編集
            if (_generatedData != null) ...[
              const SizedBox(height: 16),
              SurfaceCard(
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
                        Text(
                          'Step 2: AI生成結果を編集',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '読み仮名',
                      controller: _readingController,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: 'ジャンル',
                      controller: _genreController,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '定義',
                      controller: _definitionController,
                      maxLines: 5,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '語源',
                      controller: _etymologyController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '使用上の注意',
                      controller: _usageNoteController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '類義語',
                      hintText: '改行またはカンマ区切りで入力',
                      controller: _synonymsController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '対義語',
                      hintText: '改行またはカンマ区切りで入力',
                      controller: _antonymsController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '関連語',
                      hintText: '改行またはカンマ区切りで入力',
                      controller: _relatedController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    SurfaceField(
                      label: '参考URL',
                      hintText: '改行またはカンマ区切りで入力',
                      controller: _referenceUrlsController,
                      maxLines: 3,
                      alignLabelWithHint: true,
                    ),
                    const SizedBox(height: 16),
                    if (_generatedData!['examples'] != null &&
                        (_generatedData!['examples'] as List).isNotEmpty) ...[
                      Text(
                        '例文',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ...(_generatedData!['examples'] as List).map((example) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SurfaceCard(
                            padding: const EdgeInsets.all(12),
                            child: Text(example.toString()),
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEntry,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
