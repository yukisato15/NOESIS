class ConceptExtraction {
  final String concept;
  final String definition;
  final String relation;

  ConceptExtraction({
    required this.concept,
    required this.definition,
    required this.relation,
  });

  factory ConceptExtraction.fromJson(Map<String, dynamic> json) {
    return ConceptExtraction(
      concept: json['concept'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'concept': concept,
        'definition': definition,
        'relation': relation,
      };

  static Map<String, dynamic> get listJsonSchema => {
        'name': 'concept_extraction',
        'strict': true,
        'schema': {
          'type': 'object',
          'properties': {
            'concepts': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'concept': {'type': 'string'},
                  'definition': {'type': 'string'},
                  'relation': {'type': 'string'},
                },
                'required': ['concept', 'definition', 'relation'],
                'additionalProperties': false,
              },
            },
          },
          'required': ['concepts'],
          'additionalProperties': false,
        },
      };
}
