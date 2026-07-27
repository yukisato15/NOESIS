import 'package:flutter/material.dart';

class QuizQuestion {
  final String headword;
  final String correctAnswer;
  final List<String> options;
  final int entryId;

  const QuizQuestion({
    required this.headword,
    required this.correctAnswer,
    required this.options,
    required this.entryId,
  });
}

class QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _showResult = false;

  QuizQuestion get _current => widget.questions[_index];

  void _selectAnswer(String answer) {
    if (_selected != null) {
      return;
    }
    setState(() {
      _selected = answer;
      _showResult = true;
      if (answer == _current.correctAnswer) {
        _score += 1;
      }
    });
  }

  void _next() {
    if (_index + 1 >= widget.questions.length) {
      _showSummary();
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
      _showResult = false;
    });
  }

  void _showSummary() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('結果'),
          content: Text('${widget.questions.length}問中$_score問正解'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('終了'),
            ),
          ],
        );
      },
    );
  }

  Color _optionColor(String option, ThemeData theme) {
    if (!_showResult) {
      return theme.colorScheme.surface;
    }
    if (option == _current.correctAnswer) {
      return theme.colorScheme.primaryContainer;
    }
    if (option == _selected) {
      return theme.colorScheme.errorContainer;
    }
    return theme.colorScheme.surface;
  }

  IconData? _optionIcon(String option) {
    if (!_showResult) {
      return null;
    }
    if (option == _current.correctAnswer) {
      return Icons.check_circle;
    }
    if (option == _selected) {
      return Icons.cancel;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '問題 ${_index + 1} / ${widget.questions.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _current.headword,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '正しい説明を選んでください',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _current.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = _current.options[index];
                  final icon = _optionIcon(option);
                  return Material(
                    color: _optionColor(option, theme),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectAnswer(option),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                option,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _showResult ? _next : null,
                child: Text(
                  _index + 1 >= widget.questions.length ? '結果を見る' : '次へ',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
