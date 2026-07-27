import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class QuestionItem {
  final String category;
  final String attribute;
  final String questionType;
  final String questionText;
  final String purpose;

  const QuestionItem({
    required this.category,
    required this.attribute,
    required this.questionType,
    required this.questionText,
    required this.purpose,
  });
}

class QuestionRepository {
  QuestionRepository._();

  static final QuestionRepository instance = QuestionRepository._();
  static const _assetPath = 'assets/data/noesis_questions_core_db.csv';

  Map<String, List<QuestionItem>>? _cachedByAttribute;
  Future<void>? _loadFuture;

  Future<List<QuestionItem>> getQuestionsForAttribute(String attribute) async {
    await _ensureLoaded();
    final items = _cachedByAttribute?[attribute] ?? const <QuestionItem>[];
    return List<QuestionItem>.from(items);
  }

  Future<void> _ensureLoaded() async {
    if (_cachedByAttribute != null) {
      return;
    }
    _loadFuture ??= _load();
    await _loadFuture;
  }

  Future<void> _load() async {
    final csvText = await rootBundle.loadString(_assetPath);
    final rows = const LineSplitter()
        .convert(csvText)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (rows.isEmpty) {
      _cachedByAttribute = <String, List<QuestionItem>>{};
      return;
    }

    final header = _parseCsvLine(rows.first);
    final columnIndex = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      columnIndex[header[i]] = i;
    }

    String valueAt(List<String> values, String key) {
      final index = columnIndex[key];
      if (index == null || index >= values.length) {
        return '';
      }
      return values[index];
    }

    final grouped = <String, List<QuestionItem>>{};
    for (final line in rows.skip(1)) {
      final values = _parseCsvLine(line);
      final item = QuestionItem(
        category: valueAt(values, 'category'),
        attribute: valueAt(values, 'attribute'),
        questionType: valueAt(values, 'question_type'),
        questionText: valueAt(values, 'question_text'),
        purpose: valueAt(values, 'purpose'),
      );
      if (item.attribute.isEmpty || item.questionText.isEmpty) {
        continue;
      }
      grouped.putIfAbsent(item.attribute, () => <QuestionItem>[]).add(item);
    }

    const questionOrder = <String, int>{
      'DIRECT': 0,
      'INDIRECT': 1,
      'ASSUMPTION': 2,
      'COMPARISON': 3,
      'PAST': 4,
      'SITUATIONAL': 5,
      'OBSERVATION': 6,
      'HYPOTHETICAL': 7,
    };
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final typeCompare = (questionOrder[a.questionType] ?? 999).compareTo(
          questionOrder[b.questionType] ?? 999,
        );
        if (typeCompare != 0) {
          return typeCompare;
        }
        return a.questionText.compareTo(b.questionText);
      });
    }

    _cachedByAttribute = grouped;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (inQuotes && nextIsQuote) {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
        continue;
      }
      current.write(char);
    }
    result.add(current.toString());
    return result;
  }
}
