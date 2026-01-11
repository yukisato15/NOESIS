import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';

class ConceptMemoAddScreen extends StatefulWidget {
  const ConceptMemoAddScreen({super.key});

  @override
  State<ConceptMemoAddScreen> createState() => _ConceptMemoAddScreenState();
}

class _ConceptMemoAddScreenState extends State<ConceptMemoAddScreen> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      await _db.conceptMemosDao.createConceptMemo(
        ConceptMemosCompanion(
          title: drift.Value(_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null),
          content: drift.Value(_contentController.text.trim()),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('概念メモ追加'),
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemo,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.soften(AppPalette.thinking, 0.9),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppPalette.thinking.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: AppPalette.thinking),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '思考や概念を自由に記述してください。\n後でAI機能を使って要約や対話ができます。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル（任意）',
                hintText: '例: ハイデガーの存在論',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '思考や概念を自由に記述...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 20,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }
}
