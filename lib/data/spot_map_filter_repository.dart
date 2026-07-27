import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SpotMapFilterPreset {
  final String id;
  final String name;
  final String? keyword;
  final String? genreContains;
  final String? tagContains;
  final int? minConversationScore;
  final int? minWorkScore;

  const SpotMapFilterPreset({
    required this.id,
    required this.name,
    this.keyword,
    this.genreContains,
    this.tagContains,
    this.minConversationScore,
    this.minWorkScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'keyword': keyword,
    'genre_contains': genreContains,
    'tag_contains': tagContains,
    'min_conversation_score': minConversationScore,
    'min_work_score': minWorkScore,
  };

  factory SpotMapFilterPreset.fromJson(Map<String, dynamic> json) {
    return SpotMapFilterPreset(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      keyword: _nullable(json['keyword']),
      genreContains: _nullable(json['genre_contains']),
      tagContains: _nullable(json['tag_contains']),
      minConversationScore: _nullableInt(json['min_conversation_score']),
      minWorkScore: _nullableInt(json['min_work_score']),
    );
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class SpotMapFilterRepository {
  static const _storageKey = 'spot_map_saved_filters_v1';

  const SpotMapFilterRepository();

  Future<List<SpotMapFilterPreset>> loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) =>
                SpotMapFilterPreset.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFilter(SpotMapFilterPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadSavedFilters();
    final updated = [preset, ...current.where((item) => item.id != preset.id)];
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteFilter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadSavedFilters();
    final updated = current.where((item) => item.id != id).toList();
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }
}
