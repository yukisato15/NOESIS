import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../data/local/tables/dictionary_definitions_table.dart';
import '../shared/surface_field.dart';

class DictionarySettingsScreen extends StatefulWidget {
  final int dictionaryId;
  final AppDatabase? database;

  const DictionarySettingsScreen({
    super.key,
    required this.dictionaryId,
    this.database,
  });

  @override
  State<DictionarySettingsScreen> createState() =>
      _DictionarySettingsScreenState();
}

class _DictionarySettingsScreenState extends State<DictionarySettingsScreen> {
  AppDatabase? _db;
  AppDatabase get db {
    _db ??= widget.database ?? AppDatabase();
    return _db!;
  }
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DictionaryReferenceDomain _referenceDomain =
      DictionaryReferenceDomain.general;

  DictionaryDefinition? _definition;
  List<DictionaryField> _fields = [];
  bool _isWork = false;
  bool _isSaving = false;

  bool get _isEnglishDictionary {
    if (_definition?.referenceDomain == DictionaryReferenceDomain.english) {
      return true;
    }
    return _definition?.category == 'english' || _definition?.name == '英語辞書';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.database == null) {
      _db?.close();
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await db.ensureDictionaryRecovery();
      final definition = await db.dictionariesDao.getDictionary(
        widget.dictionaryId,
      );
      if (definition == null) {
        return;
      }
      final fields = await db.dictionariesDao.getFields(widget.dictionaryId);

      if (!mounted) {
        return;
      }

      setState(() {
        _definition = definition;
        _fields = fields;
        _nameController.text = definition.name;
        _descriptionController.text = definition.description ?? '';
        _categoryController.text = definition.category ?? '';
        _referenceDomain = definition.referenceDomain;
        _isWork = definition.isWork;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('読み込みに失敗しました')));
      }
    }
  }

  Future<void> _save() async {
    if (_definition == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = _definition!.copyWith(
        name: _nameController.text.trim().isEmpty
            ? _definition!.name
            : _nameController.text.trim(),
        description: Value(
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
        isWork: _isWork,
        category: Value(
          _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
        ),
        referenceDomain: _referenceDomain,
        updatedAt: DateTime.now(),
      );

      await db.dictionariesDao.updateDictionary(updated);

      for (final field in _fields) {
        await db.dictionariesDao.updateField(field);
      }

      if (mounted) {
        setState(() {
          _definition = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[DictionarySettings] Save failed: $e');
      debugPrint('[DictionarySettings] Stack trace: $stackTrace');
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

  Future<void> _delete() async {
    if (_definition == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('辞書を削除しますか？'),
          content: const Text('この辞書とエントリを削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final entries = await db.dictionariesDao.getEntries(widget.dictionaryId);
      final entryIds = entries.map((entry) => entry.id).toList();
      if (entryIds.isNotEmpty) {
        await (db.delete(
          db.dictionaryEntryValues,
        )..where((t) => t.entryId.isIn(entryIds))).go();
      }
      await (db.delete(
        db.dictionaryEntries,
      )..where((t) => t.dictionaryId.equals(widget.dictionaryId))).go();
      await (db.delete(
        db.dictionaryFields,
      )..where((t) => t.dictionaryId.equals(widget.dictionaryId))).go();
      await db.dictionariesDao.deleteDictionary(widget.dictionaryId);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('削除に失敗しました')));
      }
    }
  }

  void _toggleField(DictionaryField field, bool enabled) {
    setState(() {
      _fields = _fields.map((f) {
        if (f.id == field.id) {
          return f.copyWith(isEnabled: enabled);
        }
        return f;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('辞書設定'),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _definition?.isSystem == true ? null : _delete,
          ),
        ],
      ),
      body: _definition == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SurfaceField(
                  label: '辞書名',
                  controller: _nameController,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: '用途（任意）',
                  controller: _descriptionController,
                ),
                const SizedBox(height: 12),
                SurfaceField(
                  label: 'カテゴリ（任意）',
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
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isWork,
                  onChanged: _definition?.isSystem == true
                      ? null
                      : (value) => setState(() => _isWork = value),
                  title: const Text('作業用辞書'),
                ),
                const SizedBox(height: 16),
                Text('使用する項目', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._fields
                    .where(
                      (field) =>
                          field.fieldKey != 'headword' &&
                          field.fieldKey != 'definition',
                    )
                    .map(
                      (field) {
                        final label =
                            _isEnglishDictionary && field.fieldKey == 'reading'
                                ? '発音記号（IPA）'
                                : field.label;
                        return SwitchListTile(
                          value: field.isEnabled,
                          onChanged: (value) => _toggleField(field, value),
                          title: Text(label),
                        );
                      },
                    ),
              ],
            ),
    );
  }
}
