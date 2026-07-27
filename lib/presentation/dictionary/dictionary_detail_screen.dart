import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/selectable_context_text.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/entries_table.dart';
import '../shared/surface_field.dart';
import 'package:intl/intl.dart';

class DictionaryDetailScreen extends StatefulWidget {
  final int entryId;

  const DictionaryDetailScreen({super.key, required this.entryId});

  @override
  State<DictionaryDetailScreen> createState() => _DictionaryDetailScreenState();
}

class _DictionaryDetailScreenState extends State<DictionaryDetailScreen> {
  final AppDatabase _db = AppDatabase();
  final FlutterTts _tts = FlutterTts();
  Entry? _entry;
  Map<String, dynamic>? _aiAppendix;
  bool _isLoading = true;
  bool _isEditing = false;

  bool get _isEnglishDomain =>
      _entry?.domain == DictionaryDomain.english;

  Future<T?> _runWithLoading<T>(Future<T?> Function() action) async {
    if (!mounted) {
      return null;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await action();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  DictionaryDomain _selectedDomain = DictionaryDomain.general;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _loadEntry();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _db.close();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() {
      _isLoading = true;
    });

    final entry = await _db.entriesDao.getEntryById(widget.entryId);
    if (entry != null) {
      setState(() {
        _entry = entry;
        _titleController.text = entry.title;
        _bodyController.text = entry.body;
        _selectedDomain = entry.domain;
        _isLoading = false;
      });
      await _loadAppendix();
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadAppendix() async {
    final appendix = await (_db.select(_db.entryAppendices)
          ..where((t) => t.entryId.equals(widget.entryId))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.createdAt, mode: drift.OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    if (appendix == null) {
      setState(() {
        _aiAppendix = null;
      });
      return;
    }

    try {
      final decoded = jsonDecode(appendix.content);
      if (decoded is Map<String, dynamic>) {
        setState(() {
          _aiAppendix = decoded;
        });
      } else {
        setState(() {
          _aiAppendix = null;
        });
      }
    } catch (_) {
      setState(() {
        _aiAppendix = null;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルと本文を入力してください')),
      );
      return;
    }

    await _runWithLoading(() async {
      try {
        final updatedEntry = _entry!.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          domain: _selectedDomain,
          updatedAt: DateTime.now(),
        );

        await _db.entriesDao.updateEntry(updatedEntry);

        if (!mounted) {
          return;
        }

        setState(() {
          _entry = updatedEntry;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました')),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存に失敗しました')),
          );
        }
      }
    });
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このエントリーを削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runWithLoading(() async {
        try {
          await _db.entriesDao.deleteEntry(widget.entryId);
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('削除に失敗しました')),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: const Center(child: Text('エントリーが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編集' : _entry!.title),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteEntry,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _titleController.text = _entry!.title;
                  _bodyController.text = _entry!.body;
                  _selectedDomain = _entry!.domain;
                  _isEditing = false;
                });
              },
            ),
          ],
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  Widget _buildViewMode() {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DomainBadge(domain: _entry!.domain),
              const Spacer(),
              Text(
                '更新: ${dateFormat.format(_entry!.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _entry!.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            _entry!.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (_aiAppendix != null) ...[
            const SizedBox(height: 24),
            const Text(
              '補足情報',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: _isEnglishDomain ? '発音記号（IPA）' : '読み方',
              child: _isEnglishDomain
                  ? _buildReadingWithTts(_aiAppendix!['reading'])
                  : _buildTextValue(_aiAppendix!['reading']),
            ),
            _buildSectionCard(
              title: 'ジャンル',
              child: _buildTextValue(_aiAppendix!['genre']),
            ),
            _buildSectionCard(
              title: '語源',
              child: _buildTextValue(_aiAppendix!['etymology']),
            ),
            _buildSectionCard(
              title: '使用上の注意',
              child: _buildTextValue(_aiAppendix!['usage_note']),
            ),
            _buildSectionCard(
              title: '例文',
              child: _buildListValue(_aiAppendix!['examples']),
            ),
            _buildSectionCard(
              title: '類義語',
              child: _buildListValue(_aiAppendix!['synonyms']),
            ),
            _buildSectionCard(
              title: '対義語',
              child: _buildListValue(_aiAppendix!['antonyms']),
            ),
            _buildSectionCard(
              title: '関連語',
              child: _buildListValue(_aiAppendix!['related']),
            ),
            _buildSectionCard(
              title: '参考URL',
              child: _buildListValue(
                _aiAppendix!['reference_urls'],
                linkify: true,
              ),
            ),
          ],
        ],
      ),
    );
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
    final okExternal = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (okExternal) {
      return;
    }
    final okDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!okDefault && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return const Text('—');
    }
    return SelectableContextText(text: text);
  }

  Widget _buildReadingWithTts(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return const Text('—');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: SelectableContextText(text: text)),
        IconButton(
          icon: const Icon(Icons.volume_up),
          tooltip: '発音を再生',
          onPressed: _speakEnglishHeadword,
        ),
      ],
    );
  }

  Future<void> _speakEnglishHeadword() async {
    final text = _entry?.title.trim() ?? '';
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

  Widget _buildListValue(dynamic items, {bool linkify = false}) {
    if (items is! List || items.isEmpty) {
      return const Text('—');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        final text = item.toString();
        if (!linkify) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableContextText(text: '• $text'),
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
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ドメイン',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
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
            onSelectionChanged: (selection) {
              setState(() {
                _selectedDomain = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: 'タイトル',
            controller: _titleController,
          ),
          const SizedBox(height: 16),
          SurfaceField(
            label: '本文',
            controller: _bodyController,
            maxLines: 15,
            alignLabelWithHint: true,
          ),
        ],
      ),
    );
  }
}

class _DomainBadge extends StatelessWidget {
  final DictionaryDomain domain;

  const _DomainBadge({required this.domain});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (domain) {
      case DictionaryDomain.general:
        label = '一般';
        color = AppPalette.dictionaryGeneral;
        break;
      case DictionaryDomain.technology:
        label = 'IT用語';
        color = AppPalette.dictionaryTech;
        break;
      case DictionaryDomain.english:
        label = '英語';
        color = AppPalette.dictionaryEnglish;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
