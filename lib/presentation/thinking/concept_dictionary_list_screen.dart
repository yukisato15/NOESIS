import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import '../../data/local/tables/concept_dictionaries_table.dart';
import 'concept_dictionary_add_screen.dart';
import 'concept_dictionary_detail_screen.dart';

class ConceptDictionaryListScreen extends ConsumerStatefulWidget {
  const ConceptDictionaryListScreen({super.key});

  @override
  ConsumerState<ConceptDictionaryListScreen> createState() =>
      _ConceptDictionaryListScreenState();
}

class _ConceptDictionaryListScreenState
    extends ConsumerState<ConceptDictionaryListScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  String _originLabel(ConceptOrigin origin) {
    switch (origin) {
      case ConceptOrigin.direct:
        return '直接入力';
      case ConceptOrigin.dialogue:
        return '対話から登録';
    }
  }

  Future<void> _deleteConcept(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('概念辞書を削除しますか？'),
          content: const Text('この項目を削除します。'),
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

    await (_db.delete(
      _db.conceptDictionaries,
    )..where((t) => t.id.equals(id))).go();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('概念辞書一覧')),
      body: FutureBuilder<List<ConceptDictionary>>(
        future:
            (_db.select(_db.conceptDictionaries)..orderBy([
                  (t) => OrderingTerm(
                    expression: t.updatedAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('読み込みに失敗しました'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text('概念辞書がありません', style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppPalette.soften(
                      AppPalette.thinking,
                      0.2,
                    ),
                    child: Icon(Icons.menu_book, color: AppPalette.thinking),
                  ),
                  title: Text(item.title, style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    _originLabel(item.origin),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteConcept(item.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'delete', child: Text('削除')),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ConceptDictionaryDetailScreen(conceptId: item.id),
                      ),
                    );
                    if (mounted) {
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
              builder: (_) => const ConceptDictionaryAddScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: AppPalette.thinking,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }
}
