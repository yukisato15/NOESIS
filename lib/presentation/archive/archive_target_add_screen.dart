import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../core/ai/ai_client.dart';
import '../../core/ai/ai_mode.dart';
import '../../core/ai/search_client.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/archive_targets_table.dart';
import '../shared/surface_field.dart';

class ArchiveTargetAddScreen extends StatefulWidget {
  final ArchiveTargetType initialType;

  const ArchiveTargetAddScreen({
    super.key,
    this.initialType = ArchiveTargetType.person,
  });

  @override
  State<ArchiveTargetAddScreen> createState() => _ArchiveTargetAddScreenState();
}

class _ArchiveTargetAddScreenState extends State<ArchiveTargetAddScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _firstMetAtController = TextEditingController();
  final TextEditingController _firstMetPlaceController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mapUrlController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();

  late ArchiveTargetType _selectedType;
  bool _isSaving = false;
  bool _isGenerating = false;
  List<ArchiveTargetType> get _availableTypes => ArchiveTargetType.values
      .where(
        (type) =>
            type != ArchiveTargetType.publicFigure &&
            type != ArchiveTargetType.place &&
            type != ArchiveTargetType.topic,
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType == ArchiveTargetType.publicFigure
        ? ArchiveTargetType.person
        : widget.initialType;
  }

  @override
  void dispose() {
    _db.close();
    _nameController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _summaryController.dispose();
    _firstMetAtController.dispose();
    _firstMetPlaceController.dispose();
    _addressController.dispose();
    _mapUrlController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  List<String> _parseTags(String raw) {
    return raw
        .replaceAll('、', ',')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _autofillPublicFigure() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名前を入力してください')));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final result = await AIClient.instance.generateStructured(
        prompt:
            '''
あなたは人物アーカイブ編集者です。
以下の著名人・歴史上の人物について、人物ノートに使える基礎情報を日本語で整理してください。

名前: $name

出力はJSON形式で、以下のキーを含めてください。
- category: 分野やジャンル
- tags: 関連タグの配列（3-6件）
- summary: 人物像、業績、時代背景を短く整理した文章
- source_url: 参考URLを1件
''',
        jsonSchema: {
          'type': 'object',
          'properties': {
            'category': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
            'summary': {'type': 'string'},
            'source_url': {'type': 'string'},
          },
          'required': ['category', 'tags', 'summary', 'source_url'],
        },
        mode: SearchClient.canUseWebSearch
            ? AIMode.withSearch
            : AIMode.standard,
      );
      _categoryController.text = (result['category'] ?? '').toString();
      final tags = (result['tags'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      _tagsController.text = tags.join(', ');
      _summaryController.text = (result['summary'] ?? '').toString();
      _sourceUrlController.text = (result['source_url'] ?? '').toString();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('自動補完に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('名前は必須です')));
      return;
    }
    setState(() => _isSaving = true);
    await _db.archiveTargetsDao.insertTarget(
      ArchiveTargetsCompanion.insert(
        targetType: _selectedType,
        name: name,
        category: Value(_nullable(_categoryController.text)),
        tags: Value(_encodeTags(_tagsController.text)),
        summary: Value(_nullable(_summaryController.text)),
        firstMetAt: Value(_nullable(_firstMetAtController.text)),
        firstMetPlace: Value(_nullable(_firstMetPlaceController.text)),
        address: Value(_nullable(_addressController.text)),
        mapUrl: Value(_nullable(_mapUrlController.text)),
        sourceUrl: Value(_nullable(_sourceUrlController.text)),
        extraJson: Value(jsonEncode(<String, dynamic>{})),
      ),
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _encodeTags(String raw) {
    final tags = _parseTags(raw);
    return tags.isEmpty ? null : jsonEncode(tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('知人を追加')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '知人タイプ',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ArchiveTargetType>(
                  segments: _availableTypes
                      .map(
                        (type) =>
                            ButtonSegment(value: type, label: Text(type.label)),
                      )
                      .toList(),
                  selected: {_selectedType},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedType = selection.first;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SurfaceField(label: '名前', controller: _nameController),
          const SizedBox(height: 16),
          if (_selectedType == ArchiveTargetType.publicFigure)
            SurfaceCard(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _autofillPublicFigure,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_isGenerating ? '補完中...' : 'AIで基礎情報を補完'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.archive,
                  ),
                ),
              ),
            ),
          if (_selectedType == ArchiveTargetType.publicFigure)
            const SizedBox(height: 16),
          SurfaceField(
            label: 'カテゴリ',
            hintText: '思想家 / 俳優 / 喫茶店 / 雑談ネタ など',
            controller: _categoryController,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'タグ',
            hintText: 'カンマ区切りで入力',
            controller: _tagsController,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '概要',
            controller: _summaryController,
            maxLines: 5,
            alignLabelWithHint: true,
          ),
          if (_selectedType == ArchiveTargetType.person ||
              _selectedType == ArchiveTargetType.publicFigure) ...[
            const SizedBox(height: 16),
            SurfaceField(
              label: '出会った日・初めて知った日',
              controller: _firstMetAtController,
              readOnly: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _pickDate(_firstMetAtController),
              ),
            ),
            const SizedBox(height: 16),
            SurfaceField(
              label: '出会った場所・接点',
              controller: _firstMetPlaceController,
            ),
          ],
          if (_selectedType == ArchiveTargetType.place) ...[
            const SizedBox(height: 16),
            SurfaceField(label: '住所', controller: _addressController),
            const SizedBox(height: 16),
            SurfaceField(
              label: 'Google Maps URL',
              controller: _mapUrlController,
            ),
          ],
          if (_selectedType == ArchiveTargetType.publicFigure) ...[
            const SizedBox(height: 16),
            SurfaceField(label: '参考URL', controller: _sourceUrlController),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? '保存中...' : '保存する'),
            ),
          ),
        ],
      ),
    );
  }
}
