import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/dao/dictionaries_dao.dart';
import 'dictionary_entry_edit_screen.dart';
import 'dictionary_entry_detail_screen.dart';

class DictionaryEntriesScreen extends ConsumerStatefulWidget {
  final int dictionaryId;
  final AppDatabase? database;

  const DictionaryEntriesScreen({
    super.key,
    required this.dictionaryId,
    this.database,
  });

  @override
  ConsumerState<DictionaryEntriesScreen> createState() =>
      _DictionaryEntriesScreenState();
}

class _DictionaryEntriesScreenState
    extends ConsumerState<DictionaryEntriesScreen>
    with AutomaticKeepAliveClientMixin {
  AppDatabase? _db;
  AppDatabase get db => _db ?? widget.database ?? AppDatabase();
  DictionaryDefinition? _definition;
  List<DictionaryEntry> _entries = [];
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  bool get wantKeepAlive => true;

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
    super.dispose();
  }

  Future<void> _load() async {
    await db.ensureDictionaryRecovery();
    final definition = await db.dictionariesDao.getDictionary(
      widget.dictionaryId,
    );
    final entries = await db.dictionariesDao.getEntries(widget.dictionaryId);

    if (!mounted) {
      return;
    }

    setState(() {
      _definition = definition;
      _entries = entries;
    });
  }

  void _toggleSelection(int entryId) {
    setState(() {
      if (_selectedIds.contains(entryId)) {
        _selectedIds.remove(entryId);
      } else {
        _selectedIds.add(entryId);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _deleteEntry(int entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('エントリを削除しますか？'),
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

    await db.dictionariesDao.deleteEntry(entryId);
    await db.dictionariesDao.deleteEntryValues(entryId);

    if (mounted) {
      _load();
    }
  }

  Future<void> _moveSelectedEntries() async {
    if (_selectedIds.isEmpty) {
      return;
    }

    final dictionaries = await db.dictionariesDao.getAllDictionaries();
    final selection = await showDialog<_MergeSelection>(
      context: context,
      builder: (dialogContext) {
        int? selectedId;
        bool addMemo = true;
        EntryConflictPolicy conflictPolicy = EntryConflictPolicy.skip;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('他の辞書に統合'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedId,
                      items: dictionaries
                          .where((dict) => dict.id != widget.dictionaryId)
                          .map(
                            (dict) => DropdownMenuItem(
                              value: dict.id,
                              child: Text(dict.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => selectedId = value),
                      decoration: const InputDecoration(labelText: '統合先'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<EntryConflictPolicy>(
                      value: conflictPolicy,
                      decoration:
                          const InputDecoration(labelText: '重複語の扱い'),
                      items: const [
                        DropdownMenuItem(
                          value: EntryConflictPolicy.skip,
                          child: Text('スキップ（移動しない）'),
                        ),
                        DropdownMenuItem(
                          value: EntryConflictPolicy.overwrite,
                          child: Text('上書き（移動を優先）'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => conflictPolicy = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: addMemo,
                      onChanged: (value) =>
                          setState(() => addMemo = value ?? true),
                      title: const Text('元辞書名をメモに追記'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: selectedId == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(
                            _MergeSelection(
                              targetId: selectedId!,
                              addMemo: addMemo,
                              conflictPolicy: conflictPolicy,
                            ),
                          ),
                  child: const Text('統合'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selection == null) {
      return;
    }

    final movedIds = await db.dictionariesDao.mergeEntries(
      entryIds: _selectedIds.toList(),
      targetDictionaryId: selection.targetId,
      conflictPolicy: selection.conflictPolicy,
    );

    if (selection.addMemo && movedIds.isNotEmpty) {
      final targetFields = await db.dictionariesDao.getFields(
        selection.targetId,
      );
      final memoField = targetFields.firstWhere(
        (field) => field.fieldKey == 'memo',
        orElse: () => targetFields.first,
      );
      final sourceName = _definition?.name ?? '元辞書';
      for (final entryId in movedIds) {
        final values = await db.dictionariesDao.getEntryValues(entryId);
        final memoValue = values
            .firstWhere(
              (value) => value.fieldId == memoField.id,
              orElse: () => DictionaryEntryValue(
                id: -1,
                entryId: entryId,
                fieldId: memoField.id,
                value: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .value;
        final updatedMemo = memoValue.trim().isEmpty
            ? '移動元: $sourceName'
            : '$memoValue\n\n移動元: $sourceName';
        await db.dictionariesDao.upsertEntryValue(
          DictionaryEntryValuesCompanion.insert(
            entryId: entryId,
            fieldId: memoField.id,
            value: updatedMemo,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_definition?.name ?? '辞書'),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.drive_file_move_outline),
              tooltip: '他の辞書に統合',
              onPressed: _moveSelectedEntries,
            ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text('エントリがありません', style: theme.textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final selected = _selectedIds.contains(entry.id);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: _selectionMode
                        ? Checkbox(
                            value: selected,
                            onChanged: (_) => _toggleSelection(entry.id),
                          )
                        : null,
                    title: Text(entry.headword),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteEntry(entry.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('削除')),
                      ],
                    ),
                    onTap: () async {
                      if (_selectionMode) {
                        _toggleSelection(entry.id);
                        return;
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DictionaryEntryDetailScreen(
                            dictionaryId: widget.dictionaryId,
                            entryId: entry.id,
                            database: db,
                          ),
                        ),
                      );
                      _load();
                    },
                    onLongPress: () {
                      setState(() {
                        _selectionMode = true;
                        _selectedIds.add(entry.id);
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'entry_add_${widget.dictionaryId}',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DictionaryEntryEditScreen(
                dictionaryId: widget.dictionaryId,
                database: db,
              ),
            ),
          );
          _load();
        },
        backgroundColor: AppPalette.dictionaryGeneral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('エントリ追加'),
      ),
    );
  }
}

class _MergeSelection {
  final int targetId;
  final bool addMemo;
  final EntryConflictPolicy conflictPolicy;

  const _MergeSelection({
    required this.targetId,
    required this.addMemo,
    required this.conflictPolicy,
  });
}
