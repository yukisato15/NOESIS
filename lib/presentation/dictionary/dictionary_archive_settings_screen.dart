import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import 'dictionary_settings_screen.dart';

class DictionaryArchiveSettingsScreen extends StatefulWidget {
  final AppDatabase? database;

  const DictionaryArchiveSettingsScreen({super.key, this.database});

  @override
  State<DictionaryArchiveSettingsScreen> createState() =>
      _DictionaryArchiveSettingsScreenState();
}

class _DictionaryArchiveSettingsScreenState
    extends State<DictionaryArchiveSettingsScreen> {
  AppDatabase? _db;
  AppDatabase get db {
    _db ??= widget.database ?? AppDatabase();
    return _db!;
  }

  List<DictionaryDefinition> _dictionaries = [];
  bool _isLoading = true;

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
    final dictionaries = await db.dictionariesDao.getAllDictionaries();
    if (!mounted) {
      return;
    }
    setState(() {
      _dictionaries = dictionaries;
      _isLoading = false;
    });
  }

  List<DictionaryDefinition> get _customDictionaries =>
      _dictionaries.where((d) => !d.isSystem).toList();

  Future<void> _mergeDictionary() async {
    if (_customDictionaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('統合対象の辞書がありません')),
      );
      return;
    }

    DictionaryDefinition? source;
    DictionaryDefinition? target;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final targetOptions =
                _dictionaries.where((d) => d.id != source?.id).toList();
            return AlertDialog(
              title: const Text('辞書の統合'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DictionaryDefinition>(
                    value: source,
                    decoration: const InputDecoration(
                      labelText: '統合元（削除されます）',
                    ),
                    items: _customDictionaries
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        source = value;
                        if (target?.id == value?.id) {
                          target = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DictionaryDefinition>(
                    value: target,
                    decoration: const InputDecoration(
                      labelText: '統合先',
                    ),
                    items: targetOptions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => target = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed:
                      source == null || target == null ? null : () async {
                        Navigator.of(dialogContext).pop(true);
                      },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || source == null || target == null) {
      return;
    }

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('本当に統合しますか？'),
          content: Text('「${source!.name}」を「${target!.name}」に統合します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (finalConfirm != true) {
      return;
    }

    await db.mergeDictionaries(
      sourceId: source!.id,
      targetId: target!.id,
      deleteSource: true,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('辞書を統合しました')),
    );
    _load();
  }

  Future<void> _openFieldSettings() async {
    DictionaryDefinition? target;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('辞書項目のカスタマイズ'),
              content: DropdownButtonFormField<DictionaryDefinition>(
                value: target,
                decoration: const InputDecoration(labelText: '対象の辞書'),
                items: _dictionaries
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => target = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: target == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('開く'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || target == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DictionarySettingsScreen(
          dictionaryId: target!.id,
          database: db,
        ),
      ),
    );
    _load();
  }

  Future<void> _deleteDictionary() async {
    if (_customDictionaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除できる辞書がありません')),
      );
      return;
    }

    DictionaryDefinition? target;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('辞書の削除'),
              content: DropdownButtonFormField<DictionaryDefinition>(
                value: target,
                decoration: const InputDecoration(labelText: '削除する辞書'),
                items: _customDictionaries
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => target = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: target == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || target == null) {
      return;
    }

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('本当に削除しますか？'),
          content: Text('「${target!.name}」を削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (finalConfirm != true) {
      return;
    }

    await db.deleteDictionaryCascade(target!.id);

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('辞書を削除しました')),
    );
    _load();
  }

  Future<void> _backupDatabase() async {
    final path = await db.backupDatabase();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('バックアップを作成しました: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('辞書アーカイブ設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('辞書の統合'),
            subtitle: const Text('作成した辞書を別の辞書に統合'),
            onTap: _mergeDictionary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('辞書項目のカスタマイズ'),
            subtitle: const Text('項目の追加・削除を設定'),
            onTap: _openFieldSettings,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('辞書の削除'),
            subtitle: const Text('作成した辞書を削除'),
            onTap: _deleteDictionary,
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('データバックアップ（ローカル）'),
            subtitle: const Text('端末内にバックアップを作成'),
            onTap: _backupDatabase,
          ),
        ],
      ),
    );
  }
}
