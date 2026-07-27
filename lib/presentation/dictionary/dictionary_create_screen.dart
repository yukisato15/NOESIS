import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/dictionary_definitions_table.dart';
import '../../data/local/tables/dictionary_fields_table.dart';
import '../shared/surface_field.dart';

class DictionaryCreateScreen extends StatefulWidget {
  const DictionaryCreateScreen({super.key});

  @override
  State<DictionaryCreateScreen> createState() => _DictionaryCreateScreenState();
}

class _DictionaryCreateScreenState extends State<DictionaryCreateScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DictionaryReferenceDomain _referenceDomain =
      DictionaryReferenceDomain.general;

  bool _isWork = false;

  // 基本フィールド
  bool _enableMemo = true;
  bool _enableReading = true;
  bool _enableReferenceUrls = true;
  bool _enableSynonyms = true;
  bool _enableAntonyms = true;
  bool _enableRelated = true;
  bool _enableExamples = false;
  bool _enableEtymology = false;
  bool _enableUsageNote = false;

  // 拡張フィールド
  bool _enableCulturalBackground = false;
  bool _enableTrivia = false;
  bool _enableTips = false;
  bool _enableCommonMistakes = false;
  bool _enableEmotionalTone = false;
  bool _enableQuotes = false;
  bool _enableContrasts = false;
  bool _enableCaseStudies = false;
  bool _enableDerivatives = false;
  bool _enablePopCulture = false;
  bool _enableAcademicContext = false;
  bool _enableSemanticShift = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _db.close();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('辞書名を入力してください。')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dictionaryId = await _db.dictionariesDao.createDictionary(
        DictionaryDefinitionsCompanion.insert(
          name: name,
          description: Value(
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
          isSystem: const Value(false),
          isWork: Value(_isWork),
          category: Value(
            _categoryController.text.trim().isEmpty
                ? null
                : _categoryController.text.trim(),
          ),
          referenceDomain: Value(_referenceDomain),
        ),
      );

      final fields = <Map<String, dynamic>>[
        {
          'key': 'headword',
          'label': '見出し語',
        'type': DictionaryFieldType.text,
        'required': true,
        'enabled': true,
        'order': 0,
      },
      {
        'key': 'reading',
        'label': '読み方',
        'type': DictionaryFieldType.text,
        'required': false,
        'enabled': _enableReading,
        'order': 1,
      },
      {
        'key': 'definition',
        'label': '説明・定義',
        'type': DictionaryFieldType.multiline,
        'required': true,
        'enabled': true,
        'order': 2,
      },
      {
        'key': 'memo',
        'label': 'メモ',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableMemo,
        'order': 3,
      },
      {
        'key': 'reference_urls',
        'label': '参考URL',
        'type': DictionaryFieldType.urlList,
        'required': false,
        'enabled': _enableReferenceUrls,
        'order': 4,
      },
      {
        'key': 'synonyms',
        'label': '類義語',
        'type': DictionaryFieldType.list,
        'required': false,
        'enabled': _enableSynonyms,
        'order': 5,
      },
      {
        'key': 'antonyms',
        'label': '対義語',
        'type': DictionaryFieldType.list,
        'required': false,
        'enabled': _enableAntonyms,
        'order': 6,
      },
      {
        'key': 'related',
        'label': '関連語',
        'type': DictionaryFieldType.list,
        'required': false,
        'enabled': _enableRelated,
        'order': 7,
      },
      {
        'key': 'examples',
        'label': '例文',
        'type': DictionaryFieldType.list,
        'required': false,
        'enabled': _enableExamples,
        'order': 8,
      },
      {
        'key': 'etymology',
        'label': '語源',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableEtymology,
        'order': 9,
      },
      {
        'key': 'usage_note',
        'label': '使用上の注意',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableUsageNote,
        'order': 10,
      },
      {
        'key': 'cultural_background',
        'label': '文化的・歴史的背景',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableCulturalBackground,
        'order': 12,
      },
      {
        'key': 'trivia',
        'label': '面白エピソード・トリビア',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableTrivia,
        'order': 13,
      },
      {
        'key': 'tips',
        'label': 'ワンポイントアドバイス',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableTips,
        'order': 14,
      },
      {
        'key': 'common_mistakes',
        'label': 'よくある誤用・間違い',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableCommonMistakes,
        'order': 15,
      },
      {
        'key': 'emotional_tone',
        'label': '感情・ニュアンス',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableEmotionalTone,
        'order': 16,
      },
      {
        'key': 'quotes',
        'label': '関連する名言・引用',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableQuotes,
        'order': 17,
      },
      {
        'key': 'contrasts',
        'label': '対比される概念',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableContrasts,
        'order': 18,
      },
      {
        'key': 'case_studies',
        'label': '実践例・ケーススタディ',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableCaseStudies,
        'order': 19,
      },
      {
        'key': 'derivatives',
        'label': '派生語・慣用句',
        'type': DictionaryFieldType.list,
        'required': false,
        'enabled': _enableDerivatives,
        'order': 20,
      },
      {
        'key': 'pop_culture',
        'label': 'メディア・ポップカルチャー例',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enablePopCulture,
        'order': 21,
      },
      {
        'key': 'academic_context',
        'label': '学問分野での位置づけ',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableAcademicContext,
        'order': 22,
      },
      {
        'key': 'semantic_shift',
        'label': '意味の変遷',
        'type': DictionaryFieldType.multiline,
        'required': false,
        'enabled': _enableSemanticShift,
        'order': 23,
      },
      ];

      for (final field in fields) {
        await _db
            .into(_db.dictionaryFields)
            .insert(
              DictionaryFieldsCompanion.insert(
                dictionaryId: dictionaryId,
                fieldKey: field['key'] as String,
                label: field['label'] as String,
                fieldType: field['type'] as DictionaryFieldType,
                isRequired: Value(field['required'] as bool),
                isEnabled: Value(field['enabled'] as bool),
                sortOrder: Value(field['order'] as int),
              ),
            );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存に失敗しました')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('辞書を追加'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              '保存',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppPalette.dictionaryGeneral,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceField(
            label: '辞書名',
            hintText: '例: IT用語辞書',
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          SurfaceField(
            label: '用途（任意）',
            hintText: '例: 学習用・仕事用',
            controller: _descriptionController,
          ),
          const SizedBox(height: 12),
          SurfaceField(
            label: 'カテゴリ（任意）',
            hintText: '例: 試験, プロジェクト',
            controller: _categoryController,
          ),
          const SizedBox(height: 12),
          Text(
            'URL参照の優先タイプ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DictionaryReferenceDomain>(
            segments: const [
              ButtonSegment(
                value: DictionaryReferenceDomain.general,
                label: Text('一般'),
              ),
              ButtonSegment(
                value: DictionaryReferenceDomain.technology,
                label: Text('IT'),
              ),
              ButtonSegment(
                value: DictionaryReferenceDomain.english,
                label: Text('英語'),
              ),
            ],
            selected: {_referenceDomain},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() {
                _referenceDomain = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isWork,
            onChanged: (value) => setState(() => _isWork = value),
            title: const Text('作業用辞書として扱う'),
            subtitle: const Text('試験や期間限定の辞書におすすめ'),
          ),
          const SizedBox(height: 16),
          Text('使用する項目', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildToggle('メモ', _enableMemo, (v) => _enableMemo = v),
          _buildToggle('読み方', _enableReading, (v) => _enableReading = v),
          _buildToggle(
            '参考URL',
            _enableReferenceUrls,
            (v) => _enableReferenceUrls = v,
          ),
          _buildToggle('類義語', _enableSynonyms, (v) => _enableSynonyms = v),
          _buildToggle('対義語', _enableAntonyms, (v) => _enableAntonyms = v),
          _buildToggle('関連語', _enableRelated, (v) => _enableRelated = v),
          _buildToggle('例文', _enableExamples, (v) => _enableExamples = v),
          _buildToggle('語源', _enableEtymology, (v) => _enableEtymology = v),
          _buildToggle('使用上の注意', _enableUsageNote, (v) => _enableUsageNote = v),
          const SizedBox(height: 16),
          Text('拡張項目', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildToggle(
            '文化的・歴史的背景',
            _enableCulturalBackground,
            (v) => _enableCulturalBackground = v,
          ),
          _buildToggle(
            '面白エピソード・トリビア',
            _enableTrivia,
            (v) => _enableTrivia = v,
          ),
          _buildToggle(
            'ワンポイントアドバイス',
            _enableTips,
            (v) => _enableTips = v,
          ),
          _buildToggle(
            'よくある誤用・間違い',
            _enableCommonMistakes,
            (v) => _enableCommonMistakes = v,
          ),
          _buildToggle(
            '感情・ニュアンス',
            _enableEmotionalTone,
            (v) => _enableEmotionalTone = v,
          ),
          _buildToggle(
            '関連する名言・引用',
            _enableQuotes,
            (v) => _enableQuotes = v,
          ),
          _buildToggle(
            '対比される概念',
            _enableContrasts,
            (v) => _enableContrasts = v,
          ),
          _buildToggle(
            '実践例・ケーススタディ',
            _enableCaseStudies,
            (v) => _enableCaseStudies = v,
          ),
          _buildToggle(
            '派生語・慣用句',
            _enableDerivatives,
            (v) => _enableDerivatives = v,
          ),
          _buildToggle(
            'メディア・ポップカルチャー例',
            _enablePopCulture,
            (v) => _enablePopCulture = v,
          ),
          _buildToggle(
            '学問分野での位置づけ',
            _enableAcademicContext,
            (v) => _enableAcademicContext = v,
          ),
          _buildToggle(
            '意味の変遷',
            _enableSemanticShift,
            (v) => _enableSemanticShift = v,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: (newValue) => setState(() => onChanged(newValue)),
      title: Text(label),
    );
  }
}
