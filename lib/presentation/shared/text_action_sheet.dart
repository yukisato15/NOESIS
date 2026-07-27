import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/database.dart';
import '../daily/daily_memo_add_screen.dart';
import '../dictionary/dictionary_entry_edit_screen.dart';
import '../thinking/concept_dictionary_add_screen.dart';
import '../thinking/philosophical_dialogue_detail_screen.dart';

enum _TextAction {
  copy,
  addDictionaryEntry,
  startDialogue,
  addDailyMemo,
}

class _DictionaryTarget {
  final int? dictionaryId;
  final bool isConcept;
  final String label;

  const _DictionaryTarget.concept()
      : dictionaryId = null,
        isConcept = true,
        label = '概念辞書';

  const _DictionaryTarget.dictionary(this.dictionaryId, this.label)
      : isConcept = false;
}

Future<void> showTextActionSheet(BuildContext context, String text) async {
  final value = text.trim();
  if (value.isEmpty) {
    return;
  }
  final action = await showModalBottomSheet<_TextAction>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('コピー'),
              onTap: () => Navigator.of(sheetContext).pop(_TextAction.copy),
            ),
            ListTile(
              leading: const Icon(Icons.book_outlined),
              title: const Text('辞書に登録'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_TextAction.addDictionaryEntry),
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('哲学的対話を始める'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_TextAction.startDialogue),
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('日常メモに記録'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_TextAction.addDailyMemo),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted) {
    return;
  }

  switch (action) {
    case _TextAction.copy:
      await handleTextCopy(context, value);
      return;
    case _TextAction.addDictionaryEntry:
      await handleDictionaryEntryAction(context, value);
      return;
    case _TextAction.startDialogue:
      await handleStartDialogueAction(context, value);
      return;
    case _TextAction.addDailyMemo:
      await handleDailyMemoAction(context, value);
      return;
    case null:
      return;
  }
}

Future<void> handleTextCopy(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コピーしました')),
    );
  }
}

Future<void> handleDictionaryEntryAction(
  BuildContext context,
  String value,
) async {
  // 新しいデータベースインスタンスを作成（一時的）
  final db = AppDatabase();

  try {
    final dictionaries = await db.dictionariesDao.getAllDictionaries();
    if (!context.mounted) {
      return;
    }

    final target = await showModalBottomSheet<_DictionaryTarget>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('登録先を選択')),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('概念辞書'),
                onTap: () => Navigator.of(sheetContext)
                    .pop(const _DictionaryTarget.concept()),
              ),
              ...dictionaries.map(
                (dict) => ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(dict.name),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _DictionaryTarget.dictionary(dict.id, dict.name),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (target == null || !context.mounted) {
      return;
    }

    if (target.isConcept) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConceptDictionaryAddScreen(initialTitle: value),
        ),
      );
      return;
    }

    if (target.dictionaryId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DictionaryEntryEditScreen(
            dictionaryId: target.dictionaryId!,
            initialHeadword: value,
          ),
        ),
      );
    }
  } finally {
    db.close();
  }
}

Future<void> handleStartDialogueAction(
  BuildContext context,
  String value,
) async {
  // 新しいデータベースインスタンスを作成（一時的）
  final db = AppDatabase();

  try {
    final dialogueId = await db.philosophicalDialoguesDao.createDialogue(
      PhilosophicalDialoguesCompanion.insert(title: '無題の対話'),
    );
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhilosophicalDialogueDetailScreen(
          dialogueId: dialogueId,
          initialMessage: value,
          isDraft: true,
        ),
      ),
    );
  } finally {
    db.close();
  }
}

Future<void> handleDailyMemoAction(
  BuildContext context,
  String value,
) async {
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DailyMemoAddScreen(initialContent: value),
    ),
  );
}
