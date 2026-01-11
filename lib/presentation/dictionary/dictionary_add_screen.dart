import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/database.dart';
import '../../data/local/tables/entries_table.dart';
import '../shared/surface_field.dart';

class DictionaryAddScreen extends StatefulWidget {
  const DictionaryAddScreen({super.key});

  @override
  State<DictionaryAddScreen> createState() => _DictionaryAddScreenState();
}

class _DictionaryAddScreenState extends State<DictionaryAddScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  DictionaryDomain _selectedDomain = DictionaryDomain.general;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルと本文を入力してください')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      await _db.entriesDao.createEntry(
        EntriesCompanion(
          type: drift.Value(EntryType.dictionary),
          title: drift.Value(_titleController.text.trim()),
          body: drift.Value(_bodyController.text.trim()),
          domain: drift.Value(_selectedDomain),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('処理に失敗しました')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('辞書エントリー追加'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '辞書タイプ',
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
              hintText: '用語や単語を入力',
              controller: _titleController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            SurfaceField(
              label: '本文',
              hintText: '説明や定義を入力',
              controller: _bodyController,
              maxLines: 15,
              alignLabelWithHint: true,
            ),
          ],
        ),
      ),
    );
  }
}
