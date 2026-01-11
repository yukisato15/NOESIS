class DictionaryDraft {
  final List<String> genreCandidates;
  final List<String> tagCandidates;
  final String concepts;
  final String definition;
  final String example;
  final String synonyms;
  final String antonyms;
  final String related;
  final String referenceUrls;

  DictionaryDraft({
    required this.genreCandidates,
    required this.tagCandidates,
    required this.concepts,
    required this.definition,
    required this.example,
    required this.synonyms,
    required this.antonyms,
    required this.related,
    required this.referenceUrls,
  });

  factory DictionaryDraft.fromJson(Map<String, dynamic> json) {
    return DictionaryDraft(
      genreCandidates: (json['genre_candidates'] as List?)?.cast<String>() ?? [],
      tagCandidates: (json['tag_candidates'] as List?)?.cast<String>() ?? [],
      concepts: json['concepts'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      example: json['example'] as String? ?? '',
      synonyms: json['synonyms'] as String? ?? '',
      antonyms: json['antonyms'] as String? ?? '',
      related: json['related'] as String? ?? '',
      referenceUrls: json['reference_urls'] as String? ?? '',
    );
  }

  static Map<String, dynamic> get jsonSchema => {
        'name': 'dictionary_draft',
        'strict': true,
        'schema': {
          'type': 'object',
          'properties': {
            'genre_candidates': {
              'type': 'array',
              'items': {'type': 'string'},
              'minItems': 1,
              'maxItems': 3,
            },
            'tag_candidates': {
              'type': 'array',
              'items': {'type': 'string'},
              'minItems': 5,
              'maxItems': 10,
            },
            'concepts': {'type': 'string'},
            'definition': {'type': 'string'},
            'example': {'type': 'string'},
            'synonyms': {'type': 'string'},
            'antonyms': {'type': 'string'},
            'related': {'type': 'string'},
            'reference_urls': {'type': 'string'},
          },
          'required': [
            'genre_candidates',
            'tag_candidates',
            'concepts',
            'definition',
            'example',
            'synonyms',
            'antonyms',
            'related',
            'reference_urls',
          ],
          'additionalProperties': false,
        },
      };
}
