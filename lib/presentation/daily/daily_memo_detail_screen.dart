import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import 'package:intl/intl.dart';
import '../shared/text_action_sheet.dart';

class DailyMemoDetailScreen extends StatefulWidget {
  final int memoId;

  const DailyMemoDetailScreen({super.key, required this.memoId});

  @override
  State<DailyMemoDetailScreen> createState() => _DailyMemoDetailScreenState();
}

class _DailyMemoDetailScreenState extends State<DailyMemoDetailScreen> {
  final AppDatabase _db = AppDatabase();
  DailyMemo? _memo;
  bool _isLoading = true;
  bool _isEditing = false;

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
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadMemo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _db.close();
    super.dispose();
  }

  Future<void> _loadMemo() async {
    setState(() {
      _isLoading = true;
    });

    final memo = await _db.dailyMemosDao.getDailyMemoById(widget.memoId);
    if (memo != null) {
      setState(() {
        _memo = memo;
        _titleController.text = memo.title ?? '';
        _contentController.text = memo.content;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    await _runWithLoading(() async {
      try {
        final updatedMemo = _memo!.copyWith(
          title: drift.Value(_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null),
          content: _contentController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await _db.dailyMemosDao.updateDailyMemo(updatedMemo);

        if (!mounted) {
          return;
        }

        setState(() {
          _memo = updatedMemo;
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

  Future<void> _deleteMemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この日常メモを削除しますか?'),
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
          await _db.dailyMemosDao.deleteDailyMemo(widget.memoId);
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

    if (_memo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: const Center(child: Text('日常メモが見つかりません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '編集' : (_memo!.title ?? '日常メモ')),
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
              onPressed: _deleteMemo,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveMemo,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _titleController.text = _memo!.title ?? '';
                  _contentController.text = _memo!.content;
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.soften(AppPalette.daily, 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '日常メモ',
                  style: TextStyle(
                    color: AppPalette.daily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '作成: ${dateFormat.format(_memo!.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_memo!.title != null) ...[
            GestureDetector(
              onLongPress: () => showTextActionSheet(context, _memo!.title!),
              child: Text(
                _memo!.title!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          GestureDetector(
            onLongPress: () => showTextActionSheet(context, _memo!.content),
            child: Text(
              _memo!.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'タイトル（任意）',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '内容',
              hintText: '即時的・断片的なメモ',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 20,
          ),
        ],
      ),
    );
  }
}
