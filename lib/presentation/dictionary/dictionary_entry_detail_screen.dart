import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/database.dart';
import '../../data/local/tables/dictionary_fields_table.dart';
import 'dictionary_entry_edit_screen.dart';
import '../shared/text_action_sheet.dart';

class DictionaryEntryDetailScreen extends StatefulWidget {
  final int dictionaryId;
  final int entryId;
  final AppDatabase? database;

  const DictionaryEntryDetailScreen({
    super.key,
    required this.dictionaryId,
    required this.entryId,
    this.database,
  });

  @override
  State<DictionaryEntryDetailScreen> createState() =>
      _DictionaryEntryDetailScreenState();
}

class _DictionaryEntryDetailScreenState
    extends State<DictionaryEntryDetailScreen> {
  AppDatabase? _db;
  AppDatabase get db => _db ?? widget.database ?? AppDatabase();

  DictionaryDefinition? _definition;
  DictionaryEntry? _entry;
  List<DictionaryField> _fields = [];
  Map<int, DictionaryEntryValue> _values = {};
  List<String> _tags = [];
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
    final definition = await db.dictionariesDao.getDictionary(
      widget.dictionaryId,
    );
    final entry = await db.dictionariesDao.getEntry(widget.entryId);
    final fields = await db.dictionariesDao.getFields(widget.dictionaryId);
    final valueList = await db.dictionariesDao.getEntryValues(widget.entryId);

    if (!mounted) {
      return;
    }

    final values = {for (final v in valueList) v.fieldId: v};
    final tags = <String>[];
    if (entry?.tags != null && entry!.tags!.isNotEmpty) {
      try {
        tags.addAll((jsonDecode(entry.tags!) as List).cast<String>());
      } catch (_) {}
    }

    setState(() {
      _definition = definition;
      _entry = entry;
      _fields = fields;
      _values = values;
      _tags = tags;
      _isLoading = false;
    });
  }

  Future<void> _editEntry() async {
    if (_entry == null) {
      return;
    }
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DictionaryEntryEditScreen(
          dictionaryId: widget.dictionaryId,
          entryId: widget.entryId,
          database: db,
        ),
      ),
    );
    if (updated == true && mounted) {
      _load();
    }
  }

  List<String> _decodeList(DictionaryFieldType type, String value) {
    if (value.isEmpty) {
      return [];
    }
    if (type == DictionaryFieldType.list ||
        type == DictionaryFieldType.urlList) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return [value];
  }

  Widget _buildSection(String label, Widget child) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildValue(DictionaryField field, String value) {
    final items = _decodeList(field.fieldType, value);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    if (field.fieldType == DictionaryFieldType.text ||
        field.fieldType == DictionaryFieldType.multiline) {
      return GestureDetector(
        onLongPress: () => showTextActionSheet(context, value),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    final linkify = field.fieldType == DictionaryFieldType.urlList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final text = item.toString();
        if (!linkify) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onLongPress: () => showTextActionSheet(context, text),
              child: Text(
                '• $text',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () => _openUrl(text),
            onLongPress: () => showTextActionSheet(context, text),
            child: Text(
              '• $text',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openUrl(String url) async {
    final candidate = url.trim();
    if (candidate.isEmpty) {
      return;
    }
    final normalized = candidate.startsWith('http')
        ? candidate
        : 'https://$candidate';
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLの形式が正しくありません')),
      );
      return;
    }
    if (!_isAllowedHost(uri.host)) {
      final proceed = await _confirmUnsafeUrl(uri);
      if (proceed == null) {
        return;
      }
      if (proceed == false) {
        await _openWikipediaFallback();
        return;
      }
    }
    final host = uri.host.toLowerCase();
    if (host.contains('example.com') || host.contains('exmple.com')) {
      await _openWikipediaFallback();
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok) {
      await _openWikipediaFallback();
    }
  }

  bool _isAllowedHost(String host) {
    final lower = host.toLowerCase();
    const allowedSuffixes = [
      'wikipedia.org',
      'wiktionary.org',
      '.go.jp',
      '.ac.jp',
      '.gov',
      '.edu',
    ];
    return allowedSuffixes.any((suffix) {
      if (suffix.startsWith('.')) {
        return lower.endsWith(suffix);
      }
      return lower == suffix || lower.endsWith('.$suffix');
    });
  }

  Future<bool?> _confirmUnsafeUrl(Uri uri) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('外部サイトを開きますか？'),
          content: Text('安全性が確認できないため、\n${uri.host}\nを開くか選択してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('やめる'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Wikipediaで開く'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('それでも開く'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openWikipediaFallback() async {
    final headword = _entry?.headword.trim() ?? '';
    if (headword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
      return;
    }
    final jp = Uri.https(
      'ja.wikipedia.org',
      '/wiki/${Uri.encodeComponent(headword)}',
    );
    final okJp = await launchUrl(jp, mode: LaunchMode.platformDefault);
    if (okJp) {
      return;
    }
    final en = Uri.https(
      'en.wikipedia.org',
      '/wiki/${Uri.encodeComponent(headword)}',
    );
    final okEn = await launchUrl(en, mode: LaunchMode.platformDefault);
    if (!okEn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('辞書エントリ')),
        body: const Center(child: Text('エントリが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_definition?.name ?? '辞書'),
        actions: [
          TextButton(
            onPressed: _editEntry,
            child: const Text('編集'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          GestureDetector(
            onLongPress: () => showTextActionSheet(context, _entry!.headword),
            child: Text(
              _entry!.headword,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_entry!.category != null && _entry!.category!.isNotEmpty)
            GestureDetector(
              onLongPress: () =>
                  showTextActionSheet(context, _entry!.category!),
              child: Text(
                _entry!.category!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                      ),
                      child: GestureDetector(
                        onLongPress: () => showTextActionSheet(context, tag),
                        child: Text(
                          tag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 28),
          ..._fields
              .where(
                (field) =>
                    field.fieldKey != 'headword' && field.isEnabled == true,
              )
              .map((field) {
            final value = _values[field.id]?.value ?? '';
            if (value.trim().isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildSection(field.label, _buildValue(field, value));
          }).toList(),
        ],
      ),
    );
  }
}
