import 'package:flutter/material.dart';
import 'text_action_sheet.dart';

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SurfaceField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final bool alignLabelWithHint;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onLongPress;

  const SurfaceField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction,
    this.alignLabelWithHint = false,
    this.suffixIcon,
    this.onChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.primary.withOpacity(0.85),
      fontWeight: FontWeight.w600,
    );
    Future<void> runDeferredAction(Future<void> Function() action) async {
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          return;
        }
        await action();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: GestureDetector(
            onLongPress: onLongPress,
            behavior: HitTestBehavior.translucent,
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              enabled: enabled,
              readOnly: readOnly,
              textInputAction: textInputAction,
              onChanged: onChanged,
              contextMenuBuilder: (context, editableTextState) {
                final value = editableTextState.textEditingValue;
                final selection = value.selection;
                final fullText = value.text;
                final selectedText =
                    selection.isValid && !selection.isCollapsed
                        ? selection.textInside(fullText)
                        : fullText;
                final menuItems = <ContextMenuButtonItem>[
                  ContextMenuButtonItem(
                    label: 'コピー',
                    onPressed: () async {
                      editableTextState.hideToolbar();
                      await runDeferredAction(
                        () => handleTextCopy(context, selectedText),
                      );
                    },
                  ),
                  if (!readOnly)
                    ContextMenuButtonItem(
                      label: '切り取り',
                      onPressed: () {
                        editableTextState.hideToolbar();
                        editableTextState.cutSelection(
                          SelectionChangedCause.toolbar,
                        );
                      },
                    ),
                  if (!readOnly)
                    ContextMenuButtonItem(
                      label: '貼り付け',
                      onPressed: () {
                        editableTextState.pasteText(
                          SelectionChangedCause.toolbar,
                        );
                      },
                    ),
                  ContextMenuButtonItem(
                    label: '辞書に登録',
                    onPressed: () async {
                      editableTextState.hideToolbar();
                      await runDeferredAction(
                        () => handleDictionaryEntryAction(
                          context,
                          selectedText,
                        ),
                      );
                    },
                  ),
                  ContextMenuButtonItem(
                    label: '哲学的対話を始める',
                    onPressed: () async {
                      editableTextState.hideToolbar();
                      await runDeferredAction(
                        () => handleStartDialogueAction(
                          context,
                          selectedText,
                        ),
                      );
                    },
                  ),
                  ContextMenuButtonItem(
                    label: '日常メモに記録',
                    onPressed: () async {
                      editableTextState.hideToolbar();
                      await runDeferredAction(
                        () => handleDailyMemoAction(
                          context,
                          selectedText,
                        ),
                      );
                    },
                  ),
                ];
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: menuItems,
                );
              },
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
                alignLabelWithHint: alignLabelWithHint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
