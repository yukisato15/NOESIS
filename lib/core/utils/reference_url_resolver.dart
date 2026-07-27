import '../ai/search_client.dart';
import '../../data/local/tables/dictionary_definitions_table.dart';

class ReferenceUrlResolver {
  ReferenceUrlResolver._();

  static final ReferenceUrlResolver instance = ReferenceUrlResolver._();

  Future<List<String>> resolve({
    required String headword,
    required DictionaryReferenceDomain domain,
  }) async {
    final trimmed = headword.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final sources = _sourcesForDomain(domain, trimmed);
    final urls = <String>[];

    for (final source in sources) {
      final url = await _searchFirstUrl(source.query);
      if (url == null) {
        continue;
      }
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }

    if (urls.isEmpty) {
      urls.add(_wikipediaUrl(trimmed));
    }

    return urls;
  }

  List<_ReferenceSource> _sourcesForDomain(
    DictionaryReferenceDomain domain,
    String headword,
  ) {
    switch (domain) {
      case DictionaryReferenceDomain.technology:
        return [
          _ReferenceSource('わわわIT用語辞典', '$headword わわわIT用語辞典'),
          _ReferenceSource('Wikipedia', 'site:wikipedia.org $headword'),
        ];
      case DictionaryReferenceDomain.english:
        return [
          _ReferenceSource('Weblio英和和英', 'site:weblio.jp $headword'),
          _ReferenceSource('Wikipedia', 'site:wikipedia.org $headword'),
        ];
      case DictionaryReferenceDomain.general:
        return [
          _ReferenceSource('Weblio国語', 'site:weblio.jp $headword'),
          _ReferenceSource('Wikipedia', 'site:wikipedia.org $headword'),
        ];
    }
  }

  String _wikipediaUrl(String headword) {
    final encoded = Uri.encodeComponent(headword);
    return 'https://ja.wikipedia.org/wiki/$encoded';
  }

  Future<String?> _searchFirstUrl(String query) async {
    try {
      final results = await SearchClient.instance.search(
        query,
        maxResults: 3,
      );
      for (final result in results) {
        final url = result.url.trim();
        if (url.startsWith('http')) {
          return url;
        }
      }
    } catch (_) {}
    return null;
  }
}

class _ReferenceSource {
  final String label;
  final String query;

  const _ReferenceSource(this.label, this.query);
}
