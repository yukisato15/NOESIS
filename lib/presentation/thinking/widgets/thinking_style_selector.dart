import 'package:flutter/material.dart';

import '../../../core/ai/thinking_styles/thinking_style.dart';

class _CategoryGroup {
  final String label;
  final List<ThinkingCategory> categories;

  const _CategoryGroup(this.label, this.categories);
}

class _ResolvedCategoryGroup {
  final String label;
  final List<ThinkingCategory> categories;

  const _ResolvedCategoryGroup(this.label, this.categories);
}

const List<_CategoryGroup> _groupDefinitions = [
  _CategoryGroup('哲学史・思想', [
    ThinkingCategory.ancientPhilosophy,
    ThinkingCategory.modernPhilosophy,
    ThinkingCategory.existentialism,
    ThinkingCategory.lifePhenomenology,
  ]),
  _CategoryGroup('言語・構造・社会理論', [
    ThinkingCategory.languagePhilosophy,
    ThinkingCategory.linguisticsSemiotics,
    ThinkingCategory.structuralismPost,
    ThinkingCategory.anthropologyStructuralism,
    ThinkingCategory.socialTheory,
    ThinkingCategory.folklore,
  ]),
  _CategoryGroup('政治・制度・経済', [
    ThinkingCategory.ethicsPolitical,
    ThinkingCategory.politicalSocial,
    ThinkingCategory.sciencePhilosophy,
    ThinkingCategory.economics,
    ThinkingCategory.behavioralEconomics,
    ThinkingCategory.socialEconomy,
  ]),
  _CategoryGroup('生命・脳・認知', [
    ThinkingCategory.physics,
    ThinkingCategory.biology,
    ThinkingCategory.neuroscience,
    ThinkingCategory.psychologyPsychoanalysis,
    ThinkingCategory.cognitiveScience,
  ]),
  _CategoryGroup('メディア・技術思想', [
    ThinkingCategory.mediaTheory,
    ThinkingCategory.philosophyTech,
  ]),
  _CategoryGroup('擬似人格・職業', [
    ThinkingCategory.thinkingStyle,
    ThinkingCategory.professionalModels,
    ThinkingCategory.special,
  ]),
];

List<_ResolvedCategoryGroup> _resolveGroups(
  Map<ThinkingCategory, List<ThinkingStyle>> grouped,
) {
  final resolved = <_ResolvedCategoryGroup>[];
  final included = <ThinkingCategory>{};

  for (final definition in _groupDefinitions) {
    final categories = <ThinkingCategory>[];
    for (final category in definition.categories) {
      if (grouped[category]?.isNotEmpty == true) {
        categories.add(category);
        included.add(category);
      }
    }
    if (categories.isNotEmpty) {
      resolved.add(_ResolvedCategoryGroup(definition.label, categories));
    }
  }

  final leftovers = <ThinkingCategory>[];
  for (final category in ThinkingCategory.values) {
    if (grouped[category]?.isNotEmpty == true && !included.contains(category)) {
      leftovers.add(category);
    }
  }
  if (leftovers.isNotEmpty) {
    resolved.add(_ResolvedCategoryGroup('その他', leftovers));
  }
  return resolved;
}

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
      final groups = _resolveGroups(grouped);
      String? activeGroup;

      return StatefulBuilder(
        builder: (stateContext, setState) {
          final visibleGroups = activeGroup == null
              ? groups
              : groups.where((group) => group.label == activeGroup).toList();
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: const Text('すべて'),
                            selected: activeGroup == null,
                            onSelected: (_) {
                              setState(() => activeGroup = null);
                            },
                          ),
                        ),
                        ...groups.map((group) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(group.label),
                              selected: activeGroup == group.label,
                              onSelected: (_) {
                                setState(() => activeGroup = group.label);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final group in visibleGroups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              group.label,
                              style: Theme.of(stateContext).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          for (final category in group.categories) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                              child: Text(
                                category.label,
                                style: Theme.of(
                                  stateContext,
                                ).textTheme.titleSmall,
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
                                onTap: () =>
                                    Navigator.of(sheetContext).pop(style),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<List<ThinkingStyle>?> showThinkingStyleMultiSelector(
  BuildContext context, {
  required List<ThinkingStyle> current,
  int maxSelection = 8,
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
      final groups = _resolveGroups(grouped);
      String? activeGroup;

      return StatefulBuilder(
        builder: (stateContext, setState) {
          final visibleGroups = activeGroup == null
              ? groups
              : groups.where((group) => group.label == activeGroup).toList();
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
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('すべて'),
                          selected: activeGroup == null,
                          onSelected: (_) {
                            setState(() => activeGroup = null);
                          },
                        ),
                      ),
                      ...groups.map((group) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(group.label),
                            selected: activeGroup == group.label,
                            onSelected: (_) {
                              setState(() => activeGroup = group.label);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    children: [
                      for (final group in visibleGroups) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            group.label,
                            style: Theme.of(stateContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (final category in group.categories) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Text(
                              category.label,
                              style: Theme.of(
                                stateContext,
                              ).textTheme.titleSmall,
                            ),
                          ),
                          ...grouped[category]!.map((style) {
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
                                  ScaffoldMessenger.of(
                                    rootContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text('最大$maxSelection名まで選べます。'),
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
                          }),
                        ],
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
                          : () => Navigator.of(
                              sheetContext,
                            ).pop(selected.toList()),
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
