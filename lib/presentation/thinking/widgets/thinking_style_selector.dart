import 'package:flutter/material.dart';

import '../../../core/ai/thinking_styles/thinking_style.dart';

Future<ThinkingStyle?> showThinkingStyleSelector(
  BuildContext context, {
  required ThinkingStyle current,
}) {
  return showModalBottomSheet<ThinkingStyle>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final grouped = <ThinkingCategory, List<ThinkingStyle>>{};
      for (final style in ThinkingStyle.values) {
        grouped.putIfAbsent(style.category, () => []).add(style);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            children: [
              for (final category in ThinkingCategory.values)
                if (grouped[category]?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      category.label,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  ...grouped[category]!.map(
                    (style) => ListTile(
                      title: Text(style.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(style.field),
                          Text(style.background),
                          Text(style.focus),
                        ],
                      ),
                      trailing: style == current
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.of(sheetContext).pop(style),
                    ),
                  ),
                ],
            ],
          ),
        ),
      );
    },
  );
}

Future<List<ThinkingStyle>?> showThinkingStyleMultiSelector(
  BuildContext context, {
  required List<ThinkingStyle> current,
  int maxSelection = 4,
}) {
  final rootContext = context;
  return showModalBottomSheet<List<ThinkingStyle>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final selected = current.toSet();
      final grouped = <ThinkingCategory, List<ThinkingStyle>>{};
      for (final style in ThinkingStyle.values) {
        grouped.putIfAbsent(style.category, () => []).add(style);
      }

      return StatefulBuilder(
        builder: (stateContext, setState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        '参加者を選択（最大$maxSelection）',
                        style: Theme.of(stateContext).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${selected.length}/$maxSelection',
                        style: Theme.of(stateContext).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final category in ThinkingCategory.values)
                        if (grouped[category]?.isNotEmpty == true) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              category.label,
                              style: Theme.of(stateContext)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ),
                          ...grouped[category]!.map(
                            (style) {
                              final isSelected = selected.contains(style);
                              return ListTile(
                                title: Text(style.displayName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(style.field),
                                    Text(style.background),
                                    Text(style.focus),
                                  ],
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check)
                                    : null,
                                onTap: () {
                                  if (!isSelected &&
                                      selected.length >= maxSelection) {
                                    ScaffoldMessenger.of(rootContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '最大$maxSelection名まで選べます。',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    if (isSelected) {
                                      selected.remove(style);
                                    } else {
                                      selected.add(style);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () => Navigator.of(sheetContext)
                              .pop(selected.toList()),
                      child: const Text('完了'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
