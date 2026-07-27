import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/dictionary_definitions_table.dart';
import '../../data/local/tables/dictionary_fields_table.dart';
import 'dictionary_entry_edit_screen.dart';

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
  final FlutterTts _tts = FlutterTts();

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
    _tts.stop();
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
      return SelectableContextText(
        text: value,
        style: Theme.of(context).textTheme.bodyLarge,
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
            child: SelectableContextText(
              text: '• $text',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openUrl(text),
            child: SizedBox(
              width: double.infinity,
              child: SelectableContextText(
                text: '• $text',
                onTap: () => _openUrl(text),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReadingWithTts(String ipaText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableContextText(
            text: ipaText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up),
          tooltip: '発音を再生',
          onPressed: _speakEnglishHeadword,
        ),
      ],
    );
  }

  Future<void> _speakEnglishHeadword() async {
    final text = _entry?.headword.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('見出し語が空です')),
      );
      return;
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _openUrl(String url) async {
    final candidate = url.trim().replaceFirst(RegExp(r'^•\s*'), '');
    if (candidate.isEmpty) {
      return;
    }
    final normalized = candidate.startsWith(RegExp(r'https?://'))
        ? candidate
        : 'https://$candidate';
    final uri = Uri.tryParse(normalized);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLの形式が正しくありません')),
      );
      return;
    }
    final host = uri.host.toLowerCase();
    if (host.contains('example.com') || host.contains('exmple.com')) {
      await _openWikipediaFallback();
      return;
    }
    final okExternal = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (okExternal) {
      return;
    }
    final okDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!okDefault) {
      await _openWikipediaFallback();
    }
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
          SelectableContextText(
            text: _entry!.headword,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (_entry!.category != null && _entry!.category!.isNotEmpty)
            SelectableContextText(
              text: _entry!.category!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
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
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: SelectableContextText(
                        text: tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8),
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
            final label = _isEnglishDictionary && field.fieldKey == 'reading'
                ? '発音記号（IPA）'
                : field.label;
            if (_isEnglishDictionary && field.fieldKey == 'reading') {
              return _buildSection(label, _buildReadingWithTts(value));
            }
            return _buildSection(label, _buildValue(field, value));
          }).toList(),
        ],
      ),
    );
  }
}
