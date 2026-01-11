import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/image_ocr_helper.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/dictionary_fields_table.dart';
import '../shared/surface_field.dart';

class DictionaryEntryEditScreen extends StatefulWidget {
  final int dictionaryId;
  final int? entryId;
  final AppDatabase? database;
  final String? initialHeadword;

  const DictionaryEntryEditScreen({
    super.key,
    required this.dictionaryId,
    this.entryId,
    this.database,
    this.initialHeadword,
  });

  @override
  State<DictionaryEntryEditScreen> createState() =>
      _DictionaryEntryEditScreenState();
}

class _AIRefineDialog extends StatefulWidget {
  const _AIRefineDialog();

  @override
  State<_AIRefineDialog> createState() => _AIRefineDialogState();
}

class _AIRefineDialogState extends State<_AIRefineDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI修正'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '修正指示',
          hintText: '例: 例文を具体的にして',
        ),
        maxLines: 3,
        onChanged: (value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('修正する'),
        ),
      ],
    );
  }
}

class _DictionaryEntryEditScreenState extends State<DictionaryEntryEditScreen> {
  AppDatabase? _db;
  AppDatabase get db => _db ??= widget.database ?? AppDatabase();
  final AIClient _aiClient = AIClient.instance;

  final TextEditingController _headwordController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};

  DictionaryDefinition? _definition;
  List<DictionaryField> _fields = [];
  DictionaryEntry? _entry;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGenerating = false;

  // AIモード選択
  AIMode _selectedMode = AIMode.standard;
  int _remainingSearches = 100;

  // タグとカテゴリの候補リスト
  List<String> _suggestedTags = [];
  List<String> _suggestedCategories = [];
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadSearchUsage();
  }

  Future<void> _loadSearchUsage() async {
    final remaining = await SearchClient.instance.getRemainingGoogleSearches();
    if (mounted) {
      setState(() {
        _remainingSearches = remaining;
      });
    }
  }

  @override
  void dispose() {
    if (widget.database == null) {
      _db?.close();
    }
    _headwordController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await db.ensureDictionaryRecovery();
      final definition = await db.dictionariesDao.getDictionary(
        widget.dictionaryId,
      );
      final fields = await db.dictionariesDao.getFields(widget.dictionaryId);

      // 頻度の高いタグとカテゴリを取得
      final suggestedTags = await db.dictionariesDao.getFrequentTags(
        widget.dictionaryId,
      );
      final suggestedCategories = await db.dictionariesDao.getFrequentCategories(
        widget.dictionaryId,
      );

      DictionaryEntry? entry;
      Map<int, DictionaryEntryValue> values = {};
      if (widget.entryId != null) {
        entry = await db.dictionariesDao.getEntry(widget.entryId!);
        final valueList = await db.dictionariesDao.getEntryValues(
          widget.entryId!,
        );
        values = {for (final v in valueList) v.fieldId: v};
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _definition = definition;
        _fields = fields;
        _entry = entry;
        _suggestedTags = suggestedTags;
        _suggestedCategories = suggestedCategories;
        _headwordController.text =
            entry?.headword ?? widget.initialHeadword ?? '';
        _categoryController.text = entry?.category ?? '';

        // Parse tags from JSON array
        if (entry?.tags != null && entry!.tags!.isNotEmpty) {
          try {
            final tagsList = (jsonDecode(entry.tags!) as List).cast<String>();
            _selectedTags = tagsList;
            _tagsController.text = tagsList.join(', ');
          } catch (_) {
            _tagsController.text = '';
          }
        }

        for (final field in fields) {
          if (!_fieldControllers.containsKey(field.fieldKey)) {
            _fieldControllers[field.fieldKey] = TextEditingController();
          }
          final value = values[field.id]?.value ?? '';
          _fieldControllers[field.fieldKey]!.text = _formatListForDisplay(
            field.fieldType,
            value,
          );
        }
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('[DictionaryEntryEdit] load failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final message = kDebugMode ? '読み込みに失敗しました: $e' : '読み込みに失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  String _formatListForDisplay(DictionaryFieldType type, String value) {
    if (value.isEmpty) {
      return '';
    }
    if (type == DictionaryFieldType.list ||
        type == DictionaryFieldType.urlList) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).join('\n');
        }
      } catch (_) {}
    }
    return value;
  }

  String _formatListForStorage(DictionaryFieldType type, String value) {
    if (type == DictionaryFieldType.list ||
        type == DictionaryFieldType.urlList) {
      final items = value
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return jsonEncode(items);
    }
    return value;
  }

  Future<void> _save() async {
    final headword = _headwordController.text.trim();
    if (headword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('見出し語を入力してください。')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final category = _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim();

      // Parse tags from comma-separated text
      String? tagsJson;
      final tagsText = _tagsController.text.trim();
      if (tagsText.isNotEmpty) {
        final tagsList = tagsText
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
        if (tagsList.isNotEmpty) {
          tagsJson = jsonEncode(tagsList);
        }
      }

      int entryId;
      if (_entry == null) {
        entryId = await db.dictionariesDao.createEntry(
          DictionaryEntriesCompanion.insert(
            dictionaryId: widget.dictionaryId,
            headword: headword,
            category: Value(category),
            tags: Value(tagsJson),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      } else {
        final updated = _entry!.copyWith(
          headword: headword,
          category: Value(category),
          tags: Value(tagsJson),
          updatedAt: now,
        );
        await db.dictionariesDao.updateEntry(updated);
        entryId = updated.id;
      }

      for (final field in _fields) {
        if (!field.isEnabled && field.fieldKey != 'headword') {
          continue;
        }
        if (field.fieldKey == 'headword') {
          continue;
        }
        final controller = _fieldControllers[field.fieldKey];
        if (controller == null) {
          continue;
        }
        final value = _formatListForStorage(
          field.fieldType,
          controller.text.trim(),
        );
        if (value.isEmpty && !field.isRequired) {
          continue;
        }
        await db.dictionariesDao.upsertEntryValue(
          DictionaryEntryValuesCompanion.insert(
            entryId: entryId,
            fieldId: field.id,
            value: value,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e, stack) {
      debugPrint('[DictionaryEntryEdit] save failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        final message = kDebugMode ? '保存に失敗しました: $e' : '保存に失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildSchema({bool includeMetadata = false}) {
    final properties = <String, dynamic>{};
    final required = <String>[];

    // カテゴリとタグを含める
    if (includeMetadata) {
      properties['category'] = {'type': 'string'};
      properties['tags'] = {
        'type': 'array',
        'items': {'type': 'string'},
      };
    }

    for (final field in _fields) {
      if (!field.isEnabled && field.fieldKey != 'headword') {
        continue;
      }
      if (field.fieldKey == 'headword') {
        continue;
      }
      if (field.fieldType == DictionaryFieldType.list ||
          field.fieldType == DictionaryFieldType.urlList) {
        properties[field.fieldKey] = {
          'type': 'array',
          'items': {'type': 'string'},
        };
      } else {
        properties[field.fieldKey] = {'type': 'string'};
      }
      if (field.isRequired) {
        required.add(field.fieldKey);
      }
    }

    return {'type': 'object', 'properties': properties, 'required': required};
  }

  Future<void> _generateWithAI() async {
    final headword = _headwordController.text.trim();
    if (headword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('見出し語を入力してください。')));
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final fieldLabels = _fields
        .where((f) => f.fieldKey != 'headword' && f.isEnabled)
        .map((f) => '${f.label} (${f.fieldKey})')
        .join(', ');

    final prompt =
        '''
あなたは辞書作成の編集者です。
以下の辞書に合わせて、見出し語からエントリを生成してください。

辞書名: ${_definition?.name ?? ''}
辞書の用途: ${_definition?.description ?? ''}

見出し語: $headword

出力はJSON形式で、以下の項目を埋めてください。
対象項目: $fieldLabels

また、以下のメタデータも生成してください：
- category: 適切なカテゴリ/ジャンル（例: 哲学、プログラミング、ビジネスなど）
- tags: 関連するタグの配列（2-5個程度）

- 日本語で簡潔に
- リスト項目は配列で
- reference_urls は https の実在URLを1〜3件
- Wikipediaや公式ドキュメントなど安定した情報源を優先（日本語ページを優先）
- example.com などのプレースホルダは使用しない
''';

    try {
      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: _buildSchema(includeMetadata: true),
        mode: _selectedMode,
      );

      // 検索使用後、残り回数を更新
      if (_selectedMode == AIMode.withSearch) {
        await _loadSearchUsage();
      }

      // カテゴリとタグを設定
      if (json['category'] != null) {
        _categoryController.text = json['category'].toString();
      }
      if (json['tags'] != null && json['tags'] is List) {
        final tags = (json['tags'] as List).map((e) => e.toString()).toList();
        _selectedTags = tags;
        _tagsController.text = tags.join(', ');
      }

      for (final field in _fields) {
        if (field.fieldKey == 'headword') {
          continue;
        }
        final value = json[field.fieldKey];
        if (value == null) {
          continue;
        }
        final controller = _fieldControllers[field.fieldKey];
        if (controller == null) {
          continue;
        }
        if (value is List) {
          controller.text = value.map((e) => e.toString()).join('\n');
        } else {
          controller.text = value.toString();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('AI生成に失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _scanImageForText() async {
    setState(() => _isGenerating = true);

    try {
      final result = await ImageOcrHelper.pickCropAndRecognize(
        context: context,
        cropEnabled: true,
      );

      if (result == null || !mounted) {
        setState(() => _isGenerating = false);
        return;
      }

      if (!result.hasText) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('テキストが検出されませんでした')),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // 見出し語フィールドにOCRテキストを設定
      _headwordController.text = result.recognizedText.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テキストを読み込みました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _refineWithAI() async {
    final instruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return const _AIRefineDialog();
      },
    );

    if (instruction == null || instruction.trim().isEmpty) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final currentBody = _fields
        .where((f) => f.fieldKey != 'headword')
        .map((f) => '${f.label}: ${_fieldControllers[f.fieldKey]?.text ?? ''}')
        .join('\n');

    final prompt =
        '''
以下の辞書エントリを、ユーザーの指示に従って修正してください。

見出し語: ${_headwordController.text.trim()}
カテゴリ: ${_categoryController.text.trim()}
タグ: ${_tagsController.text.trim()}

現在の内容:
$currentBody

修正指示:
$instruction

出力はJSON形式で、現在の項目キーを保持してください。
また、必要に応じてカテゴリ(category)やタグ(tags)も修正してください。
''';

    try {
      final json = await _aiClient.generateStructured(
        prompt: prompt,
        jsonSchema: _buildSchema(includeMetadata: true),
        mode: _selectedMode,
      );

      // 検索使用後、残り回数を更新
      if (_selectedMode == AIMode.withSearch) {
        await _loadSearchUsage();
      }

      // カテゴリとタグを更新
      if (json['category'] != null) {
        _categoryController.text = json['category'].toString();
      }
      if (json['tags'] != null && json['tags'] is List) {
        final tags = (json['tags'] as List).map((e) => e.toString()).toList();
        _selectedTags = tags;
        _tagsController.text = tags.join(', ');
      }

      for (final field in _fields) {
        if (field.fieldKey == 'headword') {
          continue;
        }
        final value = json[field.fieldKey];
        if (value == null) {
          continue;
        }
        final controller = _fieldControllers[field.fieldKey];
        if (controller == null) {
          continue;
        }
        if (value is List) {
          controller.text = value.map((e) => e.toString()).join('\n');
        } else {
          controller.text = value.toString();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('AI修正に失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Widget _buildAIModeSelector() {
    return SegmentedButton<AIMode>(
      segments: AIMode.values
          .map(
            (mode) => ButtonSegment(
              value: mode,
              label: Text(mode.label),
            ),
          )
          .toList(),
      selected: {_selectedMode},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      onSelectionChanged: (selection) {
        setState(() {
          _selectedMode = selection.first;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry == null ? 'エントリ追加' : 'エントリ編集'),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high),
            tooltip: 'AI修正',
            onPressed: _isGenerating ? null : _refineWithAI,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceField(
            label: '見出し語',
            hintText: '例: コンテキスト・スイッチング',
            controller: _headwordController,
            suffixIcon: IconButton(
              icon: const Icon(Icons.camera_alt),
              tooltip: '画像から読み取り',
              onPressed: _isGenerating ? null : _scanImageForText,
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI生成',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAIModeSelector(),
                const SizedBox(height: 8),
                Text(
                  _selectedMode.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                if (_selectedMode == AIMode.withSearch) ...[
                  const SizedBox(height: 6),
                  Text(
                    '残り検索回数: $_remainingSearches / 100',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          _remainingSearches > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateWithAI,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AIで生成'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.dictionaryGeneral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'メタデータ',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_suggestedCategories.isNotEmpty) ...[
                  Text(
                    'おすすめカテゴリ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _suggestedCategories.map((category) {
                      final isSelected =
                          _categoryController.text.trim() == category;
                      return ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _categoryController.text = category;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                SurfaceField(
                  label: 'カテゴリ/ジャンル',
                  hintText: '例: 哲学、プログラミング、ビジネス',
                  controller: _categoryController,
                ),
                const SizedBox(height: 16),
                if (_suggestedTags.isNotEmpty) ...[
                  Text(
                    'おすすめタグ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _suggestedTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!_selectedTags.contains(tag)) {
                                _selectedTags.add(tag);
                              }
                            } else {
                              _selectedTags.remove(tag);
                            }
                            _tagsController.text = _selectedTags.join(', ');
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                SurfaceField(
                  label: 'タグ',
                  hintText: 'タグ1, タグ2, タグ3',
                  controller: _tagsController,
                  onChanged: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedTags = value
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '辞書項目',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._fields
              .where((field) => field.fieldKey != 'headword' && field.isEnabled)
              .map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SurfaceField(
                    label: field.label,
                    controller: _fieldControllers[field.fieldKey]!,
                    maxLines: field.fieldType == DictionaryFieldType.text
                        ? 1
                        : 4,
                    alignLabelWithHint:
                        field.fieldType != DictionaryFieldType.text,
                  ),
                ),
              ),
          if (_fields.any(
            (field) => field.fieldType == DictionaryFieldType.list,
          ))
            Text(
              'リスト項目は改行区切りで入力',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }
}
