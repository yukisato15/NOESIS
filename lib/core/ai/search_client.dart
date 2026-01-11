import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchResult {
  final String title;
  final String snippet;
  final String url;

  SearchResult({
    required this.title,
    required this.snippet,
    required this.url,
  });
}

class SearchClient {
  static final SearchClient instance = SearchClient._();
  SearchClient._();

  // Google Custom Search API の設定
  String? get _googleApiKey => dotenv.env['GOOGLE_API_KEY'];
  String? get _googleSearchEngineId => dotenv.env['GOOGLE_SEARCH_ENGINE_ID'];

  // Tavily API の設定
  String? get _tavilyApiKey => dotenv.env['TAVILY_API_KEY'];

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

  /// Web検索を実行（Google API優先、超過時はTavily自動切り替え）
  Future<List<SearchResult>> search(String query, {int maxResults = 5}) async {
    // Google APIが使用可能か確認
    final remaining = await getRemainingGoogleSearches();

    if (remaining > 0 && _googleApiKey != null && _googleSearchEngineId != null) {
      try {
        final results = await _searchWithGoogle(query, maxResults: maxResults);
        await _incrementGoogleUsage();
        return results;
      } catch (e) {
        print('Google Search failed, falling back to Tavily: $e');
        // Google失敗時はTavilyにフォールバック
        return await _searchWithTavily(query, maxResults: maxResults);
      }
    } else {
      // Google使用回数超過、またはAPI未設定の場合はTavilyを使用
      return await _searchWithTavily(query, maxResults: maxResults);
    }
  }

  /// Google Custom Search API で検索
  Future<List<SearchResult>> _searchWithGoogle(String query, {int maxResults = 5}) async {
    final url = Uri.parse(
      'https://www.googleapis.com/customsearch/v1'
      '?key=$_googleApiKey'
      '&cx=$_googleSearchEngineId'
      '&q=${Uri.encodeComponent(query)}'
      '&num=$maxResults'
      '&lr=lang_ja', // 日本語優先
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Google Search API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final items = data['items'] as List<dynamic>? ?? [];

    return items.map((item) {
      return SearchResult(
        title: item['title'] ?? '',
        snippet: item['snippet'] ?? '',
        url: item['link'] ?? '',
      );
    }).toList();
  }

  /// Tavily Search API で検索
  Future<List<SearchResult>> _searchWithTavily(String query, {int maxResults = 5}) async {
    if (_tavilyApiKey == null) {
      throw Exception('Tavily API key not configured');
    }

    final url = Uri.parse('https://api.tavily.com/search');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'api_key': _tavilyApiKey,
        'query': query,
        'max_results': maxResults,
        'search_depth': 'basic',
        'include_answer': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Tavily Search API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List<dynamic>? ?? [];

    return results.map((item) {
      return SearchResult(
        title: item['title'] ?? '',
        snippet: item['content'] ?? '',
        url: item['url'] ?? '',
      );
    }).toList();
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
}
