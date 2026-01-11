import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/database.dart';
import '../../data/local/tables/entries_table.dart';

class ReadingAddScreen extends StatefulWidget {
  const ReadingAddScreen({super.key});

  @override
  State<ReadingAddScreen> createState() => _ReadingAddScreenState();
}

class _ReadingAddScreenState extends State<ReadingAddScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _bookController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _bookController.dispose();
    _genreController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty ||
        _bookController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトル、本文、書籍名を入力してください')),
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
          type: drift.Value(EntryType.readingNote),
          title: drift.Value(_titleController.text.trim()),
          body: drift.Value(_bodyController.text.trim()),
          reading: drift.Value(_bookController.text.trim()),
          genre: drift.Value(_genreController.text.trim().isNotEmpty
              ? _genreController.text.trim()
              : null),
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
        title: const Text('読書ノート追加'),
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
            TextField(
              controller: _bookController,
              decoration: const InputDecoration(
                labelText: '書籍名',
                hintText: '読んだ本のタイトル',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(
                labelText: 'ジャンル（任意）',
                hintText: '例: 小説、ビジネス書、技術書',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                hintText: 'メモのタイトル',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '本文',
                hintText: 'メモや感想を入力',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
            ),
          ],
        ),
      ),
    );
  }
}
