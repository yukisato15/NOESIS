import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_palette.dart';
import '../../data/local/database.dart';
import 'concept_dictionary_add_screen.dart';
import 'concept_dictionary_list_screen.dart';
import 'philosophical_dialogue_detail_screen.dart';
import 'philosophical_dialogue_list_screen.dart';

class ThinkingScreen extends ConsumerStatefulWidget {
  const ThinkingScreen({super.key});

  @override
  ConsumerState<ThinkingScreen> createState() => _ThinkingScreenState();
}

class _ThinkingScreenState extends ConsumerState<ThinkingScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _startDialogue(BuildContext context) async {
    final id = await _db.philosophicalDialoguesDao.createDialogue(
      PhilosophicalDialoguesCompanion.insert(title: '無題の対話'),
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhilosophicalDialogueDetailScreen(
          dialogueId: id,
          isDraft: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('思索アーカイブ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ThinkingActionCard(
              title: '概念辞書を入力',
              description: '概念を直接入力して生成します',
              icon: Icons.edit_note,
              color: AppPalette.thinking,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConceptDictionaryAddScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ThinkingActionCard(
              title: '概念辞書一覧',
              description: '登録した概念を一覧で確認',
              icon: Icons.menu_book,
              color: AppPalette.thinking,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConceptDictionaryListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ThinkingActionCard(
              title: '哲学的対話',
              description: 'テーマなしで対話を開始できます',
              icon: Icons.forum,
              color: AppPalette.thinking,
              onTap: () => _startDialogue(context),
            ),
            const SizedBox(height: 14),
            _ThinkingActionCard(
              title: '対話一覧',
              description: 'これまでの対話を参照します',
              icon: Icons.chat_bubble_outline,
              color: AppPalette.thinking,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PhilosophicalDialogueListScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ThinkingActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ThinkingActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppPalette.soften(color, 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
