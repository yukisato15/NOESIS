import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import 'concept_memo_detail_screen.dart';
import 'concept_memo_add_ai_screen.dart';

class ConceptMemoListScreen extends ConsumerStatefulWidget {
  const ConceptMemoListScreen({super.key});

  @override
  ConsumerState<ConceptMemoListScreen> createState() =>
      _ConceptMemoListScreenState();
}

class _ConceptMemoListScreenState extends ConsumerState<ConceptMemoListScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('概念メモ'),
      ),
      body: FutureBuilder<List<ConceptMemo>>(
        future: _db.conceptMemosDao.getAllConceptMemos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('読み込みに失敗しました'),
            );
          }

          final memos = snapshot.data ?? [];

          if (memos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '概念メモがありません',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右下の+ボタンで追加',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppPalette.soften(
                      AppPalette.thinking,
                      0.2,
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: AppPalette.thinking,
                    ),
                  ),
                  title: Text(
                    memo.title ?? '無題',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memo.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          memo.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        memo.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ConceptMemoDetailScreen(memoId: memo.id),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ConceptMemoAddAIScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: AppPalette.thinking,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.psychology),
        label: const Text(
          'AI作成',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
