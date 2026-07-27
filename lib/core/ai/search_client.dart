import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchResult {
  final String title;
  final String snippet;
  final String url;

  SearchResult({required this.title, required this.snippet, required this.url});
}

class SearchClient {
  static SearchClient? _instance;
  final String? _baseUrl;
  final String? _googleApiKey;
  final String? _googleSearchEngineId;

  SearchClient._({
    String? baseUrl,
    String? googleApiKey,
    String? googleSearchEngineId,
  }) : _baseUrl = baseUrl?.trim().isEmpty == true ? null : baseUrl?.trim(),
       _googleApiKey = googleApiKey?.trim().isEmpty == true
           ? null
           : googleApiKey?.trim(),
       _googleSearchEngineId = googleSearchEngineId?.trim().isEmpty == true
           ? null
           : googleSearchEngineId?.trim();

  /// シングルトンインスタンスを取得
  static SearchClient get instance {
    if (_instance == null) {
      throw Exception(
        'SearchClient not initialized. Call SearchClient.initialize() first.',
      );
    }
    return _instance!;
  }

  /// アプリ起動時に初期化（main.dartから呼ぶ）
  static void initialize({
    String? baseUrl,
    String? googleApiKey,
    String? googleSearchEngineId,
  }) {
    _instance = SearchClient._(
      baseUrl: baseUrl,
      googleApiKey: googleApiKey,
      googleSearchEngineId: googleSearchEngineId,
    );
  }

  /// 初期化済みかどうか
  static bool get isInitialized => _instance != null;

  /// Web検索が利用可能かどうか
  static bool get canUseWebSearch =>
      _instance != null && _instance!.isAvailable;

  bool get _hasProxy => _baseUrl != null && _baseUrl.isNotEmpty;
  bool get _hasDirectGoogle =>
      _googleApiKey != null &&
      _googleApiKey.isNotEmpty &&
      _googleSearchEngineId != null &&
      _googleSearchEngineId.isNotEmpty;

  /// 検索プロキシまたは直接Google検索が利用可能かどうか
  bool get isAvailable => _hasProxy || _hasDirectGoogle;

  // 1日の使用回数を追跡
  static const String _googleUsageKey = 'google_search_usage';
  static const String _googleUsageDateKey = 'google_search_usage_date';
  static const int maxGoogleSearchesPerDay = 100;

  /// 今日のGoogle検索使用回数を取得
  Future<int> getGoogleUsageToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_googleUsageDateKey);

    // 日付が変わっていたらリセット
    if (savedDate != today) {
      await prefs.setInt(_googleUsageKey, 0);
      await prefs.setString(_googleUsageDateKey, today);
      return 0;
    }

    return prefs.getInt(_googleUsageKey) ?? 0;
  }

  /// Google検索使用回数を増やす
  Future<void> _incrementGoogleUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getGoogleUsageToday();
    await prefs.setInt(_googleUsageKey, current + 1);
  }

  /// 残りのGoogle検索回数を取得
  Future<int> getRemainingGoogleSearches() async {
    final used = await getGoogleUsageToday();
    return maxGoogleSearchesPerDay - used;
  }

  /// Web検索を実行（バックエンド経由）
  Future<List<SearchResult>> search(String query, {int maxResults = 5}) async {
    if (_hasProxy) {
      final response = await _post('/api/search', {
        'query': query,
        'max_results': maxResults,
      });

      await _incrementGoogleUsage();

      final results = response['results'] as List<dynamic>? ?? [];
      return results.map((item) {
        return SearchResult(
          title: item['title'] ?? '',
          snippet: item['snippet'] ?? '',
          url: item['url'] ?? '',
        );
      }).toList();
    }

    if (_hasDirectGoogle) {
      final results = await _searchWithGoogleCustomSearch(
        query,
        maxResults: maxResults,
      );
      await _incrementGoogleUsage();
      return results;
    }

    throw Exception(
      'Web search mode is not configured. Add SEARCH_PROXY_BASE_URL or GOOGLE_API_KEY + GOOGLE_SEARCH_ENGINE_ID to .env.',
    );
  }

  /// 検索結果を文字列にフォーマット
  String formatSearchResults(List<SearchResult> results) {
    if (results.isEmpty) {
      return '検索結果が見つかりませんでした。';
    }

    final buffer = StringBuffer();
    buffer.writeln('# Web検索結果\n');

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('## ${i + 1}. ${result.title}');
      buffer.writeln('URL: ${result.url}');
      buffer.writeln(result.snippet);
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('Search proxy base URL not configured.');
    }

    final uri = Uri.parse(baseUrl).replace(path: path);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Search proxy error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<SearchResult>> _searchWithGoogleCustomSearch(
    String query, {
    int maxResults = 5,
  }) async {
    final apiKey = _googleApiKey;
    final searchEngineId = _googleSearchEngineId;
    if (apiKey == null ||
        apiKey.isEmpty ||
        searchEngineId == null ||
        searchEngineId.isEmpty) {
      throw Exception('Google Custom Search credentials are not configured.');
    }

    final num = maxResults.clamp(1, 10);
    final uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
      'key': apiKey,
      'cx': searchEngineId,
      'q': query,
      'num': '$num',
      'hl': 'ja',
      'safe': 'active',
    });

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[SearchClient] Google Custom Search error: ${response.statusCode} ${response.body}',
      );
      throw Exception('Google search error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? const [];
    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return SearchResult(
        title: (map['title'] ?? '').toString(),
        snippet: (map['snippet'] ?? '').toString(),
        url: (map['link'] ?? '').toString(),
      );
    }).toList();
  }
}
