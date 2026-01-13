import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/shared/text_action_sheet.dart';

enum _ContextAction {
  copy,
  dictionary,
  dialogue,
  dailyMemo,
  askAboutCode,
}

/// 選択可能なテキストウィジェット
/// 長押しで範囲選択し、コンテキストメニューから各種アクションを実行可能
class SelectableContextText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final Function(String selectedText)? onCopy;
  final Function(String selectedText)? onAddToDictionary;
  final Function(String selectedText)? onStartPhilosophicalDialogue;
  final Function(String selectedText)? onAddToDailyMemo;
  final Function(String selectedText)? onAskAboutCode;
  final bool enableDefaultActions;

  const SelectableContextText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
    this.onCopy,
    this.onAddToDictionary,
    this.onStartPhilosophicalDialogue,
    this.onAddToDailyMemo,
    this.onAskAboutCode,
    this.enableDefaultActions = true,
  });

  @override
  State<SelectableContextText> createState() => _SelectableContextTextState();
}

class _SelectableContextTextState extends State<SelectableContextText> {
  _ContextAction? _pendingAction;
  String? _pendingText;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.text,
      style: widget.style,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      contextMenuBuilder: (context, editableTextState) {
        final TextEditingValue value = editableTextState.textEditingValue;
        final String selectedText = value.selection.textInside(value.text);

        if (selectedText.isEmpty) {
          // 選択されていない場合はデフォルトメニュー
          return AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
        }

        // カスタムコンテキストメニュー
        return AdaptiveTextSelectionToolbar(
          anchors: editableTextState.contextMenuAnchors,
          children: [
            // コピー
            TextSelectionToolbarTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () {
                ContextMenuController.removeAny();
                Clipboard.setData(ClipboardData(text: selectedText));
                if (widget.onCopy != null) {
                  widget.onCopy!(selectedText);
                } else if (widget.enableDefaultActions && context.mounted) {
                  handleTextCopy(context, selectedText);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('コピー'),
                ],
              ),
            ),

            // 辞書に登録
            if (widget.onAddToDictionary != null)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  widget.onAddToDictionary!(selectedText);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book, size: 18),
                    SizedBox(width: 8),
                    Text('辞書に登録'),
                  ],
                ),
              )
            else if (widget.enableDefaultActions)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  setState(() {
                    _pendingAction = _ContextAction.dictionary;
                    _pendingText = selectedText;
                  });
                  // 次のフレームでアクションを実行
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _executePendingAction();
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book, size: 18),
                    SizedBox(width: 8),
                    Text('辞書に登録'),
                  ],
                ),
              ),

            // 哲学的対話を始める
            if (widget.onStartPhilosophicalDialogue != null)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  widget.onStartPhilosophicalDialogue!(selectedText);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 18),
                    SizedBox(width: 8),
                    Text('哲学的対話'),
                  ],
                ),
              )
            else if (widget.enableDefaultActions)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  setState(() {
                    _pendingAction = _ContextAction.dialogue;
                    _pendingText = selectedText;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _executePendingAction();
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 18),
                    SizedBox(width: 8),
                    Text('哲学的対話'),
                  ],
                ),
              ),

            // 日常メモに記録
            if (widget.onAddToDailyMemo != null)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  widget.onAddToDailyMemo!(selectedText);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_add, size: 18),
                    SizedBox(width: 8),
                    Text('日常メモ'),
                  ],
                ),
              )
            else if (widget.enableDefaultActions)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  setState(() {
                    _pendingAction = _ContextAction.dailyMemo;
                    _pendingText = selectedText;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _executePendingAction();
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_add, size: 18),
                    SizedBox(width: 8),
                    Text('日常メモ'),
                  ],
                ),
              ),

            // コードについて質問
            if (widget.onAskAboutCode != null)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  ContextMenuController.removeAny();
                  widget.onAskAboutCode!(selectedText);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline, size: 18),
                    SizedBox(width: 8),
                    Text('このコードについて質問'),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _executePendingAction() {
    if (_pendingAction == null || _pendingText == null || !mounted) {
      return;
    }

    final action = _pendingAction!;
    final text = _pendingText!;

    // リセット
    setState(() {
      _pendingAction = null;
      _pendingText = null;
    });

    // アクション実行
    switch (action) {
      case _ContextAction.copy:
        // コピーは直接実行済み
        break;
      case _ContextAction.dictionary:
        handleDictionaryEntryAction(context, text);
        break;
      case _ContextAction.dialogue:
        handleStartDialogueAction(context, text);
        break;
      case _ContextAction.dailyMemo:
        handleDailyMemoAction(context, text);
        break;
    }
  }
}
