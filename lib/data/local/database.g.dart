// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EntryType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<EntryType>($EntriesTable.$convertertype);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DictionaryDomain, int> domain =
      GeneratedColumn<int>(
        'domain',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<DictionaryDomain>($EntriesTable.$converterdomain);
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unspecified'),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conceptMeta = const VerificationMeta(
    'concept',
  );
  @override
  late final GeneratedColumn<String> concept = GeneratedColumn<String>(
    'concept',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _readingSourceMeta = const VerificationMeta(
    'readingSource',
  );
  @override
  late final GeneratedColumn<String> readingSource = GeneratedColumn<String>(
    'reading_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ja'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    body,
    genre,
    domain,
    field,
    bookId,
    concept,
    reading,
    readingSource,
    language,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('concept')) {
      context.handle(
        _conceptMeta,
        concept.isAcceptableOrUnknown(data['concept']!, _conceptMeta),
      );
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    }
    if (data.containsKey('reading_source')) {
      context.handle(
        _readingSourceMeta,
        readingSource.isAcceptableOrUnknown(
          data['reading_source']!,
          _readingSourceMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $EntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      domain: $EntriesTable.$converterdomain.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}domain'],
        )!,
      ),
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      ),
      concept: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept'],
      ),
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      readingSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_source'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EntryType, int, int> $convertertype =
      const EnumIndexConverter<EntryType>(EntryType.values);
  static JsonTypeConverter2<DictionaryDomain, int, int> $converterdomain =
      const EnumIndexConverter<DictionaryDomain>(DictionaryDomain.values);
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final EntryType type;
  final String title;
  final String body;
  final String? genre;
  final DictionaryDomain domain;
  final String field;
  final int? bookId;
  final String? concept;
  final String reading;
  final String readingSource;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Entry({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.genre,
    required this.domain,
    required this.field,
    this.bookId,
    this.concept,
    required this.reading,
    required this.readingSource,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<int>($EntriesTable.$convertertype.toSql(type));
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    {
      map['domain'] = Variable<int>(
        $EntriesTable.$converterdomain.toSql(domain),
      );
    }
    map['field'] = Variable<String>(field);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<int>(bookId);
    }
    if (!nullToAbsent || concept != null) {
      map['concept'] = Variable<String>(concept);
    }
    map['reading'] = Variable<String>(reading);
    map['reading_source'] = Variable<String>(readingSource);
    map['language'] = Variable<String>(language);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      body: Value(body),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      domain: Value(domain),
      field: Value(field),
      bookId: bookId == null && nullToAbsent
          ? const Value.absent()
          : Value(bookId),
      concept: concept == null && nullToAbsent
          ? const Value.absent()
          : Value(concept),
      reading: Value(reading),
      readingSource: Value(readingSource),
      language: Value(language),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      type: $EntriesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      genre: serializer.fromJson<String?>(json['genre']),
      domain: $EntriesTable.$converterdomain.fromJson(
        serializer.fromJson<int>(json['domain']),
      ),
      field: serializer.fromJson<String>(json['field']),
      bookId: serializer.fromJson<int?>(json['bookId']),
      concept: serializer.fromJson<String?>(json['concept']),
      reading: serializer.fromJson<String>(json['reading']),
      readingSource: serializer.fromJson<String>(json['readingSource']),
      language: serializer.fromJson<String>(json['language']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<int>($EntriesTable.$convertertype.toJson(type)),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'genre': serializer.toJson<String?>(genre),
      'domain': serializer.toJson<int>(
        $EntriesTable.$converterdomain.toJson(domain),
      ),
      'field': serializer.toJson<String>(field),
      'bookId': serializer.toJson<int?>(bookId),
      'concept': serializer.toJson<String?>(concept),
      'reading': serializer.toJson<String>(reading),
      'readingSource': serializer.toJson<String>(readingSource),
      'language': serializer.toJson<String>(language),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Entry copyWith({
    int? id,
    EntryType? type,
    String? title,
    String? body,
    Value<String?> genre = const Value.absent(),
    DictionaryDomain? domain,
    String? field,
    Value<int?> bookId = const Value.absent(),
    Value<String?> concept = const Value.absent(),
    String? reading,
    String? readingSource,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Entry(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    genre: genre.present ? genre.value : this.genre,
    domain: domain ?? this.domain,
    field: field ?? this.field,
    bookId: bookId.present ? bookId.value : this.bookId,
    concept: concept.present ? concept.value : this.concept,
    reading: reading ?? this.reading,
    readingSource: readingSource ?? this.readingSource,
    language: language ?? this.language,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      genre: data.genre.present ? data.genre.value : this.genre,
      domain: data.domain.present ? data.domain.value : this.domain,
      field: data.field.present ? data.field.value : this.field,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      concept: data.concept.present ? data.concept.value : this.concept,
      reading: data.reading.present ? data.reading.value : this.reading,
      readingSource: data.readingSource.present
          ? data.readingSource.value
          : this.readingSource,
      language: data.language.present ? data.language.value : this.language,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('genre: $genre, ')
          ..write('domain: $domain, ')
          ..write('field: $field, ')
          ..write('bookId: $bookId, ')
          ..write('concept: $concept, ')
          ..write('reading: $reading, ')
          ..write('readingSource: $readingSource, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    body,
    genre,
    domain,
    field,
    bookId,
    concept,
    reading,
    readingSource,
    language,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.body == this.body &&
          other.genre == this.genre &&
          other.domain == this.domain &&
          other.field == this.field &&
          other.bookId == this.bookId &&
          other.concept == this.concept &&
          other.reading == this.reading &&
          other.readingSource == this.readingSource &&
          other.language == this.language &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<EntryType> type;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> genre;
  final Value<DictionaryDomain> domain;
  final Value<String> field;
  final Value<int?> bookId;
  final Value<String?> concept;
  final Value<String> reading;
  final Value<String> readingSource;
  final Value<String> language;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.genre = const Value.absent(),
    this.domain = const Value.absent(),
    this.field = const Value.absent(),
    this.bookId = const Value.absent(),
    this.concept = const Value.absent(),
    this.reading = const Value.absent(),
    this.readingSource = const Value.absent(),
    this.language = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required EntryType type,
    required String title,
    required String body,
    this.genre = const Value.absent(),
    this.domain = const Value.absent(),
    this.field = const Value.absent(),
    this.bookId = const Value.absent(),
    this.concept = const Value.absent(),
    this.reading = const Value.absent(),
    this.readingSource = const Value.absent(),
    this.language = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : type = Value(type),
       title = Value(title),
       body = Value(body);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<int>? type,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? genre,
    Expression<int>? domain,
    Expression<String>? field,
    Expression<int>? bookId,
    Expression<String>? concept,
    Expression<String>? reading,
    Expression<String>? readingSource,
    Expression<String>? language,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (genre != null) 'genre': genre,
      if (domain != null) 'domain': domain,
      if (field != null) 'field': field,
      if (bookId != null) 'book_id': bookId,
      if (concept != null) 'concept': concept,
      if (reading != null) 'reading': reading,
      if (readingSource != null) 'reading_source': readingSource,
      if (language != null) 'language': language,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<EntryType>? type,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? genre,
    Value<DictionaryDomain>? domain,
    Value<String>? field,
    Value<int?>? bookId,
    Value<String?>? concept,
    Value<String>? reading,
    Value<String>? readingSource,
    Value<String>? language,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      genre: genre ?? this.genre,
      domain: domain ?? this.domain,
      field: field ?? this.field,
      bookId: bookId ?? this.bookId,
      concept: concept ?? this.concept,
      reading: reading ?? this.reading,
      readingSource: readingSource ?? this.readingSource,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $EntriesTable.$convertertype.toSql(type.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (domain.present) {
      map['domain'] = Variable<int>(
        $EntriesTable.$converterdomain.toSql(domain.value),
      );
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (concept.present) {
      map['concept'] = Variable<String>(concept.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (readingSource.present) {
      map['reading_source'] = Variable<String>(readingSource.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('genre: $genre, ')
          ..write('domain: $domain, ')
          ..write('field: $field, ')
          ..write('bookId: $bookId, ')
          ..write('concept: $concept, ')
          ..write('reading: $reading, ')
          ..write('readingSource: $readingSource, ')
          ..write('language: $language, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EnglishLexiconsTable extends EnglishLexicons
    with TableInfo<$EnglishLexiconsTable, EnglishLexicon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnglishLexiconsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headwordMeta = const VerificationMeta(
    'headword',
  );
  @override
  late final GeneratedColumn<String> headword = GeneratedColumn<String>(
    'headword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipaMeta = const VerificationMeta('ipa');
  @override
  late final GeneratedColumn<String> ipa = GeneratedColumn<String>(
    'ipa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingKanaMeta = const VerificationMeta(
    'readingKana',
  );
  @override
  late final GeneratedColumn<String> readingKana = GeneratedColumn<String>(
    'reading_kana',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pronunciationNoteMeta = const VerificationMeta(
    'pronunciationNote',
  );
  @override
  late final GeneratedColumn<String> pronunciationNote =
      GeneratedColumn<String>(
        'pronunciation_note',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countabilityMeta = const VerificationMeta(
    'countability',
  );
  @override
  late final GeneratedColumn<String> countability = GeneratedColumn<String>(
    'countability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionEnMeta = const VerificationMeta(
    'definitionEn',
  );
  @override
  late final GeneratedColumn<String> definitionEn = GeneratedColumn<String>(
    'definition_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionJaMeta = const VerificationMeta(
    'definitionJa',
  );
  @override
  late final GeneratedColumn<String> definitionJa = GeneratedColumn<String>(
    'definition_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _synonymsJsonMeta = const VerificationMeta(
    'synonymsJson',
  );
  @override
  late final GeneratedColumn<String> synonymsJson = GeneratedColumn<String>(
    'synonyms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _antonymsJsonMeta = const VerificationMeta(
    'antonymsJson',
  );
  @override
  late final GeneratedColumn<String> antonymsJson = GeneratedColumn<String>(
    'antonyms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedTermsJsonMeta = const VerificationMeta(
    'relatedTermsJson',
  );
  @override
  late final GeneratedColumn<String> relatedTermsJson = GeneratedColumn<String>(
    'related_terms_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examplesJsonMeta = const VerificationMeta(
    'examplesJson',
  );
  @override
  late final GeneratedColumn<String> examplesJson = GeneratedColumn<String>(
    'examples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phrasesJsonMeta = const VerificationMeta(
    'phrasesJson',
  );
  @override
  late final GeneratedColumn<String> phrasesJson = GeneratedColumn<String>(
    'phrases_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registerMeta = const VerificationMeta(
    'register',
  );
  @override
  late final GeneratedColumn<String> register = GeneratedColumn<String>(
    'register',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etymologyMeta = const VerificationMeta(
    'etymology',
  );
  @override
  late final GeneratedColumn<String> etymology = GeneratedColumn<String>(
    'etymology',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usageNoteMeta = const VerificationMeta(
    'usageNote',
  );
  @override
  late final GeneratedColumn<String> usageNote = GeneratedColumn<String>(
    'usage_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptMemoMeta = const VerificationMeta(
    'conceptMemo',
  );
  @override
  late final GeneratedColumn<String> conceptMemo = GeneratedColumn<String>(
    'concept_memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _audioTtsTextMeta = const VerificationMeta(
    'audioTtsText',
  );
  @override
  late final GeneratedColumn<String> audioTtsText = GeneratedColumn<String>(
    'audio_tts_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _audioNoteMeta = const VerificationMeta(
    'audioNote',
  );
  @override
  late final GeneratedColumn<String> audioNote = GeneratedColumn<String>(
    'audio_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entryId,
    headword,
    language,
    ipa,
    readingKana,
    pronunciationNote,
    partOfSpeech,
    countability,
    definitionEn,
    definitionJa,
    synonymsJson,
    antonymsJson,
    relatedTermsJson,
    examplesJson,
    phrasesJson,
    register,
    etymology,
    usageNote,
    conceptMemo,
    audioTtsText,
    audioUrl,
    audioNote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'english_lexicons';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnglishLexicon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('headword')) {
      context.handle(
        _headwordMeta,
        headword.isAcceptableOrUnknown(data['headword']!, _headwordMeta),
      );
    } else if (isInserting) {
      context.missing(_headwordMeta);
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('ipa')) {
      context.handle(
        _ipaMeta,
        ipa.isAcceptableOrUnknown(data['ipa']!, _ipaMeta),
      );
    } else if (isInserting) {
      context.missing(_ipaMeta);
    }
    if (data.containsKey('reading_kana')) {
      context.handle(
        _readingKanaMeta,
        readingKana.isAcceptableOrUnknown(
          data['reading_kana']!,
          _readingKanaMeta,
        ),
      );
    }
    if (data.containsKey('pronunciation_note')) {
      context.handle(
        _pronunciationNoteMeta,
        pronunciationNote.isAcceptableOrUnknown(
          data['pronunciation_note']!,
          _pronunciationNoteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pronunciationNoteMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partOfSpeechMeta);
    }
    if (data.containsKey('countability')) {
      context.handle(
        _countabilityMeta,
        countability.isAcceptableOrUnknown(
          data['countability']!,
          _countabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countabilityMeta);
    }
    if (data.containsKey('definition_en')) {
      context.handle(
        _definitionEnMeta,
        definitionEn.isAcceptableOrUnknown(
          data['definition_en']!,
          _definitionEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionEnMeta);
    }
    if (data.containsKey('definition_ja')) {
      context.handle(
        _definitionJaMeta,
        definitionJa.isAcceptableOrUnknown(
          data['definition_ja']!,
          _definitionJaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_definitionJaMeta);
    }
    if (data.containsKey('synonyms_json')) {
      context.handle(
        _synonymsJsonMeta,
        synonymsJson.isAcceptableOrUnknown(
          data['synonyms_json']!,
          _synonymsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_synonymsJsonMeta);
    }
    if (data.containsKey('antonyms_json')) {
      context.handle(
        _antonymsJsonMeta,
        antonymsJson.isAcceptableOrUnknown(
          data['antonyms_json']!,
          _antonymsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_antonymsJsonMeta);
    }
    if (data.containsKey('related_terms_json')) {
      context.handle(
        _relatedTermsJsonMeta,
        relatedTermsJson.isAcceptableOrUnknown(
          data['related_terms_json']!,
          _relatedTermsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedTermsJsonMeta);
    }
    if (data.containsKey('examples_json')) {
      context.handle(
        _examplesJsonMeta,
        examplesJson.isAcceptableOrUnknown(
          data['examples_json']!,
          _examplesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_examplesJsonMeta);
    }
    if (data.containsKey('phrases_json')) {
      context.handle(
        _phrasesJsonMeta,
        phrasesJson.isAcceptableOrUnknown(
          data['phrases_json']!,
          _phrasesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_phrasesJsonMeta);
    }
    if (data.containsKey('register')) {
      context.handle(
        _registerMeta,
        register.isAcceptableOrUnknown(data['register']!, _registerMeta),
      );
    } else if (isInserting) {
      context.missing(_registerMeta);
    }
    if (data.containsKey('etymology')) {
      context.handle(
        _etymologyMeta,
        etymology.isAcceptableOrUnknown(data['etymology']!, _etymologyMeta),
      );
    } else if (isInserting) {
      context.missing(_etymologyMeta);
    }
    if (data.containsKey('usage_note')) {
      context.handle(
        _usageNoteMeta,
        usageNote.isAcceptableOrUnknown(data['usage_note']!, _usageNoteMeta),
      );
    } else if (isInserting) {
      context.missing(_usageNoteMeta);
    }
    if (data.containsKey('concept_memo')) {
      context.handle(
        _conceptMemoMeta,
        conceptMemo.isAcceptableOrUnknown(
          data['concept_memo']!,
          _conceptMemoMeta,
        ),
      );
    }
    if (data.containsKey('audio_tts_text')) {
      context.handle(
        _audioTtsTextMeta,
        audioTtsText.isAcceptableOrUnknown(
          data['audio_tts_text']!,
          _audioTtsTextMeta,
        ),
      );
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('audio_note')) {
      context.handle(
        _audioNoteMeta,
        audioNote.isAcceptableOrUnknown(data['audio_note']!, _audioNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId};
  @override
  EnglishLexicon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnglishLexicon(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      headword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headword'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      ipa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ipa'],
      )!,
      readingKana: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading_kana'],
      )!,
      pronunciationNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation_note'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      )!,
      countability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}countability'],
      )!,
      definitionEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_en'],
      )!,
      definitionJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition_ja'],
      )!,
      synonymsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synonyms_json'],
      )!,
      antonymsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}antonyms_json'],
      )!,
      relatedTermsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_terms_json'],
      )!,
      examplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples_json'],
      )!,
      phrasesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phrases_json'],
      )!,
      register: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}register'],
      )!,
      etymology: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etymology'],
      )!,
      usageNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage_note'],
      )!,
      conceptMemo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_memo'],
      )!,
      audioTtsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_tts_text'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      )!,
      audioNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_note'],
      )!,
    );
  }

  @override
  $EnglishLexiconsTable createAlias(String alias) {
    return $EnglishLexiconsTable(attachedDatabase, alias);
  }
}

class EnglishLexicon extends DataClass implements Insertable<EnglishLexicon> {
  final int entryId;
  final String headword;
  final String language;
  final String ipa;
  final String readingKana;
  final String pronunciationNote;
  final String partOfSpeech;
  final String countability;
  final String definitionEn;
  final String definitionJa;
  final String synonymsJson;
  final String antonymsJson;
  final String relatedTermsJson;
  final String examplesJson;
  final String phrasesJson;
  final String register;
  final String etymology;
  final String usageNote;
  final String conceptMemo;
  final String audioTtsText;
  final String audioUrl;
  final String audioNote;
  const EnglishLexicon({
    required this.entryId,
    required this.headword,
    required this.language,
    required this.ipa,
    required this.readingKana,
    required this.pronunciationNote,
    required this.partOfSpeech,
    required this.countability,
    required this.definitionEn,
    required this.definitionJa,
    required this.synonymsJson,
    required this.antonymsJson,
    required this.relatedTermsJson,
    required this.examplesJson,
    required this.phrasesJson,
    required this.register,
    required this.etymology,
    required this.usageNote,
    required this.conceptMemo,
    required this.audioTtsText,
    required this.audioUrl,
    required this.audioNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['headword'] = Variable<String>(headword);
    map['language'] = Variable<String>(language);
    map['ipa'] = Variable<String>(ipa);
    map['reading_kana'] = Variable<String>(readingKana);
    map['pronunciation_note'] = Variable<String>(pronunciationNote);
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    map['countability'] = Variable<String>(countability);
    map['definition_en'] = Variable<String>(definitionEn);
    map['definition_ja'] = Variable<String>(definitionJa);
    map['synonyms_json'] = Variable<String>(synonymsJson);
    map['antonyms_json'] = Variable<String>(antonymsJson);
    map['related_terms_json'] = Variable<String>(relatedTermsJson);
    map['examples_json'] = Variable<String>(examplesJson);
    map['phrases_json'] = Variable<String>(phrasesJson);
    map['register'] = Variable<String>(register);
    map['etymology'] = Variable<String>(etymology);
    map['usage_note'] = Variable<String>(usageNote);
    map['concept_memo'] = Variable<String>(conceptMemo);
    map['audio_tts_text'] = Variable<String>(audioTtsText);
    map['audio_url'] = Variable<String>(audioUrl);
    map['audio_note'] = Variable<String>(audioNote);
    return map;
  }

  EnglishLexiconsCompanion toCompanion(bool nullToAbsent) {
    return EnglishLexiconsCompanion(
      entryId: Value(entryId),
      headword: Value(headword),
      language: Value(language),
      ipa: Value(ipa),
      readingKana: Value(readingKana),
      pronunciationNote: Value(pronunciationNote),
      partOfSpeech: Value(partOfSpeech),
      countability: Value(countability),
      definitionEn: Value(definitionEn),
      definitionJa: Value(definitionJa),
      synonymsJson: Value(synonymsJson),
      antonymsJson: Value(antonymsJson),
      relatedTermsJson: Value(relatedTermsJson),
      examplesJson: Value(examplesJson),
      phrasesJson: Value(phrasesJson),
      register: Value(register),
      etymology: Value(etymology),
      usageNote: Value(usageNote),
      conceptMemo: Value(conceptMemo),
      audioTtsText: Value(audioTtsText),
      audioUrl: Value(audioUrl),
      audioNote: Value(audioNote),
    );
  }

  factory EnglishLexicon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnglishLexicon(
      entryId: serializer.fromJson<int>(json['entryId']),
      headword: serializer.fromJson<String>(json['headword']),
      language: serializer.fromJson<String>(json['language']),
      ipa: serializer.fromJson<String>(json['ipa']),
      readingKana: serializer.fromJson<String>(json['readingKana']),
      pronunciationNote: serializer.fromJson<String>(json['pronunciationNote']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      countability: serializer.fromJson<String>(json['countability']),
      definitionEn: serializer.fromJson<String>(json['definitionEn']),
      definitionJa: serializer.fromJson<String>(json['definitionJa']),
      synonymsJson: serializer.fromJson<String>(json['synonymsJson']),
      antonymsJson: serializer.fromJson<String>(json['antonymsJson']),
      relatedTermsJson: serializer.fromJson<String>(json['relatedTermsJson']),
      examplesJson: serializer.fromJson<String>(json['examplesJson']),
      phrasesJson: serializer.fromJson<String>(json['phrasesJson']),
      register: serializer.fromJson<String>(json['register']),
      etymology: serializer.fromJson<String>(json['etymology']),
      usageNote: serializer.fromJson<String>(json['usageNote']),
      conceptMemo: serializer.fromJson<String>(json['conceptMemo']),
      audioTtsText: serializer.fromJson<String>(json['audioTtsText']),
      audioUrl: serializer.fromJson<String>(json['audioUrl']),
      audioNote: serializer.fromJson<String>(json['audioNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'headword': serializer.toJson<String>(headword),
      'language': serializer.toJson<String>(language),
      'ipa': serializer.toJson<String>(ipa),
      'readingKana': serializer.toJson<String>(readingKana),
      'pronunciationNote': serializer.toJson<String>(pronunciationNote),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'countability': serializer.toJson<String>(countability),
      'definitionEn': serializer.toJson<String>(definitionEn),
      'definitionJa': serializer.toJson<String>(definitionJa),
      'synonymsJson': serializer.toJson<String>(synonymsJson),
      'antonymsJson': serializer.toJson<String>(antonymsJson),
      'relatedTermsJson': serializer.toJson<String>(relatedTermsJson),
      'examplesJson': serializer.toJson<String>(examplesJson),
      'phrasesJson': serializer.toJson<String>(phrasesJson),
      'register': serializer.toJson<String>(register),
      'etymology': serializer.toJson<String>(etymology),
      'usageNote': serializer.toJson<String>(usageNote),
      'conceptMemo': serializer.toJson<String>(conceptMemo),
      'audioTtsText': serializer.toJson<String>(audioTtsText),
      'audioUrl': serializer.toJson<String>(audioUrl),
      'audioNote': serializer.toJson<String>(audioNote),
    };
  }

  EnglishLexicon copyWith({
    int? entryId,
    String? headword,
    String? language,
    String? ipa,
    String? readingKana,
    String? pronunciationNote,
    String? partOfSpeech,
    String? countability,
    String? definitionEn,
    String? definitionJa,
    String? synonymsJson,
    String? antonymsJson,
    String? relatedTermsJson,
    String? examplesJson,
    String? phrasesJson,
    String? register,
    String? etymology,
    String? usageNote,
    String? conceptMemo,
    String? audioTtsText,
    String? audioUrl,
    String? audioNote,
  }) => EnglishLexicon(
    entryId: entryId ?? this.entryId,
    headword: headword ?? this.headword,
    language: language ?? this.language,
    ipa: ipa ?? this.ipa,
    readingKana: readingKana ?? this.readingKana,
    pronunciationNote: pronunciationNote ?? this.pronunciationNote,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    countability: countability ?? this.countability,
    definitionEn: definitionEn ?? this.definitionEn,
    definitionJa: definitionJa ?? this.definitionJa,
    synonymsJson: synonymsJson ?? this.synonymsJson,
    antonymsJson: antonymsJson ?? this.antonymsJson,
    relatedTermsJson: relatedTermsJson ?? this.relatedTermsJson,
    examplesJson: examplesJson ?? this.examplesJson,
    phrasesJson: phrasesJson ?? this.phrasesJson,
    register: register ?? this.register,
    etymology: etymology ?? this.etymology,
    usageNote: usageNote ?? this.usageNote,
    conceptMemo: conceptMemo ?? this.conceptMemo,
    audioTtsText: audioTtsText ?? this.audioTtsText,
    audioUrl: audioUrl ?? this.audioUrl,
    audioNote: audioNote ?? this.audioNote,
  );
  EnglishLexicon copyWithCompanion(EnglishLexiconsCompanion data) {
    return EnglishLexicon(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      headword: data.headword.present ? data.headword.value : this.headword,
      language: data.language.present ? data.language.value : this.language,
      ipa: data.ipa.present ? data.ipa.value : this.ipa,
      readingKana: data.readingKana.present
          ? data.readingKana.value
          : this.readingKana,
      pronunciationNote: data.pronunciationNote.present
          ? data.pronunciationNote.value
          : this.pronunciationNote,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      countability: data.countability.present
          ? data.countability.value
          : this.countability,
      definitionEn: data.definitionEn.present
          ? data.definitionEn.value
          : this.definitionEn,
      definitionJa: data.definitionJa.present
          ? data.definitionJa.value
          : this.definitionJa,
      synonymsJson: data.synonymsJson.present
          ? data.synonymsJson.value
          : this.synonymsJson,
      antonymsJson: data.antonymsJson.present
          ? data.antonymsJson.value
          : this.antonymsJson,
      relatedTermsJson: data.relatedTermsJson.present
          ? data.relatedTermsJson.value
          : this.relatedTermsJson,
      examplesJson: data.examplesJson.present
          ? data.examplesJson.value
          : this.examplesJson,
      phrasesJson: data.phrasesJson.present
          ? data.phrasesJson.value
          : this.phrasesJson,
      register: data.register.present ? data.register.value : this.register,
      etymology: data.etymology.present ? data.etymology.value : this.etymology,
      usageNote: data.usageNote.present ? data.usageNote.value : this.usageNote,
      conceptMemo: data.conceptMemo.present
          ? data.conceptMemo.value
          : this.conceptMemo,
      audioTtsText: data.audioTtsText.present
          ? data.audioTtsText.value
          : this.audioTtsText,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      audioNote: data.audioNote.present ? data.audioNote.value : this.audioNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnglishLexicon(')
          ..write('entryId: $entryId, ')
          ..write('headword: $headword, ')
          ..write('language: $language, ')
          ..write('ipa: $ipa, ')
          ..write('readingKana: $readingKana, ')
          ..write('pronunciationNote: $pronunciationNote, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('countability: $countability, ')
          ..write('definitionEn: $definitionEn, ')
          ..write('definitionJa: $definitionJa, ')
          ..write('synonymsJson: $synonymsJson, ')
          ..write('antonymsJson: $antonymsJson, ')
          ..write('relatedTermsJson: $relatedTermsJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('phrasesJson: $phrasesJson, ')
          ..write('register: $register, ')
          ..write('etymology: $etymology, ')
          ..write('usageNote: $usageNote, ')
          ..write('conceptMemo: $conceptMemo, ')
          ..write('audioTtsText: $audioTtsText, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('audioNote: $audioNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    entryId,
    headword,
    language,
    ipa,
    readingKana,
    pronunciationNote,
    partOfSpeech,
    countability,
    definitionEn,
    definitionJa,
    synonymsJson,
    antonymsJson,
    relatedTermsJson,
    examplesJson,
    phrasesJson,
    register,
    etymology,
    usageNote,
    conceptMemo,
    audioTtsText,
    audioUrl,
    audioNote,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnglishLexicon &&
          other.entryId == this.entryId &&
          other.headword == this.headword &&
          other.language == this.language &&
          other.ipa == this.ipa &&
          other.readingKana == this.readingKana &&
          other.pronunciationNote == this.pronunciationNote &&
          other.partOfSpeech == this.partOfSpeech &&
          other.countability == this.countability &&
          other.definitionEn == this.definitionEn &&
          other.definitionJa == this.definitionJa &&
          other.synonymsJson == this.synonymsJson &&
          other.antonymsJson == this.antonymsJson &&
          other.relatedTermsJson == this.relatedTermsJson &&
          other.examplesJson == this.examplesJson &&
          other.phrasesJson == this.phrasesJson &&
          other.register == this.register &&
          other.etymology == this.etymology &&
          other.usageNote == this.usageNote &&
          other.conceptMemo == this.conceptMemo &&
          other.audioTtsText == this.audioTtsText &&
          other.audioUrl == this.audioUrl &&
          other.audioNote == this.audioNote);
}

class EnglishLexiconsCompanion extends UpdateCompanion<EnglishLexicon> {
  final Value<int> entryId;
  final Value<String> headword;
  final Value<String> language;
  final Value<String> ipa;
  final Value<String> readingKana;
  final Value<String> pronunciationNote;
  final Value<String> partOfSpeech;
  final Value<String> countability;
  final Value<String> definitionEn;
  final Value<String> definitionJa;
  final Value<String> synonymsJson;
  final Value<String> antonymsJson;
  final Value<String> relatedTermsJson;
  final Value<String> examplesJson;
  final Value<String> phrasesJson;
  final Value<String> register;
  final Value<String> etymology;
  final Value<String> usageNote;
  final Value<String> conceptMemo;
  final Value<String> audioTtsText;
  final Value<String> audioUrl;
  final Value<String> audioNote;
  const EnglishLexiconsCompanion({
    this.entryId = const Value.absent(),
    this.headword = const Value.absent(),
    this.language = const Value.absent(),
    this.ipa = const Value.absent(),
    this.readingKana = const Value.absent(),
    this.pronunciationNote = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.countability = const Value.absent(),
    this.definitionEn = const Value.absent(),
    this.definitionJa = const Value.absent(),
    this.synonymsJson = const Value.absent(),
    this.antonymsJson = const Value.absent(),
    this.relatedTermsJson = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.phrasesJson = const Value.absent(),
    this.register = const Value.absent(),
    this.etymology = const Value.absent(),
    this.usageNote = const Value.absent(),
    this.conceptMemo = const Value.absent(),
    this.audioTtsText = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.audioNote = const Value.absent(),
  });
  EnglishLexiconsCompanion.insert({
    this.entryId = const Value.absent(),
    required String headword,
    required String language,
    required String ipa,
    this.readingKana = const Value.absent(),
    required String pronunciationNote,
    required String partOfSpeech,
    required String countability,
    required String definitionEn,
    required String definitionJa,
    required String synonymsJson,
    required String antonymsJson,
    required String relatedTermsJson,
    required String examplesJson,
    required String phrasesJson,
    required String register,
    required String etymology,
    required String usageNote,
    this.conceptMemo = const Value.absent(),
    this.audioTtsText = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.audioNote = const Value.absent(),
  }) : headword = Value(headword),
       language = Value(language),
       ipa = Value(ipa),
       pronunciationNote = Value(pronunciationNote),
       partOfSpeech = Value(partOfSpeech),
       countability = Value(countability),
       definitionEn = Value(definitionEn),
       definitionJa = Value(definitionJa),
       synonymsJson = Value(synonymsJson),
       antonymsJson = Value(antonymsJson),
       relatedTermsJson = Value(relatedTermsJson),
       examplesJson = Value(examplesJson),
       phrasesJson = Value(phrasesJson),
       register = Value(register),
       etymology = Value(etymology),
       usageNote = Value(usageNote);
  static Insertable<EnglishLexicon> custom({
    Expression<int>? entryId,
    Expression<String>? headword,
    Expression<String>? language,
    Expression<String>? ipa,
    Expression<String>? readingKana,
    Expression<String>? pronunciationNote,
    Expression<String>? partOfSpeech,
    Expression<String>? countability,
    Expression<String>? definitionEn,
    Expression<String>? definitionJa,
    Expression<String>? synonymsJson,
    Expression<String>? antonymsJson,
    Expression<String>? relatedTermsJson,
    Expression<String>? examplesJson,
    Expression<String>? phrasesJson,
    Expression<String>? register,
    Expression<String>? etymology,
    Expression<String>? usageNote,
    Expression<String>? conceptMemo,
    Expression<String>? audioTtsText,
    Expression<String>? audioUrl,
    Expression<String>? audioNote,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (headword != null) 'headword': headword,
      if (language != null) 'language': language,
      if (ipa != null) 'ipa': ipa,
      if (readingKana != null) 'reading_kana': readingKana,
      if (pronunciationNote != null) 'pronunciation_note': pronunciationNote,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (countability != null) 'countability': countability,
      if (definitionEn != null) 'definition_en': definitionEn,
      if (definitionJa != null) 'definition_ja': definitionJa,
      if (synonymsJson != null) 'synonyms_json': synonymsJson,
      if (antonymsJson != null) 'antonyms_json': antonymsJson,
      if (relatedTermsJson != null) 'related_terms_json': relatedTermsJson,
      if (examplesJson != null) 'examples_json': examplesJson,
      if (phrasesJson != null) 'phrases_json': phrasesJson,
      if (register != null) 'register': register,
      if (etymology != null) 'etymology': etymology,
      if (usageNote != null) 'usage_note': usageNote,
      if (conceptMemo != null) 'concept_memo': conceptMemo,
      if (audioTtsText != null) 'audio_tts_text': audioTtsText,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (audioNote != null) 'audio_note': audioNote,
    });
  }

  EnglishLexiconsCompanion copyWith({
    Value<int>? entryId,
    Value<String>? headword,
    Value<String>? language,
    Value<String>? ipa,
    Value<String>? readingKana,
    Value<String>? pronunciationNote,
    Value<String>? partOfSpeech,
    Value<String>? countability,
    Value<String>? definitionEn,
    Value<String>? definitionJa,
    Value<String>? synonymsJson,
    Value<String>? antonymsJson,
    Value<String>? relatedTermsJson,
    Value<String>? examplesJson,
    Value<String>? phrasesJson,
    Value<String>? register,
    Value<String>? etymology,
    Value<String>? usageNote,
    Value<String>? conceptMemo,
    Value<String>? audioTtsText,
    Value<String>? audioUrl,
    Value<String>? audioNote,
  }) {
    return EnglishLexiconsCompanion(
      entryId: entryId ?? this.entryId,
      headword: headword ?? this.headword,
      language: language ?? this.language,
      ipa: ipa ?? this.ipa,
      readingKana: readingKana ?? this.readingKana,
      pronunciationNote: pronunciationNote ?? this.pronunciationNote,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      countability: countability ?? this.countability,
      definitionEn: definitionEn ?? this.definitionEn,
      definitionJa: definitionJa ?? this.definitionJa,
      synonymsJson: synonymsJson ?? this.synonymsJson,
      antonymsJson: antonymsJson ?? this.antonymsJson,
      relatedTermsJson: relatedTermsJson ?? this.relatedTermsJson,
      examplesJson: examplesJson ?? this.examplesJson,
      phrasesJson: phrasesJson ?? this.phrasesJson,
      register: register ?? this.register,
      etymology: etymology ?? this.etymology,
      usageNote: usageNote ?? this.usageNote,
      conceptMemo: conceptMemo ?? this.conceptMemo,
      audioTtsText: audioTtsText ?? this.audioTtsText,
      audioUrl: audioUrl ?? this.audioUrl,
      audioNote: audioNote ?? this.audioNote,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (headword.present) {
      map['headword'] = Variable<String>(headword.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (ipa.present) {
      map['ipa'] = Variable<String>(ipa.value);
    }
    if (readingKana.present) {
      map['reading_kana'] = Variable<String>(readingKana.value);
    }
    if (pronunciationNote.present) {
      map['pronunciation_note'] = Variable<String>(pronunciationNote.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (countability.present) {
      map['countability'] = Variable<String>(countability.value);
    }
    if (definitionEn.present) {
      map['definition_en'] = Variable<String>(definitionEn.value);
    }
    if (definitionJa.present) {
      map['definition_ja'] = Variable<String>(definitionJa.value);
    }
    if (synonymsJson.present) {
      map['synonyms_json'] = Variable<String>(synonymsJson.value);
    }
    if (antonymsJson.present) {
      map['antonyms_json'] = Variable<String>(antonymsJson.value);
    }
    if (relatedTermsJson.present) {
      map['related_terms_json'] = Variable<String>(relatedTermsJson.value);
    }
    if (examplesJson.present) {
      map['examples_json'] = Variable<String>(examplesJson.value);
    }
    if (phrasesJson.present) {
      map['phrases_json'] = Variable<String>(phrasesJson.value);
    }
    if (register.present) {
      map['register'] = Variable<String>(register.value);
    }
    if (etymology.present) {
      map['etymology'] = Variable<String>(etymology.value);
    }
    if (usageNote.present) {
      map['usage_note'] = Variable<String>(usageNote.value);
    }
    if (conceptMemo.present) {
      map['concept_memo'] = Variable<String>(conceptMemo.value);
    }
    if (audioTtsText.present) {
      map['audio_tts_text'] = Variable<String>(audioTtsText.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (audioNote.present) {
      map['audio_note'] = Variable<String>(audioNote.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnglishLexiconsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('headword: $headword, ')
          ..write('language: $language, ')
          ..write('ipa: $ipa, ')
          ..write('readingKana: $readingKana, ')
          ..write('pronunciationNote: $pronunciationNote, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('countability: $countability, ')
          ..write('definitionEn: $definitionEn, ')
          ..write('definitionJa: $definitionJa, ')
          ..write('synonymsJson: $synonymsJson, ')
          ..write('antonymsJson: $antonymsJson, ')
          ..write('relatedTermsJson: $relatedTermsJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('phrasesJson: $phrasesJson, ')
          ..write('register: $register, ')
          ..write('etymology: $etymology, ')
          ..write('usageNote: $usageNote, ')
          ..write('conceptMemo: $conceptMemo, ')
          ..write('audioTtsText: $audioTtsText, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('audioNote: $audioNote')
          ..write(')'))
        .toString();
  }
}

class $EntryAppendicesTable extends EntryAppendices
    with TableInfo<$EntryAppendicesTable, EntryAppendix> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryAppendicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AppendixType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AppendixType>($EntryAppendicesTable.$convertertype);
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, type, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_appendices';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryAppendix> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryAppendix map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryAppendix(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      type: $EntryAppendicesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EntryAppendicesTable createAlias(String alias) {
    return $EntryAppendicesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AppendixType, int, int> $convertertype =
      const EnumIndexConverter<AppendixType>(AppendixType.values);
}

class EntryAppendix extends DataClass implements Insertable<EntryAppendix> {
  final int id;
  final int entryId;
  final AppendixType type;
  final String content;
  final DateTime createdAt;
  const EntryAppendix({
    required this.id,
    required this.entryId,
    required this.type,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    {
      map['type'] = Variable<int>(
        $EntryAppendicesTable.$convertertype.toSql(type),
      );
    }
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EntryAppendicesCompanion toCompanion(bool nullToAbsent) {
    return EntryAppendicesCompanion(
      id: Value(id),
      entryId: Value(entryId),
      type: Value(type),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory EntryAppendix.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryAppendix(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      type: $EntryAppendicesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'type': serializer.toJson<int>(
        $EntryAppendicesTable.$convertertype.toJson(type),
      ),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EntryAppendix copyWith({
    int? id,
    int? entryId,
    AppendixType? type,
    String? content,
    DateTime? createdAt,
  }) => EntryAppendix(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    type: type ?? this.type,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  EntryAppendix copyWithCompanion(EntryAppendicesCompanion data) {
    return EntryAppendix(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      type: data.type.present ? data.type.value : this.type,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryAppendix(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, type, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryAppendix &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.type == this.type &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class EntryAppendicesCompanion extends UpdateCompanion<EntryAppendix> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<AppendixType> type;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const EntryAppendicesCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.type = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EntryAppendicesCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required AppendixType type,
    required String content,
    this.createdAt = const Value.absent(),
  }) : entryId = Value(entryId),
       type = Value(type),
       content = Value(content);
  static Insertable<EntryAppendix> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<int>? type,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EntryAppendicesCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<AppendixType>? type,
    Value<String>? content,
    Value<DateTime>? createdAt,
  }) {
    return EntryAppendicesCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $EntryAppendicesTable.$convertertype.toSql(type.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryAppendicesCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('type: $type, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedDateMeta = const VerificationMeta(
    'publishedDate',
  );
  @override
  late final GeneratedColumn<String> publishedDate = GeneratedColumn<String>(
    'published_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _synopsisMeta = const VerificationMeta(
    'synopsis',
  );
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
    'synopsis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedUrlMeta = const VerificationMeta(
    'relatedUrl',
  );
  @override
  late final GeneratedColumn<String> relatedUrl = GeneratedColumn<String>(
    'related_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewSummaryMeta = const VerificationMeta(
    'reviewSummary',
  );
  @override
  late final GeneratedColumn<String> reviewSummary = GeneratedColumn<String>(
    'review_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    author,
    genre,
    publisher,
    publishedDate,
    isbn,
    synopsis,
    rating,
    relatedUrl,
    reviewSummary,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('published_date')) {
      context.handle(
        _publishedDateMeta,
        publishedDate.isAcceptableOrUnknown(
          data['published_date']!,
          _publishedDateMeta,
        ),
      );
    }
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    }
    if (data.containsKey('synopsis')) {
      context.handle(
        _synopsisMeta,
        synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('related_url')) {
      context.handle(
        _relatedUrlMeta,
        relatedUrl.isAcceptableOrUnknown(data['related_url']!, _relatedUrlMeta),
      );
    }
    if (data.containsKey('review_summary')) {
      context.handle(
        _reviewSummaryMeta,
        reviewSummary.isAcceptableOrUnknown(
          data['review_summary']!,
          _reviewSummaryMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      publishedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_date'],
      ),
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      ),
      synopsis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synopsis'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      relatedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_url'],
      ),
      reviewSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_summary'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final int id;

  /// 書名
  final String title;

  /// 著者名
  final String author;

  /// ジャンル（手入力またはAI補完）
  final String? genre;

  /// 出版社（AI補完）
  final String? publisher;

  /// 出版年月日（AI補完）
  final String? publishedDate;

  /// ISBN（AI補完）
  final String? isbn;

  /// あらすじ概要（AI補完）
  final String? synopsis;

  /// 評価（★や短文、AI補完）
  final String? rating;

  /// 関連URL（AI補完）
  final String? relatedUrl;

  /// 一般的なレビュー要約（AI補完）
  final String? reviewSummary;

  /// 登録日時（＝読み始めた日時）
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.genre,
    this.publisher,
    this.publishedDate,
    this.isbn,
    this.synopsis,
    this.rating,
    this.relatedUrl,
    this.reviewSummary,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || publishedDate != null) {
      map['published_date'] = Variable<String>(publishedDate);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    if (!nullToAbsent || synopsis != null) {
      map['synopsis'] = Variable<String>(synopsis);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || relatedUrl != null) {
      map['related_url'] = Variable<String>(relatedUrl);
    }
    if (!nullToAbsent || reviewSummary != null) {
      map['review_summary'] = Variable<String>(reviewSummary);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author: Value(author),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      publishedDate: publishedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedDate),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      synopsis: synopsis == null && nullToAbsent
          ? const Value.absent()
          : Value(synopsis),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      relatedUrl: relatedUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedUrl),
      reviewSummary: reviewSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewSummary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      genre: serializer.fromJson<String?>(json['genre']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      publishedDate: serializer.fromJson<String?>(json['publishedDate']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      synopsis: serializer.fromJson<String?>(json['synopsis']),
      rating: serializer.fromJson<String?>(json['rating']),
      relatedUrl: serializer.fromJson<String?>(json['relatedUrl']),
      reviewSummary: serializer.fromJson<String?>(json['reviewSummary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'genre': serializer.toJson<String?>(genre),
      'publisher': serializer.toJson<String?>(publisher),
      'publishedDate': serializer.toJson<String?>(publishedDate),
      'isbn': serializer.toJson<String?>(isbn),
      'synopsis': serializer.toJson<String?>(synopsis),
      'rating': serializer.toJson<String?>(rating),
      'relatedUrl': serializer.toJson<String?>(relatedUrl),
      'reviewSummary': serializer.toJson<String?>(reviewSummary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    Value<String?> genre = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> publishedDate = const Value.absent(),
    Value<String?> isbn = const Value.absent(),
    Value<String?> synopsis = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<String?> relatedUrl = const Value.absent(),
    Value<String?> reviewSummary = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    author: author ?? this.author,
    genre: genre.present ? genre.value : this.genre,
    publisher: publisher.present ? publisher.value : this.publisher,
    publishedDate: publishedDate.present
        ? publishedDate.value
        : this.publishedDate,
    isbn: isbn.present ? isbn.value : this.isbn,
    synopsis: synopsis.present ? synopsis.value : this.synopsis,
    rating: rating.present ? rating.value : this.rating,
    relatedUrl: relatedUrl.present ? relatedUrl.value : this.relatedUrl,
    reviewSummary: reviewSummary.present
        ? reviewSummary.value
        : this.reviewSummary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      genre: data.genre.present ? data.genre.value : this.genre,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      publishedDate: data.publishedDate.present
          ? data.publishedDate.value
          : this.publishedDate,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      rating: data.rating.present ? data.rating.value : this.rating,
      relatedUrl: data.relatedUrl.present
          ? data.relatedUrl.value
          : this.relatedUrl,
      reviewSummary: data.reviewSummary.present
          ? data.reviewSummary.value
          : this.reviewSummary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('genre: $genre, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('isbn: $isbn, ')
          ..write('synopsis: $synopsis, ')
          ..write('rating: $rating, ')
          ..write('relatedUrl: $relatedUrl, ')
          ..write('reviewSummary: $reviewSummary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    genre,
    publisher,
    publishedDate,
    isbn,
    synopsis,
    rating,
    relatedUrl,
    reviewSummary,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.genre == this.genre &&
          other.publisher == this.publisher &&
          other.publishedDate == this.publishedDate &&
          other.isbn == this.isbn &&
          other.synopsis == this.synopsis &&
          other.rating == this.rating &&
          other.relatedUrl == this.relatedUrl &&
          other.reviewSummary == this.reviewSummary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> author;
  final Value<String?> genre;
  final Value<String?> publisher;
  final Value<String?> publishedDate;
  final Value<String?> isbn;
  final Value<String?> synopsis;
  final Value<String?> rating;
  final Value<String?> relatedUrl;
  final Value<String?> reviewSummary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.genre = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.isbn = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.rating = const Value.absent(),
    this.relatedUrl = const Value.absent(),
    this.reviewSummary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String author,
    this.genre = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.isbn = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.rating = const Value.absent(),
    this.relatedUrl = const Value.absent(),
    this.reviewSummary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       author = Value(author);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? genre,
    Expression<String>? publisher,
    Expression<String>? publishedDate,
    Expression<String>? isbn,
    Expression<String>? synopsis,
    Expression<String>? rating,
    Expression<String>? relatedUrl,
    Expression<String>? reviewSummary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (genre != null) 'genre': genre,
      if (publisher != null) 'publisher': publisher,
      if (publishedDate != null) 'published_date': publishedDate,
      if (isbn != null) 'isbn': isbn,
      if (synopsis != null) 'synopsis': synopsis,
      if (rating != null) 'rating': rating,
      if (relatedUrl != null) 'related_url': relatedUrl,
      if (reviewSummary != null) 'review_summary': reviewSummary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? author,
    Value<String?>? genre,
    Value<String?>? publisher,
    Value<String?>? publishedDate,
    Value<String?>? isbn,
    Value<String?>? synopsis,
    Value<String?>? rating,
    Value<String?>? relatedUrl,
    Value<String?>? reviewSummary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      isbn: isbn ?? this.isbn,
      synopsis: synopsis ?? this.synopsis,
      rating: rating ?? this.rating,
      relatedUrl: relatedUrl ?? this.relatedUrl,
      reviewSummary: reviewSummary ?? this.reviewSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (publishedDate.present) {
      map['published_date'] = Variable<String>(publishedDate.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (relatedUrl.present) {
      map['related_url'] = Variable<String>(relatedUrl.value);
    }
    if (reviewSummary.present) {
      map['review_summary'] = Variable<String>(reviewSummary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('genre: $genre, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('isbn: $isbn, ')
          ..write('synopsis: $synopsis, ')
          ..write('rating: $rating, ')
          ..write('relatedUrl: $relatedUrl, ')
          ..write('reviewSummary: $reviewSummary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingMemosTable extends ReadingMemos
    with TableInfo<$ReadingMemosTable, ReadingMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionTitleMeta = const VerificationMeta(
    'sectionTitle',
  );
  @override
  late final GeneratedColumn<String> sectionTitle = GeneratedColumn<String>(
    'section_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<String> pageNumber = GeneratedColumn<String>(
    'page_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    content,
    sectionTitle,
    pageNumber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('section_title')) {
      context.handle(
        _sectionTitleMeta,
        sectionTitle.isAcceptableOrUnknown(
          data['section_title']!,
          _sectionTitleMeta,
        ),
      );
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingMemo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      sectionTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_title'],
      ),
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_number'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ReadingMemosTable createAlias(String alias) {
    return $ReadingMemosTable(attachedDatabase, alias);
  }
}

class ReadingMemo extends DataClass implements Insertable<ReadingMemo> {
  final int id;

  /// 所属する書籍ID
  final int bookId;

  /// 本文（手入力またはLive Textでコピペ）
  final String content;

  /// 小タイトル（章名、トピック名など）
  final String? sectionTitle;

  /// ページ番号
  final String? pageNumber;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime? updatedAt;
  const ReadingMemo({
    required this.id,
    required this.bookId,
    required this.content,
    this.sectionTitle,
    this.pageNumber,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || sectionTitle != null) {
      map['section_title'] = Variable<String>(sectionTitle);
    }
    if (!nullToAbsent || pageNumber != null) {
      map['page_number'] = Variable<String>(pageNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ReadingMemosCompanion toCompanion(bool nullToAbsent) {
    return ReadingMemosCompanion(
      id: Value(id),
      bookId: Value(bookId),
      content: Value(content),
      sectionTitle: sectionTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionTitle),
      pageNumber: pageNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(pageNumber),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ReadingMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingMemo(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      content: serializer.fromJson<String>(json['content']),
      sectionTitle: serializer.fromJson<String?>(json['sectionTitle']),
      pageNumber: serializer.fromJson<String?>(json['pageNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'content': serializer.toJson<String>(content),
      'sectionTitle': serializer.toJson<String?>(sectionTitle),
      'pageNumber': serializer.toJson<String?>(pageNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ReadingMemo copyWith({
    int? id,
    int? bookId,
    String? content,
    Value<String?> sectionTitle = const Value.absent(),
    Value<String?> pageNumber = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => ReadingMemo(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    content: content ?? this.content,
    sectionTitle: sectionTitle.present ? sectionTitle.value : this.sectionTitle,
    pageNumber: pageNumber.present ? pageNumber.value : this.pageNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ReadingMemo copyWithCompanion(ReadingMemosCompanion data) {
    return ReadingMemo(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      content: data.content.present ? data.content.value : this.content,
      sectionTitle: data.sectionTitle.present
          ? data.sectionTitle.value
          : this.sectionTitle,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingMemo(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('content: $content, ')
          ..write('sectionTitle: $sectionTitle, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    content,
    sectionTitle,
    pageNumber,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingMemo &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.content == this.content &&
          other.sectionTitle == this.sectionTitle &&
          other.pageNumber == this.pageNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReadingMemosCompanion extends UpdateCompanion<ReadingMemo> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> content;
  final Value<String?> sectionTitle;
  final Value<String?> pageNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const ReadingMemosCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.content = const Value.absent(),
    this.sectionTitle = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReadingMemosCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String content,
    this.sectionTitle = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       content = Value(content);
  static Insertable<ReadingMemo> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? content,
    Expression<String>? sectionTitle,
    Expression<String>? pageNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (content != null) 'content': content,
      if (sectionTitle != null) 'section_title': sectionTitle,
      if (pageNumber != null) 'page_number': pageNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReadingMemosCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? content,
    Value<String?>? sectionTitle,
    Value<String?>? pageNumber,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return ReadingMemosCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      content: content ?? this.content,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (sectionTitle.present) {
      map['section_title'] = Variable<String>(sectionTitle.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<String>(pageNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingMemosCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('content: $content, ')
          ..write('sectionTitle: $sectionTitle, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingReflectionsTable extends ReadingReflections
    with TableInfo<$ReadingReflectionsTable, ReadingReflection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingReflectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, bookId, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_reflections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingReflection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingReflection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingReflection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadingReflectionsTable createAlias(String alias) {
    return $ReadingReflectionsTable(attachedDatabase, alias);
  }
}

class ReadingReflection extends DataClass
    implements Insertable<ReadingReflection> {
  final int id;
  final int bookId;
  final String content;
  final DateTime createdAt;
  const ReadingReflection({
    required this.id,
    required this.bookId,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReadingReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingReflectionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ReadingReflection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingReflection(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReadingReflection copyWith({
    int? id,
    int? bookId,
    String? content,
    DateTime? createdAt,
  }) => ReadingReflection(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  ReadingReflection copyWithCompanion(ReadingReflectionsCompanion data) {
    return ReadingReflection(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingReflection(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingReflection &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ReadingReflectionsCompanion extends UpdateCompanion<ReadingReflection> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const ReadingReflectionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReadingReflectionsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String content,
    this.createdAt = const Value.absent(),
  }) : bookId = Value(bookId),
       content = Value(content);
  static Insertable<ReadingReflection> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReadingReflectionsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? content,
    Value<DateTime>? createdAt,
  }) {
    return ReadingReflectionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ConceptDictionariesTable extends ConceptDictionaries
    with TableInfo<$ConceptDictionariesTable, ConceptDictionary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptDictionariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceUrlsMeta = const VerificationMeta(
    'referenceUrls',
  );
  @override
  late final GeneratedColumn<String> referenceUrls = GeneratedColumn<String>(
    'reference_urls',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _similarConceptsMeta = const VerificationMeta(
    'similarConcepts',
  );
  @override
  late final GeneratedColumn<String> similarConcepts = GeneratedColumn<String>(
    'similar_concepts',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contrastingConceptsMeta =
      const VerificationMeta('contrastingConcepts');
  @override
  late final GeneratedColumn<String> contrastingConcepts =
      GeneratedColumn<String>(
        'contrasting_concepts',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _relatedConceptsMeta = const VerificationMeta(
    'relatedConcepts',
  );
  @override
  late final GeneratedColumn<String> relatedConcepts = GeneratedColumn<String>(
    'related_concepts',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _culturalBackgroundMeta =
      const VerificationMeta('culturalBackground');
  @override
  late final GeneratedColumn<String> culturalBackground =
      GeneratedColumn<String>(
        'cultural_background',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _practicalAdviceMeta = const VerificationMeta(
    'practicalAdvice',
  );
  @override
  late final GeneratedColumn<String> practicalAdvice = GeneratedColumn<String>(
    'practical_advice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _caseStudiesMeta = const VerificationMeta(
    'caseStudies',
  );
  @override
  late final GeneratedColumn<String> caseStudies = GeneratedColumn<String>(
    'case_studies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gyaruExplanationMeta = const VerificationMeta(
    'gyaruExplanation',
  );
  @override
  late final GeneratedColumn<String> gyaruExplanation = GeneratedColumn<String>(
    'gyaru_explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _childExplanationMeta = const VerificationMeta(
    'childExplanation',
  );
  @override
  late final GeneratedColumn<String> childExplanation = GeneratedColumn<String>(
    'child_explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConceptOrigin, int> origin =
      GeneratedColumn<int>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ConceptOrigin>(
        $ConceptDictionariesTable.$converterorigin,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    category,
    tags,
    memo,
    referenceUrls,
    similarConcepts,
    contrastingConcepts,
    relatedConcepts,
    culturalBackground,
    practicalAdvice,
    caseStudies,
    gyaruExplanation,
    childExplanation,
    origin,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concept_dictionaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConceptDictionary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('reference_urls')) {
      context.handle(
        _referenceUrlsMeta,
        referenceUrls.isAcceptableOrUnknown(
          data['reference_urls']!,
          _referenceUrlsMeta,
        ),
      );
    }
    if (data.containsKey('similar_concepts')) {
      context.handle(
        _similarConceptsMeta,
        similarConcepts.isAcceptableOrUnknown(
          data['similar_concepts']!,
          _similarConceptsMeta,
        ),
      );
    }
    if (data.containsKey('contrasting_concepts')) {
      context.handle(
        _contrastingConceptsMeta,
        contrastingConcepts.isAcceptableOrUnknown(
          data['contrasting_concepts']!,
          _contrastingConceptsMeta,
        ),
      );
    }
    if (data.containsKey('related_concepts')) {
      context.handle(
        _relatedConceptsMeta,
        relatedConcepts.isAcceptableOrUnknown(
          data['related_concepts']!,
          _relatedConceptsMeta,
        ),
      );
    }
    if (data.containsKey('cultural_background')) {
      context.handle(
        _culturalBackgroundMeta,
        culturalBackground.isAcceptableOrUnknown(
          data['cultural_background']!,
          _culturalBackgroundMeta,
        ),
      );
    }
    if (data.containsKey('practical_advice')) {
      context.handle(
        _practicalAdviceMeta,
        practicalAdvice.isAcceptableOrUnknown(
          data['practical_advice']!,
          _practicalAdviceMeta,
        ),
      );
    }
    if (data.containsKey('case_studies')) {
      context.handle(
        _caseStudiesMeta,
        caseStudies.isAcceptableOrUnknown(
          data['case_studies']!,
          _caseStudiesMeta,
        ),
      );
    }
    if (data.containsKey('gyaru_explanation')) {
      context.handle(
        _gyaruExplanationMeta,
        gyaruExplanation.isAcceptableOrUnknown(
          data['gyaru_explanation']!,
          _gyaruExplanationMeta,
        ),
      );
    }
    if (data.containsKey('child_explanation')) {
      context.handle(
        _childExplanationMeta,
        childExplanation.isAcceptableOrUnknown(
          data['child_explanation']!,
          _childExplanationMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConceptDictionary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConceptDictionary(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      referenceUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_urls'],
      ),
      similarConcepts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}similar_concepts'],
      ),
      contrastingConcepts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contrasting_concepts'],
      ),
      relatedConcepts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_concepts'],
      ),
      culturalBackground: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cultural_background'],
      ),
      practicalAdvice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}practical_advice'],
      ),
      caseStudies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}case_studies'],
      ),
      gyaruExplanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gyaru_explanation'],
      ),
      childExplanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}child_explanation'],
      ),
      origin: $ConceptDictionariesTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}origin'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConceptDictionariesTable createAlias(String alias) {
    return $ConceptDictionariesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConceptOrigin, int, int> $converterorigin =
      const EnumIndexConverter<ConceptOrigin>(ConceptOrigin.values);
}

class ConceptDictionary extends DataClass
    implements Insertable<ConceptDictionary> {
  final int id;
  final String title;
  final String body;
  final String? category;
  final String? tags;
  final String? memo;
  final String? referenceUrls;
  final String? similarConcepts;
  final String? contrastingConcepts;
  final String? relatedConcepts;
  final String? culturalBackground;
  final String? practicalAdvice;
  final String? caseStudies;
  final String? gyaruExplanation;
  final String? childExplanation;
  final ConceptOrigin origin;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConceptDictionary({
    required this.id,
    required this.title,
    required this.body,
    this.category,
    this.tags,
    this.memo,
    this.referenceUrls,
    this.similarConcepts,
    this.contrastingConcepts,
    this.relatedConcepts,
    this.culturalBackground,
    this.practicalAdvice,
    this.caseStudies,
    this.gyaruExplanation,
    this.childExplanation,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || referenceUrls != null) {
      map['reference_urls'] = Variable<String>(referenceUrls);
    }
    if (!nullToAbsent || similarConcepts != null) {
      map['similar_concepts'] = Variable<String>(similarConcepts);
    }
    if (!nullToAbsent || contrastingConcepts != null) {
      map['contrasting_concepts'] = Variable<String>(contrastingConcepts);
    }
    if (!nullToAbsent || relatedConcepts != null) {
      map['related_concepts'] = Variable<String>(relatedConcepts);
    }
    if (!nullToAbsent || culturalBackground != null) {
      map['cultural_background'] = Variable<String>(culturalBackground);
    }
    if (!nullToAbsent || practicalAdvice != null) {
      map['practical_advice'] = Variable<String>(practicalAdvice);
    }
    if (!nullToAbsent || caseStudies != null) {
      map['case_studies'] = Variable<String>(caseStudies);
    }
    if (!nullToAbsent || gyaruExplanation != null) {
      map['gyaru_explanation'] = Variable<String>(gyaruExplanation);
    }
    if (!nullToAbsent || childExplanation != null) {
      map['child_explanation'] = Variable<String>(childExplanation);
    }
    {
      map['origin'] = Variable<int>(
        $ConceptDictionariesTable.$converterorigin.toSql(origin),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConceptDictionariesCompanion toCompanion(bool nullToAbsent) {
    return ConceptDictionariesCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      referenceUrls: referenceUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceUrls),
      similarConcepts: similarConcepts == null && nullToAbsent
          ? const Value.absent()
          : Value(similarConcepts),
      contrastingConcepts: contrastingConcepts == null && nullToAbsent
          ? const Value.absent()
          : Value(contrastingConcepts),
      relatedConcepts: relatedConcepts == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedConcepts),
      culturalBackground: culturalBackground == null && nullToAbsent
          ? const Value.absent()
          : Value(culturalBackground),
      practicalAdvice: practicalAdvice == null && nullToAbsent
          ? const Value.absent()
          : Value(practicalAdvice),
      caseStudies: caseStudies == null && nullToAbsent
          ? const Value.absent()
          : Value(caseStudies),
      gyaruExplanation: gyaruExplanation == null && nullToAbsent
          ? const Value.absent()
          : Value(gyaruExplanation),
      childExplanation: childExplanation == null && nullToAbsent
          ? const Value.absent()
          : Value(childExplanation),
      origin: Value(origin),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConceptDictionary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConceptDictionary(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      category: serializer.fromJson<String?>(json['category']),
      tags: serializer.fromJson<String?>(json['tags']),
      memo: serializer.fromJson<String?>(json['memo']),
      referenceUrls: serializer.fromJson<String?>(json['referenceUrls']),
      similarConcepts: serializer.fromJson<String?>(json['similarConcepts']),
      contrastingConcepts: serializer.fromJson<String?>(
        json['contrastingConcepts'],
      ),
      relatedConcepts: serializer.fromJson<String?>(json['relatedConcepts']),
      culturalBackground: serializer.fromJson<String?>(
        json['culturalBackground'],
      ),
      practicalAdvice: serializer.fromJson<String?>(json['practicalAdvice']),
      caseStudies: serializer.fromJson<String?>(json['caseStudies']),
      gyaruExplanation: serializer.fromJson<String?>(json['gyaruExplanation']),
      childExplanation: serializer.fromJson<String?>(json['childExplanation']),
      origin: $ConceptDictionariesTable.$converterorigin.fromJson(
        serializer.fromJson<int>(json['origin']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'category': serializer.toJson<String?>(category),
      'tags': serializer.toJson<String?>(tags),
      'memo': serializer.toJson<String?>(memo),
      'referenceUrls': serializer.toJson<String?>(referenceUrls),
      'similarConcepts': serializer.toJson<String?>(similarConcepts),
      'contrastingConcepts': serializer.toJson<String?>(contrastingConcepts),
      'relatedConcepts': serializer.toJson<String?>(relatedConcepts),
      'culturalBackground': serializer.toJson<String?>(culturalBackground),
      'practicalAdvice': serializer.toJson<String?>(practicalAdvice),
      'caseStudies': serializer.toJson<String?>(caseStudies),
      'gyaruExplanation': serializer.toJson<String?>(gyaruExplanation),
      'childExplanation': serializer.toJson<String?>(childExplanation),
      'origin': serializer.toJson<int>(
        $ConceptDictionariesTable.$converterorigin.toJson(origin),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConceptDictionary copyWith({
    int? id,
    String? title,
    String? body,
    Value<String?> category = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<String?> referenceUrls = const Value.absent(),
    Value<String?> similarConcepts = const Value.absent(),
    Value<String?> contrastingConcepts = const Value.absent(),
    Value<String?> relatedConcepts = const Value.absent(),
    Value<String?> culturalBackground = const Value.absent(),
    Value<String?> practicalAdvice = const Value.absent(),
    Value<String?> caseStudies = const Value.absent(),
    Value<String?> gyaruExplanation = const Value.absent(),
    Value<String?> childExplanation = const Value.absent(),
    ConceptOrigin? origin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConceptDictionary(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    category: category.present ? category.value : this.category,
    tags: tags.present ? tags.value : this.tags,
    memo: memo.present ? memo.value : this.memo,
    referenceUrls: referenceUrls.present
        ? referenceUrls.value
        : this.referenceUrls,
    similarConcepts: similarConcepts.present
        ? similarConcepts.value
        : this.similarConcepts,
    contrastingConcepts: contrastingConcepts.present
        ? contrastingConcepts.value
        : this.contrastingConcepts,
    relatedConcepts: relatedConcepts.present
        ? relatedConcepts.value
        : this.relatedConcepts,
    culturalBackground: culturalBackground.present
        ? culturalBackground.value
        : this.culturalBackground,
    practicalAdvice: practicalAdvice.present
        ? practicalAdvice.value
        : this.practicalAdvice,
    caseStudies: caseStudies.present ? caseStudies.value : this.caseStudies,
    gyaruExplanation: gyaruExplanation.present
        ? gyaruExplanation.value
        : this.gyaruExplanation,
    childExplanation: childExplanation.present
        ? childExplanation.value
        : this.childExplanation,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConceptDictionary copyWithCompanion(ConceptDictionariesCompanion data) {
    return ConceptDictionary(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      category: data.category.present ? data.category.value : this.category,
      tags: data.tags.present ? data.tags.value : this.tags,
      memo: data.memo.present ? data.memo.value : this.memo,
      referenceUrls: data.referenceUrls.present
          ? data.referenceUrls.value
          : this.referenceUrls,
      similarConcepts: data.similarConcepts.present
          ? data.similarConcepts.value
          : this.similarConcepts,
      contrastingConcepts: data.contrastingConcepts.present
          ? data.contrastingConcepts.value
          : this.contrastingConcepts,
      relatedConcepts: data.relatedConcepts.present
          ? data.relatedConcepts.value
          : this.relatedConcepts,
      culturalBackground: data.culturalBackground.present
          ? data.culturalBackground.value
          : this.culturalBackground,
      practicalAdvice: data.practicalAdvice.present
          ? data.practicalAdvice.value
          : this.practicalAdvice,
      caseStudies: data.caseStudies.present
          ? data.caseStudies.value
          : this.caseStudies,
      gyaruExplanation: data.gyaruExplanation.present
          ? data.gyaruExplanation.value
          : this.gyaruExplanation,
      childExplanation: data.childExplanation.present
          ? data.childExplanation.value
          : this.childExplanation,
      origin: data.origin.present ? data.origin.value : this.origin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConceptDictionary(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('memo: $memo, ')
          ..write('referenceUrls: $referenceUrls, ')
          ..write('similarConcepts: $similarConcepts, ')
          ..write('contrastingConcepts: $contrastingConcepts, ')
          ..write('relatedConcepts: $relatedConcepts, ')
          ..write('culturalBackground: $culturalBackground, ')
          ..write('practicalAdvice: $practicalAdvice, ')
          ..write('caseStudies: $caseStudies, ')
          ..write('gyaruExplanation: $gyaruExplanation, ')
          ..write('childExplanation: $childExplanation, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    category,
    tags,
    memo,
    referenceUrls,
    similarConcepts,
    contrastingConcepts,
    relatedConcepts,
    culturalBackground,
    practicalAdvice,
    caseStudies,
    gyaruExplanation,
    childExplanation,
    origin,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConceptDictionary &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.category == this.category &&
          other.tags == this.tags &&
          other.memo == this.memo &&
          other.referenceUrls == this.referenceUrls &&
          other.similarConcepts == this.similarConcepts &&
          other.contrastingConcepts == this.contrastingConcepts &&
          other.relatedConcepts == this.relatedConcepts &&
          other.culturalBackground == this.culturalBackground &&
          other.practicalAdvice == this.practicalAdvice &&
          other.caseStudies == this.caseStudies &&
          other.gyaruExplanation == this.gyaruExplanation &&
          other.childExplanation == this.childExplanation &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConceptDictionariesCompanion extends UpdateCompanion<ConceptDictionary> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> category;
  final Value<String?> tags;
  final Value<String?> memo;
  final Value<String?> referenceUrls;
  final Value<String?> similarConcepts;
  final Value<String?> contrastingConcepts;
  final Value<String?> relatedConcepts;
  final Value<String?> culturalBackground;
  final Value<String?> practicalAdvice;
  final Value<String?> caseStudies;
  final Value<String?> gyaruExplanation;
  final Value<String?> childExplanation;
  final Value<ConceptOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConceptDictionariesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.memo = const Value.absent(),
    this.referenceUrls = const Value.absent(),
    this.similarConcepts = const Value.absent(),
    this.contrastingConcepts = const Value.absent(),
    this.relatedConcepts = const Value.absent(),
    this.culturalBackground = const Value.absent(),
    this.practicalAdvice = const Value.absent(),
    this.caseStudies = const Value.absent(),
    this.gyaruExplanation = const Value.absent(),
    this.childExplanation = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConceptDictionariesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.memo = const Value.absent(),
    this.referenceUrls = const Value.absent(),
    this.similarConcepts = const Value.absent(),
    this.contrastingConcepts = const Value.absent(),
    this.relatedConcepts = const Value.absent(),
    this.culturalBackground = const Value.absent(),
    this.practicalAdvice = const Value.absent(),
    this.caseStudies = const Value.absent(),
    this.gyaruExplanation = const Value.absent(),
    this.childExplanation = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       body = Value(body);
  static Insertable<ConceptDictionary> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? category,
    Expression<String>? tags,
    Expression<String>? memo,
    Expression<String>? referenceUrls,
    Expression<String>? similarConcepts,
    Expression<String>? contrastingConcepts,
    Expression<String>? relatedConcepts,
    Expression<String>? culturalBackground,
    Expression<String>? practicalAdvice,
    Expression<String>? caseStudies,
    Expression<String>? gyaruExplanation,
    Expression<String>? childExplanation,
    Expression<int>? origin,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (memo != null) 'memo': memo,
      if (referenceUrls != null) 'reference_urls': referenceUrls,
      if (similarConcepts != null) 'similar_concepts': similarConcepts,
      if (contrastingConcepts != null)
        'contrasting_concepts': contrastingConcepts,
      if (relatedConcepts != null) 'related_concepts': relatedConcepts,
      if (culturalBackground != null) 'cultural_background': culturalBackground,
      if (practicalAdvice != null) 'practical_advice': practicalAdvice,
      if (caseStudies != null) 'case_studies': caseStudies,
      if (gyaruExplanation != null) 'gyaru_explanation': gyaruExplanation,
      if (childExplanation != null) 'child_explanation': childExplanation,
      if (origin != null) 'origin': origin,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConceptDictionariesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? category,
    Value<String?>? tags,
    Value<String?>? memo,
    Value<String?>? referenceUrls,
    Value<String?>? similarConcepts,
    Value<String?>? contrastingConcepts,
    Value<String?>? relatedConcepts,
    Value<String?>? culturalBackground,
    Value<String?>? practicalAdvice,
    Value<String?>? caseStudies,
    Value<String?>? gyaruExplanation,
    Value<String?>? childExplanation,
    Value<ConceptOrigin>? origin,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConceptDictionariesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      memo: memo ?? this.memo,
      referenceUrls: referenceUrls ?? this.referenceUrls,
      similarConcepts: similarConcepts ?? this.similarConcepts,
      contrastingConcepts: contrastingConcepts ?? this.contrastingConcepts,
      relatedConcepts: relatedConcepts ?? this.relatedConcepts,
      culturalBackground: culturalBackground ?? this.culturalBackground,
      practicalAdvice: practicalAdvice ?? this.practicalAdvice,
      caseStudies: caseStudies ?? this.caseStudies,
      gyaruExplanation: gyaruExplanation ?? this.gyaruExplanation,
      childExplanation: childExplanation ?? this.childExplanation,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (referenceUrls.present) {
      map['reference_urls'] = Variable<String>(referenceUrls.value);
    }
    if (similarConcepts.present) {
      map['similar_concepts'] = Variable<String>(similarConcepts.value);
    }
    if (contrastingConcepts.present) {
      map['contrasting_concepts'] = Variable<String>(contrastingConcepts.value);
    }
    if (relatedConcepts.present) {
      map['related_concepts'] = Variable<String>(relatedConcepts.value);
    }
    if (culturalBackground.present) {
      map['cultural_background'] = Variable<String>(culturalBackground.value);
    }
    if (practicalAdvice.present) {
      map['practical_advice'] = Variable<String>(practicalAdvice.value);
    }
    if (caseStudies.present) {
      map['case_studies'] = Variable<String>(caseStudies.value);
    }
    if (gyaruExplanation.present) {
      map['gyaru_explanation'] = Variable<String>(gyaruExplanation.value);
    }
    if (childExplanation.present) {
      map['child_explanation'] = Variable<String>(childExplanation.value);
    }
    if (origin.present) {
      map['origin'] = Variable<int>(
        $ConceptDictionariesTable.$converterorigin.toSql(origin.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptDictionariesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('memo: $memo, ')
          ..write('referenceUrls: $referenceUrls, ')
          ..write('similarConcepts: $similarConcepts, ')
          ..write('contrastingConcepts: $contrastingConcepts, ')
          ..write('relatedConcepts: $relatedConcepts, ')
          ..write('culturalBackground: $culturalBackground, ')
          ..write('practicalAdvice: $practicalAdvice, ')
          ..write('caseStudies: $caseStudies, ')
          ..write('gyaruExplanation: $gyaruExplanation, ')
          ..write('childExplanation: $childExplanation, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConceptMemosTable extends ConceptMemos
    with TableInfo<$ConceptMemosTable, ConceptMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConceptMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extractedJsonMeta = const VerificationMeta(
    'extractedJson',
  );
  @override
  late final GeneratedColumn<String> extractedJson = GeneratedColumn<String>(
    'extracted_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    summary,
    extractedJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'concept_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConceptMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('extracted_json')) {
      context.handle(
        _extractedJsonMeta,
        extractedJson.isAcceptableOrUnknown(
          data['extracted_json']!,
          _extractedJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConceptMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConceptMemo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      extractedJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConceptMemosTable createAlias(String alias) {
    return $ConceptMemosTable(attachedDatabase, alias);
  }
}

class ConceptMemo extends DataClass implements Insertable<ConceptMemo> {
  final int id;
  final String? title;
  final String content;
  final String? summary;
  final String extractedJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConceptMemo({
    required this.id,
    this.title,
    required this.content,
    this.summary,
    required this.extractedJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['extracted_json'] = Variable<String>(extractedJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConceptMemosCompanion toCompanion(bool nullToAbsent) {
    return ConceptMemosCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      extractedJson: Value(extractedJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConceptMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConceptMemo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      summary: serializer.fromJson<String?>(json['summary']),
      extractedJson: serializer.fromJson<String>(json['extractedJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'summary': serializer.toJson<String?>(summary),
      'extractedJson': serializer.toJson<String>(extractedJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConceptMemo copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<String?> summary = const Value.absent(),
    String? extractedJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConceptMemo(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    summary: summary.present ? summary.value : this.summary,
    extractedJson: extractedJson ?? this.extractedJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConceptMemo copyWithCompanion(ConceptMemosCompanion data) {
    return ConceptMemo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      summary: data.summary.present ? data.summary.value : this.summary,
      extractedJson: data.extractedJson.present
          ? data.extractedJson.value
          : this.extractedJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConceptMemo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('summary: $summary, ')
          ..write('extractedJson: $extractedJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    summary,
    extractedJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConceptMemo &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.summary == this.summary &&
          other.extractedJson == this.extractedJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConceptMemosCompanion extends UpdateCompanion<ConceptMemo> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<String?> summary;
  final Value<String> extractedJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ConceptMemosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.summary = const Value.absent(),
    this.extractedJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConceptMemosCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.summary = const Value.absent(),
    this.extractedJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : content = Value(content);
  static Insertable<ConceptMemo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? summary,
    Expression<String>? extractedJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (summary != null) 'summary': summary,
      if (extractedJson != null) 'extracted_json': extractedJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConceptMemosCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<String?>? summary,
    Value<String>? extractedJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ConceptMemosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      extractedJson: extractedJson ?? this.extractedJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (extractedJson.present) {
      map['extracted_json'] = Variable<String>(extractedJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConceptMemosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('summary: $summary, ')
          ..write('extractedJson: $extractedJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyMemosTable extends DailyMemos
    with TableInfo<$DailyMemosTable, DailyMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    category,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyMemo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyMemosTable createAlias(String alias) {
    return $DailyMemosTable(attachedDatabase, alias);
  }
}

class DailyMemo extends DataClass implements Insertable<DailyMemo> {
  final int id;
  final String? title;
  final String content;
  final String? category;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DailyMemo({
    required this.id,
    this.title,
    required this.content,
    this.category,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyMemosCompanion toCompanion(bool nullToAbsent) {
    return DailyMemosCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyMemo(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      category: serializer.fromJson<String?>(json['category']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'category': serializer.toJson<String?>(category),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyMemo copyWith({
    int? id,
    Value<String?> title = const Value.absent(),
    String? content,
    Value<String?> category = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DailyMemo(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    category: category.present ? category.value : this.category,
    tags: tags.present ? tags.value : this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyMemo copyWithCompanion(DailyMemosCompanion data) {
    return DailyMemo(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      category: data.category.present ? data.category.value : this.category,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyMemo(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, category, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyMemo &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.category == this.category &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DailyMemosCompanion extends UpdateCompanion<DailyMemo> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<String?> category;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DailyMemosCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyMemosCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required String content,
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : content = Value(content);
  static Insertable<DailyMemo> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? category,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyMemosCompanion copyWith({
    Value<int>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<String?>? category,
    Value<String?>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DailyMemosCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyMemosCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DictionaryDefinitionsTable extends DictionaryDefinitions
    with TableInfo<$DictionaryDefinitionsTable, DictionaryDefinition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isWorkMeta = const VerificationMeta('isWork');
  @override
  late final GeneratedColumn<bool> isWork = GeneratedColumn<bool>(
    'is_work',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_work" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedTagsMeta = const VerificationMeta(
    'recommendedTags',
  );
  @override
  late final GeneratedColumn<String> recommendedTags = GeneratedColumn<String>(
    'recommended_tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedCategoriesMeta =
      const VerificationMeta('recommendedCategories');
  @override
  late final GeneratedColumn<String> recommendedCategories =
      GeneratedColumn<String>(
        'recommended_categories',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    isSystem,
    isWork,
    category,
    recommendedTags,
    recommendedCategories,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryDefinition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('is_work')) {
      context.handle(
        _isWorkMeta,
        isWork.isAcceptableOrUnknown(data['is_work']!, _isWorkMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('recommended_tags')) {
      context.handle(
        _recommendedTagsMeta,
        recommendedTags.isAcceptableOrUnknown(
          data['recommended_tags']!,
          _recommendedTagsMeta,
        ),
      );
    }
    if (data.containsKey('recommended_categories')) {
      context.handle(
        _recommendedCategoriesMeta,
        recommendedCategories.isAcceptableOrUnknown(
          data['recommended_categories']!,
          _recommendedCategoriesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryDefinition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryDefinition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      isWork: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_work'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      recommendedTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_tags'],
      ),
      recommendedCategories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_categories'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DictionaryDefinitionsTable createAlias(String alias) {
    return $DictionaryDefinitionsTable(attachedDatabase, alias);
  }
}

class DictionaryDefinition extends DataClass
    implements Insertable<DictionaryDefinition> {
  final int id;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isWork;
  final String? category;
  final String? recommendedTags;
  final String? recommendedCategories;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DictionaryDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    required this.isWork,
    this.category,
    this.recommendedTags,
    this.recommendedCategories,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['is_work'] = Variable<bool>(isWork);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || recommendedTags != null) {
      map['recommended_tags'] = Variable<String>(recommendedTags);
    }
    if (!nullToAbsent || recommendedCategories != null) {
      map['recommended_categories'] = Variable<String>(recommendedCategories);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DictionaryDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return DictionaryDefinitionsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isSystem: Value(isSystem),
      isWork: Value(isWork),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      recommendedTags: recommendedTags == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedTags),
      recommendedCategories: recommendedCategories == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedCategories),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DictionaryDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryDefinition(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      isWork: serializer.fromJson<bool>(json['isWork']),
      category: serializer.fromJson<String?>(json['category']),
      recommendedTags: serializer.fromJson<String?>(json['recommendedTags']),
      recommendedCategories: serializer.fromJson<String?>(
        json['recommendedCategories'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isSystem': serializer.toJson<bool>(isSystem),
      'isWork': serializer.toJson<bool>(isWork),
      'category': serializer.toJson<String?>(category),
      'recommendedTags': serializer.toJson<String?>(recommendedTags),
      'recommendedCategories': serializer.toJson<String?>(
        recommendedCategories,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DictionaryDefinition copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isSystem,
    bool? isWork,
    Value<String?> category = const Value.absent(),
    Value<String?> recommendedTags = const Value.absent(),
    Value<String?> recommendedCategories = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DictionaryDefinition(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isSystem: isSystem ?? this.isSystem,
    isWork: isWork ?? this.isWork,
    category: category.present ? category.value : this.category,
    recommendedTags: recommendedTags.present
        ? recommendedTags.value
        : this.recommendedTags,
    recommendedCategories: recommendedCategories.present
        ? recommendedCategories.value
        : this.recommendedCategories,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DictionaryDefinition copyWithCompanion(DictionaryDefinitionsCompanion data) {
    return DictionaryDefinition(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      isWork: data.isWork.present ? data.isWork.value : this.isWork,
      category: data.category.present ? data.category.value : this.category,
      recommendedTags: data.recommendedTags.present
          ? data.recommendedTags.value
          : this.recommendedTags,
      recommendedCategories: data.recommendedCategories.present
          ? data.recommendedCategories.value
          : this.recommendedCategories,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryDefinition(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('isWork: $isWork, ')
          ..write('category: $category, ')
          ..write('recommendedTags: $recommendedTags, ')
          ..write('recommendedCategories: $recommendedCategories, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    isSystem,
    isWork,
    category,
    recommendedTags,
    recommendedCategories,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryDefinition &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isSystem == this.isSystem &&
          other.isWork == this.isWork &&
          other.category == this.category &&
          other.recommendedTags == this.recommendedTags &&
          other.recommendedCategories == this.recommendedCategories &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DictionaryDefinitionsCompanion
    extends UpdateCompanion<DictionaryDefinition> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isSystem;
  final Value<bool> isWork;
  final Value<String?> category;
  final Value<String?> recommendedTags;
  final Value<String?> recommendedCategories;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DictionaryDefinitionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isWork = const Value.absent(),
    this.category = const Value.absent(),
    this.recommendedTags = const Value.absent(),
    this.recommendedCategories = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DictionaryDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isWork = const Value.absent(),
    this.category = const Value.absent(),
    this.recommendedTags = const Value.absent(),
    this.recommendedCategories = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<DictionaryDefinition> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isSystem,
    Expression<bool>? isWork,
    Expression<String>? category,
    Expression<String>? recommendedTags,
    Expression<String>? recommendedCategories,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isSystem != null) 'is_system': isSystem,
      if (isWork != null) 'is_work': isWork,
      if (category != null) 'category': category,
      if (recommendedTags != null) 'recommended_tags': recommendedTags,
      if (recommendedCategories != null)
        'recommended_categories': recommendedCategories,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DictionaryDefinitionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isSystem,
    Value<bool>? isWork,
    Value<String?>? category,
    Value<String?>? recommendedTags,
    Value<String?>? recommendedCategories,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DictionaryDefinitionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isWork: isWork ?? this.isWork,
      category: category ?? this.category,
      recommendedTags: recommendedTags ?? this.recommendedTags,
      recommendedCategories:
          recommendedCategories ?? this.recommendedCategories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (isWork.present) {
      map['is_work'] = Variable<bool>(isWork.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (recommendedTags.present) {
      map['recommended_tags'] = Variable<String>(recommendedTags.value);
    }
    if (recommendedCategories.present) {
      map['recommended_categories'] = Variable<String>(
        recommendedCategories.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('isWork: $isWork, ')
          ..write('category: $category, ')
          ..write('recommendedTags: $recommendedTags, ')
          ..write('recommendedCategories: $recommendedCategories, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DictionaryFieldsTable extends DictionaryFields
    with TableInfo<$DictionaryFieldsTable, DictionaryField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DictionaryFieldType, int>
  fieldType =
      GeneratedColumn<int>(
        'field_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DictionaryFieldType>(
        $DictionaryFieldsTable.$converterfieldType,
      );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'is_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    fieldKey,
    label,
    fieldType,
    isRequired,
    isEnabled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('is_required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['is_required']!, _isRequiredMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      fieldType: $DictionaryFieldsTable.$converterfieldType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}field_type'],
        )!,
      ),
      isRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DictionaryFieldsTable createAlias(String alias) {
    return $DictionaryFieldsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DictionaryFieldType, int, int> $converterfieldType =
      const EnumIndexConverter<DictionaryFieldType>(DictionaryFieldType.values);
}

class DictionaryField extends DataClass implements Insertable<DictionaryField> {
  final int id;
  final int dictionaryId;
  final String fieldKey;
  final String label;
  final DictionaryFieldType fieldType;
  final bool isRequired;
  final bool isEnabled;
  final int sortOrder;
  const DictionaryField({
    required this.id,
    required this.dictionaryId,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    required this.isEnabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['field_key'] = Variable<String>(fieldKey);
    map['label'] = Variable<String>(label);
    {
      map['field_type'] = Variable<int>(
        $DictionaryFieldsTable.$converterfieldType.toSql(fieldType),
      );
    }
    map['is_required'] = Variable<bool>(isRequired);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DictionaryFieldsCompanion toCompanion(bool nullToAbsent) {
    return DictionaryFieldsCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      fieldKey: Value(fieldKey),
      label: Value(label),
      fieldType: Value(fieldType),
      isRequired: Value(isRequired),
      isEnabled: Value(isEnabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory DictionaryField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryField(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      label: serializer.fromJson<String>(json['label']),
      fieldType: $DictionaryFieldsTable.$converterfieldType.fromJson(
        serializer.fromJson<int>(json['fieldType']),
      ),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'label': serializer.toJson<String>(label),
      'fieldType': serializer.toJson<int>(
        $DictionaryFieldsTable.$converterfieldType.toJson(fieldType),
      ),
      'isRequired': serializer.toJson<bool>(isRequired),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DictionaryField copyWith({
    int? id,
    int? dictionaryId,
    String? fieldKey,
    String? label,
    DictionaryFieldType? fieldType,
    bool? isRequired,
    bool? isEnabled,
    int? sortOrder,
  }) => DictionaryField(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    fieldKey: fieldKey ?? this.fieldKey,
    label: label ?? this.label,
    fieldType: fieldType ?? this.fieldType,
    isRequired: isRequired ?? this.isRequired,
    isEnabled: isEnabled ?? this.isEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DictionaryField copyWithCompanion(DictionaryFieldsCompanion data) {
    return DictionaryField(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      label: data.label.present ? data.label.value : this.label,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      isRequired: data.isRequired.present
          ? data.isRequired.value
          : this.isRequired,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryField(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('fieldType: $fieldType, ')
          ..write('isRequired: $isRequired, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictionaryId,
    fieldKey,
    label,
    fieldType,
    isRequired,
    isEnabled,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryField &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.fieldKey == this.fieldKey &&
          other.label == this.label &&
          other.fieldType == this.fieldType &&
          other.isRequired == this.isRequired &&
          other.isEnabled == this.isEnabled &&
          other.sortOrder == this.sortOrder);
}

class DictionaryFieldsCompanion extends UpdateCompanion<DictionaryField> {
  final Value<int> id;
  final Value<int> dictionaryId;
  final Value<String> fieldKey;
  final Value<String> label;
  final Value<DictionaryFieldType> fieldType;
  final Value<bool> isRequired;
  final Value<bool> isEnabled;
  final Value<int> sortOrder;
  const DictionaryFieldsCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.label = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  DictionaryFieldsCompanion.insert({
    this.id = const Value.absent(),
    required int dictionaryId,
    required String fieldKey,
    required String label,
    required DictionaryFieldType fieldType,
    this.isRequired = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : dictionaryId = Value(dictionaryId),
       fieldKey = Value(fieldKey),
       label = Value(label),
       fieldType = Value(fieldType);
  static Insertable<DictionaryField> custom({
    Expression<int>? id,
    Expression<int>? dictionaryId,
    Expression<String>? fieldKey,
    Expression<String>? label,
    Expression<int>? fieldType,
    Expression<bool>? isRequired,
    Expression<bool>? isEnabled,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (label != null) 'label': label,
      if (fieldType != null) 'field_type': fieldType,
      if (isRequired != null) 'is_required': isRequired,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  DictionaryFieldsCompanion copyWith({
    Value<int>? id,
    Value<int>? dictionaryId,
    Value<String>? fieldKey,
    Value<String>? label,
    Value<DictionaryFieldType>? fieldType,
    Value<bool>? isRequired,
    Value<bool>? isEnabled,
    Value<int>? sortOrder,
  }) {
    return DictionaryFieldsCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      fieldKey: fieldKey ?? this.fieldKey,
      label: label ?? this.label,
      fieldType: fieldType ?? this.fieldType,
      isRequired: isRequired ?? this.isRequired,
      isEnabled: isEnabled ?? this.isEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<int>(
        $DictionaryFieldsTable.$converterfieldType.toSql(fieldType.value),
      );
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryFieldsCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('label: $label, ')
          ..write('fieldType: $fieldType, ')
          ..write('isRequired: $isRequired, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $DictionaryEntriesTable extends DictionaryEntries
    with TableInfo<$DictionaryEntriesTable, DictionaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dictionaryIdMeta = const VerificationMeta(
    'dictionaryId',
  );
  @override
  late final GeneratedColumn<int> dictionaryId = GeneratedColumn<int>(
    'dictionary_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headwordMeta = const VerificationMeta(
    'headword',
  );
  @override
  late final GeneratedColumn<String> headword = GeneratedColumn<String>(
    'headword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dictionaryId,
    headword,
    category,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dictionary_id')) {
      context.handle(
        _dictionaryIdMeta,
        dictionaryId.isAcceptableOrUnknown(
          data['dictionary_id']!,
          _dictionaryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryIdMeta);
    }
    if (data.containsKey('headword')) {
      context.handle(
        _headwordMeta,
        headword.isAcceptableOrUnknown(data['headword']!, _headwordMeta),
      );
    } else if (isInserting) {
      context.missing(_headwordMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dictionary_id'],
      )!,
      headword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headword'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DictionaryEntriesTable createAlias(String alias) {
    return $DictionaryEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryEntry extends DataClass implements Insertable<DictionaryEntry> {
  final int id;
  final int dictionaryId;
  final String headword;
  final String? category;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DictionaryEntry({
    required this.id,
    required this.dictionaryId,
    required this.headword,
    this.category,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dictionary_id'] = Variable<int>(dictionaryId);
    map['headword'] = Variable<String>(headword);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DictionaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryEntriesCompanion(
      id: Value(id),
      dictionaryId: Value(dictionaryId),
      headword: Value(headword),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DictionaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryEntry(
      id: serializer.fromJson<int>(json['id']),
      dictionaryId: serializer.fromJson<int>(json['dictionaryId']),
      headword: serializer.fromJson<String>(json['headword']),
      category: serializer.fromJson<String?>(json['category']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dictionaryId': serializer.toJson<int>(dictionaryId),
      'headword': serializer.toJson<String>(headword),
      'category': serializer.toJson<String?>(category),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DictionaryEntry copyWith({
    int? id,
    int? dictionaryId,
    String? headword,
    Value<String?> category = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DictionaryEntry(
    id: id ?? this.id,
    dictionaryId: dictionaryId ?? this.dictionaryId,
    headword: headword ?? this.headword,
    category: category.present ? category.value : this.category,
    tags: tags.present ? tags.value : this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DictionaryEntry copyWithCompanion(DictionaryEntriesCompanion data) {
    return DictionaryEntry(
      id: data.id.present ? data.id.value : this.id,
      dictionaryId: data.dictionaryId.present
          ? data.dictionaryId.value
          : this.dictionaryId,
      headword: data.headword.present ? data.headword.value : this.headword,
      category: data.category.present ? data.category.value : this.category,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntry(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dictionaryId,
    headword,
    category,
    tags,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryEntry &&
          other.id == this.id &&
          other.dictionaryId == this.dictionaryId &&
          other.headword == this.headword &&
          other.category == this.category &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DictionaryEntriesCompanion extends UpdateCompanion<DictionaryEntry> {
  final Value<int> id;
  final Value<int> dictionaryId;
  final Value<String> headword;
  final Value<String?> category;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DictionaryEntriesCompanion({
    this.id = const Value.absent(),
    this.dictionaryId = const Value.absent(),
    this.headword = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DictionaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int dictionaryId,
    required String headword,
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : dictionaryId = Value(dictionaryId),
       headword = Value(headword);
  static Insertable<DictionaryEntry> custom({
    Expression<int>? id,
    Expression<int>? dictionaryId,
    Expression<String>? headword,
    Expression<String>? category,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dictionaryId != null) 'dictionary_id': dictionaryId,
      if (headword != null) 'headword': headword,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DictionaryEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? dictionaryId,
    Value<String>? headword,
    Value<String?>? category,
    Value<String?>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DictionaryEntriesCompanion(
      id: id ?? this.id,
      dictionaryId: dictionaryId ?? this.dictionaryId,
      headword: headword ?? this.headword,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dictionaryId.present) {
      map['dictionary_id'] = Variable<int>(dictionaryId.value);
    }
    if (headword.present) {
      map['headword'] = Variable<String>(headword.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dictionaryId: $dictionaryId, ')
          ..write('headword: $headword, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DictionaryEntryValuesTable extends DictionaryEntryValues
    with TableInfo<$DictionaryEntryValuesTable, DictionaryEntryValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryEntryValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldIdMeta = const VerificationMeta(
    'fieldId',
  );
  @override
  late final GeneratedColumn<int> fieldId = GeneratedColumn<int>(
    'field_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    fieldId,
    value,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_entry_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryEntryValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(
        _fieldIdMeta,
        fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryEntryValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryEntryValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      fieldId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}field_id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DictionaryEntryValuesTable createAlias(String alias) {
    return $DictionaryEntryValuesTable(attachedDatabase, alias);
  }
}

class DictionaryEntryValue extends DataClass
    implements Insertable<DictionaryEntryValue> {
  final int id;
  final int entryId;
  final int fieldId;
  final String value;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DictionaryEntryValue({
    required this.id,
    required this.entryId,
    required this.fieldId,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['field_id'] = Variable<int>(fieldId);
    map['value'] = Variable<String>(value);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DictionaryEntryValuesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryEntryValuesCompanion(
      id: Value(id),
      entryId: Value(entryId),
      fieldId: Value(fieldId),
      value: Value(value),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DictionaryEntryValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryEntryValue(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      fieldId: serializer.fromJson<int>(json['fieldId']),
      value: serializer.fromJson<String>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'fieldId': serializer.toJson<int>(fieldId),
      'value': serializer.toJson<String>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DictionaryEntryValue copyWith({
    int? id,
    int? entryId,
    int? fieldId,
    String? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DictionaryEntryValue(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    fieldId: fieldId ?? this.fieldId,
    value: value ?? this.value,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DictionaryEntryValue copyWithCompanion(DictionaryEntryValuesCompanion data) {
    return DictionaryEntryValue(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntryValue(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entryId, fieldId, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryEntryValue &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.fieldId == this.fieldId &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DictionaryEntryValuesCompanion
    extends UpdateCompanion<DictionaryEntryValue> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<int> fieldId;
  final Value<String> value;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DictionaryEntryValuesCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DictionaryEntryValuesCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required int fieldId,
    required String value,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : entryId = Value(entryId),
       fieldId = Value(fieldId),
       value = Value(value);
  static Insertable<DictionaryEntryValue> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<int>? fieldId,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (fieldId != null) 'field_id': fieldId,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DictionaryEntryValuesCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<int>? fieldId,
    Value<String>? value,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DictionaryEntryValuesCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      fieldId: fieldId ?? this.fieldId,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<int>(fieldId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntryValuesCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('fieldId: $fieldId, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $EntryTagsTable extends EntryTags
    with TableInfo<$EntryTagsTable, EntryTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, tagId};
  @override
  EntryTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryTag(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $EntryTagsTable createAlias(String alias) {
    return $EntryTagsTable(attachedDatabase, alias);
  }
}

class EntryTag extends DataClass implements Insertable<EntryTag> {
  final int entryId;
  final int tagId;
  const EntryTag({required this.entryId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  EntryTagsCompanion toCompanion(bool nullToAbsent) {
    return EntryTagsCompanion(entryId: Value(entryId), tagId: Value(tagId));
  }

  factory EntryTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryTag(
      entryId: serializer.fromJson<int>(json['entryId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  EntryTag copyWith({int? entryId, int? tagId}) =>
      EntryTag(entryId: entryId ?? this.entryId, tagId: tagId ?? this.tagId);
  EntryTag copyWithCompanion(EntryTagsCompanion data) {
    return EntryTag(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryTag(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryTag &&
          other.entryId == this.entryId &&
          other.tagId == this.tagId);
}

class EntryTagsCompanion extends UpdateCompanion<EntryTag> {
  final Value<int> entryId;
  final Value<int> tagId;
  final Value<int> rowid;
  const EntryTagsCompanion({
    this.entryId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryTagsCompanion.insert({
    required int entryId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       tagId = Value(tagId);
  static Insertable<EntryTag> custom({
    Expression<int>? entryId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryTagsCompanion copyWith({
    Value<int>? entryId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return EntryTagsCompanion(
      entryId: entryId ?? this.entryId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryTagsCompanion(')
          ..write('entryId: $entryId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuotesTable extends Quotes with TableInfo<$QuotesTable, Quote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteTextMeta = const VerificationMeta(
    'quoteText',
  );
  @override
  late final GeneratedColumn<String> quoteText = GeneratedColumn<String>(
    'quote_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageOrLocMeta = const VerificationMeta(
    'pageOrLoc',
  );
  @override
  late final GeneratedColumn<String> pageOrLoc = GeneratedColumn<String>(
    'page_or_loc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionTitleMeta = const VerificationMeta(
    'sectionTitle',
  );
  @override
  late final GeneratedColumn<String> sectionTitle = GeneratedColumn<String>(
    'section_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceImagePathMeta = const VerificationMeta(
    'sourceImagePath',
  );
  @override
  late final GeneratedColumn<String> sourceImagePath = GeneratedColumn<String>(
    'source_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    quoteText,
    pageOrLoc,
    sectionTitle,
    note,
    sourceImagePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Quote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('quote_text')) {
      context.handle(
        _quoteTextMeta,
        quoteText.isAcceptableOrUnknown(data['quote_text']!, _quoteTextMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteTextMeta);
    }
    if (data.containsKey('page_or_loc')) {
      context.handle(
        _pageOrLocMeta,
        pageOrLoc.isAcceptableOrUnknown(data['page_or_loc']!, _pageOrLocMeta),
      );
    }
    if (data.containsKey('section_title')) {
      context.handle(
        _sectionTitleMeta,
        sectionTitle.isAcceptableOrUnknown(
          data['section_title']!,
          _sectionTitleMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source_image_path')) {
      context.handle(
        _sourceImagePathMeta,
        sourceImagePath.isAcceptableOrUnknown(
          data['source_image_path']!,
          _sourceImagePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      quoteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_text'],
      )!,
      pageOrLoc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_or_loc'],
      ),
      sectionTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sourceImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }
}

class Quote extends DataClass implements Insertable<Quote> {
  final int id;
  final int entryId;
  final String quoteText;
  final String? pageOrLoc;
  final String? sectionTitle;
  final String? note;
  final String? sourceImagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Quote({
    required this.id,
    required this.entryId,
    required this.quoteText,
    this.pageOrLoc,
    this.sectionTitle,
    this.note,
    this.sourceImagePath,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entry_id'] = Variable<int>(entryId);
    map['quote_text'] = Variable<String>(quoteText);
    if (!nullToAbsent || pageOrLoc != null) {
      map['page_or_loc'] = Variable<String>(pageOrLoc);
    }
    if (!nullToAbsent || sectionTitle != null) {
      map['section_title'] = Variable<String>(sectionTitle);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || sourceImagePath != null) {
      map['source_image_path'] = Variable<String>(sourceImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      entryId: Value(entryId),
      quoteText: Value(quoteText),
      pageOrLoc: pageOrLoc == null && nullToAbsent
          ? const Value.absent()
          : Value(pageOrLoc),
      sectionTitle: sectionTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionTitle),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sourceImagePath: sourceImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceImagePath),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Quote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quote(
      id: serializer.fromJson<int>(json['id']),
      entryId: serializer.fromJson<int>(json['entryId']),
      quoteText: serializer.fromJson<String>(json['quoteText']),
      pageOrLoc: serializer.fromJson<String?>(json['pageOrLoc']),
      sectionTitle: serializer.fromJson<String?>(json['sectionTitle']),
      note: serializer.fromJson<String?>(json['note']),
      sourceImagePath: serializer.fromJson<String?>(json['sourceImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entryId': serializer.toJson<int>(entryId),
      'quoteText': serializer.toJson<String>(quoteText),
      'pageOrLoc': serializer.toJson<String?>(pageOrLoc),
      'sectionTitle': serializer.toJson<String?>(sectionTitle),
      'note': serializer.toJson<String?>(note),
      'sourceImagePath': serializer.toJson<String?>(sourceImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Quote copyWith({
    int? id,
    int? entryId,
    String? quoteText,
    Value<String?> pageOrLoc = const Value.absent(),
    Value<String?> sectionTitle = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> sourceImagePath = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Quote(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    quoteText: quoteText ?? this.quoteText,
    pageOrLoc: pageOrLoc.present ? pageOrLoc.value : this.pageOrLoc,
    sectionTitle: sectionTitle.present ? sectionTitle.value : this.sectionTitle,
    note: note.present ? note.value : this.note,
    sourceImagePath: sourceImagePath.present
        ? sourceImagePath.value
        : this.sourceImagePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Quote copyWithCompanion(QuotesCompanion data) {
    return Quote(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      quoteText: data.quoteText.present ? data.quoteText.value : this.quoteText,
      pageOrLoc: data.pageOrLoc.present ? data.pageOrLoc.value : this.pageOrLoc,
      sectionTitle: data.sectionTitle.present
          ? data.sectionTitle.value
          : this.sectionTitle,
      note: data.note.present ? data.note.value : this.note,
      sourceImagePath: data.sourceImagePath.present
          ? data.sourceImagePath.value
          : this.sourceImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quote(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('quoteText: $quoteText, ')
          ..write('pageOrLoc: $pageOrLoc, ')
          ..write('sectionTitle: $sectionTitle, ')
          ..write('note: $note, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    quoteText,
    pageOrLoc,
    sectionTitle,
    note,
    sourceImagePath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quote &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.quoteText == this.quoteText &&
          other.pageOrLoc == this.pageOrLoc &&
          other.sectionTitle == this.sectionTitle &&
          other.note == this.note &&
          other.sourceImagePath == this.sourceImagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuotesCompanion extends UpdateCompanion<Quote> {
  final Value<int> id;
  final Value<int> entryId;
  final Value<String> quoteText;
  final Value<String?> pageOrLoc;
  final Value<String?> sectionTitle;
  final Value<String?> note;
  final Value<String?> sourceImagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.quoteText = const Value.absent(),
    this.pageOrLoc = const Value.absent(),
    this.sectionTitle = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QuotesCompanion.insert({
    this.id = const Value.absent(),
    required int entryId,
    required String quoteText,
    this.pageOrLoc = const Value.absent(),
    this.sectionTitle = const Value.absent(),
    this.note = const Value.absent(),
    this.sourceImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : entryId = Value(entryId),
       quoteText = Value(quoteText);
  static Insertable<Quote> custom({
    Expression<int>? id,
    Expression<int>? entryId,
    Expression<String>? quoteText,
    Expression<String>? pageOrLoc,
    Expression<String>? sectionTitle,
    Expression<String>? note,
    Expression<String>? sourceImagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (quoteText != null) 'quote_text': quoteText,
      if (pageOrLoc != null) 'page_or_loc': pageOrLoc,
      if (sectionTitle != null) 'section_title': sectionTitle,
      if (note != null) 'note': note,
      if (sourceImagePath != null) 'source_image_path': sourceImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QuotesCompanion copyWith({
    Value<int>? id,
    Value<int>? entryId,
    Value<String>? quoteText,
    Value<String?>? pageOrLoc,
    Value<String?>? sectionTitle,
    Value<String?>? note,
    Value<String?>? sourceImagePath,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
  }) {
    return QuotesCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      quoteText: quoteText ?? this.quoteText,
      pageOrLoc: pageOrLoc ?? this.pageOrLoc,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      note: note ?? this.note,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (quoteText.present) {
      map['quote_text'] = Variable<String>(quoteText.value);
    }
    if (pageOrLoc.present) {
      map['page_or_loc'] = Variable<String>(pageOrLoc.value);
    }
    if (sectionTitle.present) {
      map['section_title'] = Variable<String>(sectionTitle.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sourceImagePath.present) {
      map['source_image_path'] = Variable<String>(sourceImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('quoteText: $quoteText, ')
          ..write('pageOrLoc: $pageOrLoc, ')
          ..write('sectionTitle: $sectionTitle, ')
          ..write('note: $note, ')
          ..write('sourceImagePath: $sourceImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, Source> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, url, title, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<Source> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Source(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends DataClass implements Insertable<Source> {
  final int id;
  final String? url;
  final String? title;
  final String? note;
  const Source({required this.id, this.url, this.title, this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String?>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String?>(url),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
    };
  }

  Source copyWith({
    int? id,
    Value<String?> url = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Source(
    id: id ?? this.id,
    url: url.present ? url.value : this.url,
    title: title.present ? title.value : this.title,
    note: note.present ? note.value : this.note,
  );
  Source copyWithCompanion(SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, url, title, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Source &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.note == this.note);
}

class SourcesCompanion extends UpdateCompanion<Source> {
  final Value<int> id;
  final Value<String?> url;
  final Value<String?> title;
  final Value<String?> note;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
  });
  static Insertable<Source> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String?>? url,
    Value<String?>? title,
    Value<String?>? note,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $EntrySourcesTable extends EntrySources
    with TableInfo<$EntrySourcesTable, EntrySource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntrySourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryId, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntrySource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryId, sourceId};
  @override
  EntrySource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntrySource(
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $EntrySourcesTable createAlias(String alias) {
    return $EntrySourcesTable(attachedDatabase, alias);
  }
}

class EntrySource extends DataClass implements Insertable<EntrySource> {
  final int entryId;
  final int sourceId;
  const EntrySource({required this.entryId, required this.sourceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_id'] = Variable<int>(entryId);
    map['source_id'] = Variable<int>(sourceId);
    return map;
  }

  EntrySourcesCompanion toCompanion(bool nullToAbsent) {
    return EntrySourcesCompanion(
      entryId: Value(entryId),
      sourceId: Value(sourceId),
    );
  }

  factory EntrySource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntrySource(
      entryId: serializer.fromJson<int>(json['entryId']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryId': serializer.toJson<int>(entryId),
      'sourceId': serializer.toJson<int>(sourceId),
    };
  }

  EntrySource copyWith({int? entryId, int? sourceId}) => EntrySource(
    entryId: entryId ?? this.entryId,
    sourceId: sourceId ?? this.sourceId,
  );
  EntrySource copyWithCompanion(EntrySourcesCompanion data) {
    return EntrySource(
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntrySource(')
          ..write('entryId: $entryId, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryId, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntrySource &&
          other.entryId == this.entryId &&
          other.sourceId == this.sourceId);
}

class EntrySourcesCompanion extends UpdateCompanion<EntrySource> {
  final Value<int> entryId;
  final Value<int> sourceId;
  final Value<int> rowid;
  const EntrySourcesCompanion({
    this.entryId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntrySourcesCompanion.insert({
    required int entryId,
    required int sourceId,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       sourceId = Value(sourceId);
  static Insertable<EntrySource> custom({
    Expression<int>? entryId,
    Expression<int>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryId != null) 'entry_id': entryId,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntrySourcesCompanion copyWith({
    Value<int>? entryId,
    Value<int>? sourceId,
    Value<int>? rowid,
  }) {
    return EntrySourcesCompanion(
      entryId: entryId ?? this.entryId,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntrySourcesCompanion(')
          ..write('entryId: $entryId, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AISessionsTable extends AISessions
    with TableInfo<$AISessionsTable, AISession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AISessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _subjectTypeMeta = const VerificationMeta(
    'subjectType',
  );
  @override
  late final GeneratedColumn<String> subjectType = GeneratedColumn<String>(
    'subject_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectType,
    subjectId,
    role,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AISession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('subject_type')) {
      context.handle(
        _subjectTypeMeta,
        subjectType.isAcceptableOrUnknown(
          data['subject_type']!,
          _subjectTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectTypeMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AISession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AISession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subjectType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_type'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AISessionsTable createAlias(String alias) {
    return $AISessionsTable(attachedDatabase, alias);
  }
}

class AISession extends DataClass implements Insertable<AISession> {
  final int id;
  final String subjectType;
  final int subjectId;
  final String role;
  final String content;
  final DateTime createdAt;
  const AISession({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    required this.role,
    required this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['subject_type'] = Variable<String>(subjectType);
    map['subject_id'] = Variable<int>(subjectId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AISessionsCompanion toCompanion(bool nullToAbsent) {
    return AISessionsCompanion(
      id: Value(id),
      subjectType: Value(subjectType),
      subjectId: Value(subjectId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AISession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AISession(
      id: serializer.fromJson<int>(json['id']),
      subjectType: serializer.fromJson<String>(json['subjectType']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subjectType': serializer.toJson<String>(subjectType),
      'subjectId': serializer.toJson<int>(subjectId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AISession copyWith({
    int? id,
    String? subjectType,
    int? subjectId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) => AISession(
    id: id ?? this.id,
    subjectType: subjectType ?? this.subjectType,
    subjectId: subjectId ?? this.subjectId,
    role: role ?? this.role,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  AISession copyWithCompanion(AISessionsCompanion data) {
    return AISession(
      id: data.id.present ? data.id.value : this.id,
      subjectType: data.subjectType.present
          ? data.subjectType.value
          : this.subjectType,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AISession(')
          ..write('id: $id, ')
          ..write('subjectType: $subjectType, ')
          ..write('subjectId: $subjectId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, subjectType, subjectId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AISession &&
          other.id == this.id &&
          other.subjectType == this.subjectType &&
          other.subjectId == this.subjectId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AISessionsCompanion extends UpdateCompanion<AISession> {
  final Value<int> id;
  final Value<String> subjectType;
  final Value<int> subjectId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const AISessionsCompanion({
    this.id = const Value.absent(),
    this.subjectType = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AISessionsCompanion.insert({
    this.id = const Value.absent(),
    required String subjectType,
    required int subjectId,
    required String role,
    required String content,
    this.createdAt = const Value.absent(),
  }) : subjectType = Value(subjectType),
       subjectId = Value(subjectId),
       role = Value(role),
       content = Value(content);
  static Insertable<AISession> custom({
    Expression<int>? id,
    Expression<String>? subjectType,
    Expression<int>? subjectId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectType != null) 'subject_type': subjectType,
      if (subjectId != null) 'subject_id': subjectId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AISessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? subjectType,
    Value<int>? subjectId,
    Value<String>? role,
    Value<String>? content,
    Value<DateTime>? createdAt,
  }) {
    return AISessionsCompanion(
      id: id ?? this.id,
      subjectType: subjectType ?? this.subjectType,
      subjectId: subjectId ?? this.subjectId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subjectType.present) {
      map['subject_type'] = Variable<String>(subjectType.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AISessionsCompanion(')
          ..write('id: $id, ')
          ..write('subjectType: $subjectType, ')
          ..write('subjectId: $subjectId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PhilosophicalDialoguesTable extends PhilosophicalDialogues
    with TableInfo<$PhilosophicalDialoguesTable, PhilosophicalDialogue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhilosophicalDialoguesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    summary,
    category,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'philosophical_dialogues';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhilosophicalDialogue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhilosophicalDialogue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhilosophicalDialogue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PhilosophicalDialoguesTable createAlias(String alias) {
    return $PhilosophicalDialoguesTable(attachedDatabase, alias);
  }
}

class PhilosophicalDialogue extends DataClass
    implements Insertable<PhilosophicalDialogue> {
  final int id;
  final String title;
  final String? summary;
  final String? category;
  final String? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PhilosophicalDialogue({
    required this.id,
    required this.title,
    this.summary,
    this.category,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PhilosophicalDialoguesCompanion toCompanion(bool nullToAbsent) {
    return PhilosophicalDialoguesCompanion(
      id: Value(id),
      title: Value(title),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PhilosophicalDialogue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhilosophicalDialogue(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String?>(json['summary']),
      category: serializer.fromJson<String?>(json['category']),
      tags: serializer.fromJson<String?>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String?>(summary),
      'category': serializer.toJson<String?>(category),
      'tags': serializer.toJson<String?>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PhilosophicalDialogue copyWith({
    int? id,
    String? title,
    Value<String?> summary = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PhilosophicalDialogue(
    id: id ?? this.id,
    title: title ?? this.title,
    summary: summary.present ? summary.value : this.summary,
    category: category.present ? category.value : this.category,
    tags: tags.present ? tags.value : this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PhilosophicalDialogue copyWithCompanion(
    PhilosophicalDialoguesCompanion data,
  ) {
    return PhilosophicalDialogue(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      category: data.category.present ? data.category.value : this.category,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalDialogue(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, summary, category, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhilosophicalDialogue &&
          other.id == this.id &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.category == this.category &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PhilosophicalDialoguesCompanion
    extends UpdateCompanion<PhilosophicalDialogue> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> summary;
  final Value<String?> category;
  final Value<String?> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PhilosophicalDialoguesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PhilosophicalDialoguesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.summary = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<PhilosophicalDialogue> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? category,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PhilosophicalDialoguesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? summary,
    Value<String?>? category,
    Value<String?>? tags,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PhilosophicalDialoguesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalDialoguesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PhilosophicalMessagesTable extends PhilosophicalMessages
    with TableInfo<$PhilosophicalMessagesTable, PhilosophicalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhilosophicalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dialogueIdMeta = const VerificationMeta(
    'dialogueId',
  );
  @override
  late final GeneratedColumn<int> dialogueId = GeneratedColumn<int>(
    'dialogue_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DialogueRole, int> role =
      GeneratedColumn<int>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DialogueRole>($PhilosophicalMessagesTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<DialogueInputType, int>
  inputType =
      GeneratedColumn<int>(
        'input_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<DialogueInputType>(
        $PhilosophicalMessagesTable.$converterinputType,
      );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _personaMeta = const VerificationMeta(
    'persona',
  );
  @override
  late final GeneratedColumn<String> persona = GeneratedColumn<String>(
    'persona',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dialogueId,
    role,
    inputType,
    content,
    persona,
    imagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'philosophical_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhilosophicalMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dialogue_id')) {
      context.handle(
        _dialogueIdMeta,
        dialogueId.isAcceptableOrUnknown(data['dialogue_id']!, _dialogueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dialogueIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('persona')) {
      context.handle(
        _personaMeta,
        persona.isAcceptableOrUnknown(data['persona']!, _personaMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhilosophicalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhilosophicalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dialogueId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dialogue_id'],
      )!,
      role: $PhilosophicalMessagesTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}role'],
        )!,
      ),
      inputType: $PhilosophicalMessagesTable.$converterinputType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}input_type'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      persona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}persona'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhilosophicalMessagesTable createAlias(String alias) {
    return $PhilosophicalMessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DialogueRole, int, int> $converterrole =
      const EnumIndexConverter<DialogueRole>(DialogueRole.values);
  static JsonTypeConverter2<DialogueInputType, int, int> $converterinputType =
      const EnumIndexConverter<DialogueInputType>(DialogueInputType.values);
}

class PhilosophicalMessage extends DataClass
    implements Insertable<PhilosophicalMessage> {
  final int id;
  final int dialogueId;
  final DialogueRole role;
  final DialogueInputType inputType;
  final String content;
  final String? persona;
  final String? imagePath;
  final DateTime createdAt;
  const PhilosophicalMessage({
    required this.id,
    required this.dialogueId,
    required this.role,
    required this.inputType,
    required this.content,
    this.persona,
    this.imagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dialogue_id'] = Variable<int>(dialogueId);
    {
      map['role'] = Variable<int>(
        $PhilosophicalMessagesTable.$converterrole.toSql(role),
      );
    }
    {
      map['input_type'] = Variable<int>(
        $PhilosophicalMessagesTable.$converterinputType.toSql(inputType),
      );
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || persona != null) {
      map['persona'] = Variable<String>(persona);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhilosophicalMessagesCompanion toCompanion(bool nullToAbsent) {
    return PhilosophicalMessagesCompanion(
      id: Value(id),
      dialogueId: Value(dialogueId),
      role: Value(role),
      inputType: Value(inputType),
      content: Value(content),
      persona: persona == null && nullToAbsent
          ? const Value.absent()
          : Value(persona),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory PhilosophicalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhilosophicalMessage(
      id: serializer.fromJson<int>(json['id']),
      dialogueId: serializer.fromJson<int>(json['dialogueId']),
      role: $PhilosophicalMessagesTable.$converterrole.fromJson(
        serializer.fromJson<int>(json['role']),
      ),
      inputType: $PhilosophicalMessagesTable.$converterinputType.fromJson(
        serializer.fromJson<int>(json['inputType']),
      ),
      content: serializer.fromJson<String>(json['content']),
      persona: serializer.fromJson<String?>(json['persona']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dialogueId': serializer.toJson<int>(dialogueId),
      'role': serializer.toJson<int>(
        $PhilosophicalMessagesTable.$converterrole.toJson(role),
      ),
      'inputType': serializer.toJson<int>(
        $PhilosophicalMessagesTable.$converterinputType.toJson(inputType),
      ),
      'content': serializer.toJson<String>(content),
      'persona': serializer.toJson<String?>(persona),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PhilosophicalMessage copyWith({
    int? id,
    int? dialogueId,
    DialogueRole? role,
    DialogueInputType? inputType,
    String? content,
    Value<String?> persona = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    DateTime? createdAt,
  }) => PhilosophicalMessage(
    id: id ?? this.id,
    dialogueId: dialogueId ?? this.dialogueId,
    role: role ?? this.role,
    inputType: inputType ?? this.inputType,
    content: content ?? this.content,
    persona: persona.present ? persona.value : this.persona,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  PhilosophicalMessage copyWithCompanion(PhilosophicalMessagesCompanion data) {
    return PhilosophicalMessage(
      id: data.id.present ? data.id.value : this.id,
      dialogueId: data.dialogueId.present
          ? data.dialogueId.value
          : this.dialogueId,
      role: data.role.present ? data.role.value : this.role,
      inputType: data.inputType.present ? data.inputType.value : this.inputType,
      content: data.content.present ? data.content.value : this.content,
      persona: data.persona.present ? data.persona.value : this.persona,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalMessage(')
          ..write('id: $id, ')
          ..write('dialogueId: $dialogueId, ')
          ..write('role: $role, ')
          ..write('inputType: $inputType, ')
          ..write('content: $content, ')
          ..write('persona: $persona, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dialogueId,
    role,
    inputType,
    content,
    persona,
    imagePath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhilosophicalMessage &&
          other.id == this.id &&
          other.dialogueId == this.dialogueId &&
          other.role == this.role &&
          other.inputType == this.inputType &&
          other.content == this.content &&
          other.persona == this.persona &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class PhilosophicalMessagesCompanion
    extends UpdateCompanion<PhilosophicalMessage> {
  final Value<int> id;
  final Value<int> dialogueId;
  final Value<DialogueRole> role;
  final Value<DialogueInputType> inputType;
  final Value<String> content;
  final Value<String?> persona;
  final Value<String?> imagePath;
  final Value<DateTime> createdAt;
  const PhilosophicalMessagesCompanion({
    this.id = const Value.absent(),
    this.dialogueId = const Value.absent(),
    this.role = const Value.absent(),
    this.inputType = const Value.absent(),
    this.content = const Value.absent(),
    this.persona = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhilosophicalMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int dialogueId,
    required DialogueRole role,
    this.inputType = const Value.absent(),
    this.content = const Value.absent(),
    this.persona = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : dialogueId = Value(dialogueId),
       role = Value(role);
  static Insertable<PhilosophicalMessage> custom({
    Expression<int>? id,
    Expression<int>? dialogueId,
    Expression<int>? role,
    Expression<int>? inputType,
    Expression<String>? content,
    Expression<String>? persona,
    Expression<String>? imagePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dialogueId != null) 'dialogue_id': dialogueId,
      if (role != null) 'role': role,
      if (inputType != null) 'input_type': inputType,
      if (content != null) 'content': content,
      if (persona != null) 'persona': persona,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhilosophicalMessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? dialogueId,
    Value<DialogueRole>? role,
    Value<DialogueInputType>? inputType,
    Value<String>? content,
    Value<String?>? persona,
    Value<String?>? imagePath,
    Value<DateTime>? createdAt,
  }) {
    return PhilosophicalMessagesCompanion(
      id: id ?? this.id,
      dialogueId: dialogueId ?? this.dialogueId,
      role: role ?? this.role,
      inputType: inputType ?? this.inputType,
      content: content ?? this.content,
      persona: persona ?? this.persona,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dialogueId.present) {
      map['dialogue_id'] = Variable<int>(dialogueId.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(
        $PhilosophicalMessagesTable.$converterrole.toSql(role.value),
      );
    }
    if (inputType.present) {
      map['input_type'] = Variable<int>(
        $PhilosophicalMessagesTable.$converterinputType.toSql(inputType.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (persona.present) {
      map['persona'] = Variable<String>(persona.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('dialogueId: $dialogueId, ')
          ..write('role: $role, ')
          ..write('inputType: $inputType, ')
          ..write('content: $content, ')
          ..write('persona: $persona, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PhilosophicalConceptExtractionsTable
    extends PhilosophicalConceptExtractions
    with
        TableInfo<
          $PhilosophicalConceptExtractionsTable,
          PhilosophicalConceptExtraction
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhilosophicalConceptExtractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dialogueIdMeta = const VerificationMeta(
    'dialogueId',
  );
  @override
  late final GeneratedColumn<int> dialogueId = GeneratedColumn<int>(
    'dialogue_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personaMeta = const VerificationMeta(
    'persona',
  );
  @override
  late final GeneratedColumn<String> persona = GeneratedColumn<String>(
    'persona',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conceptTitleMeta = const VerificationMeta(
    'conceptTitle',
  );
  @override
  late final GeneratedColumn<String> conceptTitle = GeneratedColumn<String>(
    'concept_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptBodyMeta = const VerificationMeta(
    'conceptBody',
  );
  @override
  late final GeneratedColumn<String> conceptBody = GeneratedColumn<String>(
    'concept_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConceptOrigin, int>
  conceptOrigin =
      GeneratedColumn<int>(
        'concept_origin',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<ConceptOrigin>(
        $PhilosophicalConceptExtractionsTable.$converterconceptOrigin,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ExtractionStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ExtractionStatus>(
        $PhilosophicalConceptExtractionsTable.$converterstatus,
      );
  static const VerificationMeta _conceptDictionaryIdMeta =
      const VerificationMeta('conceptDictionaryId');
  @override
  late final GeneratedColumn<int> conceptDictionaryId = GeneratedColumn<int>(
    'concept_dictionary_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dialogueId,
    messageId,
    persona,
    conceptTitle,
    conceptBody,
    conceptOrigin,
    status,
    conceptDictionaryId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'philosophical_concept_extractions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhilosophicalConceptExtraction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dialogue_id')) {
      context.handle(
        _dialogueIdMeta,
        dialogueId.isAcceptableOrUnknown(data['dialogue_id']!, _dialogueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dialogueIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('persona')) {
      context.handle(
        _personaMeta,
        persona.isAcceptableOrUnknown(data['persona']!, _personaMeta),
      );
    }
    if (data.containsKey('concept_title')) {
      context.handle(
        _conceptTitleMeta,
        conceptTitle.isAcceptableOrUnknown(
          data['concept_title']!,
          _conceptTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptTitleMeta);
    }
    if (data.containsKey('concept_body')) {
      context.handle(
        _conceptBodyMeta,
        conceptBody.isAcceptableOrUnknown(
          data['concept_body']!,
          _conceptBodyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conceptBodyMeta);
    }
    if (data.containsKey('concept_dictionary_id')) {
      context.handle(
        _conceptDictionaryIdMeta,
        conceptDictionaryId.isAcceptableOrUnknown(
          data['concept_dictionary_id']!,
          _conceptDictionaryIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhilosophicalConceptExtraction map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhilosophicalConceptExtraction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dialogueId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dialogue_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_id'],
      ),
      persona: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}persona'],
      ),
      conceptTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_title'],
      )!,
      conceptBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concept_body'],
      )!,
      conceptOrigin: $PhilosophicalConceptExtractionsTable
          .$converterconceptOrigin
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}concept_origin'],
            )!,
          ),
      status: $PhilosophicalConceptExtractionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      conceptDictionaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}concept_dictionary_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PhilosophicalConceptExtractionsTable createAlias(String alias) {
    return $PhilosophicalConceptExtractionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConceptOrigin, int, int> $converterconceptOrigin =
      const EnumIndexConverter<ConceptOrigin>(ConceptOrigin.values);
  static JsonTypeConverter2<ExtractionStatus, int, int> $converterstatus =
      const EnumIndexConverter<ExtractionStatus>(ExtractionStatus.values);
}

class PhilosophicalConceptExtraction extends DataClass
    implements Insertable<PhilosophicalConceptExtraction> {
  final int id;
  final int dialogueId;
  final int? messageId;
  final String? persona;
  final String conceptTitle;
  final String conceptBody;
  final ConceptOrigin conceptOrigin;
  final ExtractionStatus status;
  final int? conceptDictionaryId;
  final DateTime createdAt;
  const PhilosophicalConceptExtraction({
    required this.id,
    required this.dialogueId,
    this.messageId,
    this.persona,
    required this.conceptTitle,
    required this.conceptBody,
    required this.conceptOrigin,
    required this.status,
    this.conceptDictionaryId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dialogue_id'] = Variable<int>(dialogueId);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<int>(messageId);
    }
    if (!nullToAbsent || persona != null) {
      map['persona'] = Variable<String>(persona);
    }
    map['concept_title'] = Variable<String>(conceptTitle);
    map['concept_body'] = Variable<String>(conceptBody);
    {
      map['concept_origin'] = Variable<int>(
        $PhilosophicalConceptExtractionsTable.$converterconceptOrigin.toSql(
          conceptOrigin,
        ),
      );
    }
    {
      map['status'] = Variable<int>(
        $PhilosophicalConceptExtractionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || conceptDictionaryId != null) {
      map['concept_dictionary_id'] = Variable<int>(conceptDictionaryId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PhilosophicalConceptExtractionsCompanion toCompanion(bool nullToAbsent) {
    return PhilosophicalConceptExtractionsCompanion(
      id: Value(id),
      dialogueId: Value(dialogueId),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      persona: persona == null && nullToAbsent
          ? const Value.absent()
          : Value(persona),
      conceptTitle: Value(conceptTitle),
      conceptBody: Value(conceptBody),
      conceptOrigin: Value(conceptOrigin),
      status: Value(status),
      conceptDictionaryId: conceptDictionaryId == null && nullToAbsent
          ? const Value.absent()
          : Value(conceptDictionaryId),
      createdAt: Value(createdAt),
    );
  }

  factory PhilosophicalConceptExtraction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhilosophicalConceptExtraction(
      id: serializer.fromJson<int>(json['id']),
      dialogueId: serializer.fromJson<int>(json['dialogueId']),
      messageId: serializer.fromJson<int?>(json['messageId']),
      persona: serializer.fromJson<String?>(json['persona']),
      conceptTitle: serializer.fromJson<String>(json['conceptTitle']),
      conceptBody: serializer.fromJson<String>(json['conceptBody']),
      conceptOrigin: $PhilosophicalConceptExtractionsTable
          .$converterconceptOrigin
          .fromJson(serializer.fromJson<int>(json['conceptOrigin'])),
      status: $PhilosophicalConceptExtractionsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      conceptDictionaryId: serializer.fromJson<int?>(
        json['conceptDictionaryId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dialogueId': serializer.toJson<int>(dialogueId),
      'messageId': serializer.toJson<int?>(messageId),
      'persona': serializer.toJson<String?>(persona),
      'conceptTitle': serializer.toJson<String>(conceptTitle),
      'conceptBody': serializer.toJson<String>(conceptBody),
      'conceptOrigin': serializer.toJson<int>(
        $PhilosophicalConceptExtractionsTable.$converterconceptOrigin.toJson(
          conceptOrigin,
        ),
      ),
      'status': serializer.toJson<int>(
        $PhilosophicalConceptExtractionsTable.$converterstatus.toJson(status),
      ),
      'conceptDictionaryId': serializer.toJson<int?>(conceptDictionaryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PhilosophicalConceptExtraction copyWith({
    int? id,
    int? dialogueId,
    Value<int?> messageId = const Value.absent(),
    Value<String?> persona = const Value.absent(),
    String? conceptTitle,
    String? conceptBody,
    ConceptOrigin? conceptOrigin,
    ExtractionStatus? status,
    Value<int?> conceptDictionaryId = const Value.absent(),
    DateTime? createdAt,
  }) => PhilosophicalConceptExtraction(
    id: id ?? this.id,
    dialogueId: dialogueId ?? this.dialogueId,
    messageId: messageId.present ? messageId.value : this.messageId,
    persona: persona.present ? persona.value : this.persona,
    conceptTitle: conceptTitle ?? this.conceptTitle,
    conceptBody: conceptBody ?? this.conceptBody,
    conceptOrigin: conceptOrigin ?? this.conceptOrigin,
    status: status ?? this.status,
    conceptDictionaryId: conceptDictionaryId.present
        ? conceptDictionaryId.value
        : this.conceptDictionaryId,
    createdAt: createdAt ?? this.createdAt,
  );
  PhilosophicalConceptExtraction copyWithCompanion(
    PhilosophicalConceptExtractionsCompanion data,
  ) {
    return PhilosophicalConceptExtraction(
      id: data.id.present ? data.id.value : this.id,
      dialogueId: data.dialogueId.present
          ? data.dialogueId.value
          : this.dialogueId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      persona: data.persona.present ? data.persona.value : this.persona,
      conceptTitle: data.conceptTitle.present
          ? data.conceptTitle.value
          : this.conceptTitle,
      conceptBody: data.conceptBody.present
          ? data.conceptBody.value
          : this.conceptBody,
      conceptOrigin: data.conceptOrigin.present
          ? data.conceptOrigin.value
          : this.conceptOrigin,
      status: data.status.present ? data.status.value : this.status,
      conceptDictionaryId: data.conceptDictionaryId.present
          ? data.conceptDictionaryId.value
          : this.conceptDictionaryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalConceptExtraction(')
          ..write('id: $id, ')
          ..write('dialogueId: $dialogueId, ')
          ..write('messageId: $messageId, ')
          ..write('persona: $persona, ')
          ..write('conceptTitle: $conceptTitle, ')
          ..write('conceptBody: $conceptBody, ')
          ..write('conceptOrigin: $conceptOrigin, ')
          ..write('status: $status, ')
          ..write('conceptDictionaryId: $conceptDictionaryId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dialogueId,
    messageId,
    persona,
    conceptTitle,
    conceptBody,
    conceptOrigin,
    status,
    conceptDictionaryId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhilosophicalConceptExtraction &&
          other.id == this.id &&
          other.dialogueId == this.dialogueId &&
          other.messageId == this.messageId &&
          other.persona == this.persona &&
          other.conceptTitle == this.conceptTitle &&
          other.conceptBody == this.conceptBody &&
          other.conceptOrigin == this.conceptOrigin &&
          other.status == this.status &&
          other.conceptDictionaryId == this.conceptDictionaryId &&
          other.createdAt == this.createdAt);
}

class PhilosophicalConceptExtractionsCompanion
    extends UpdateCompanion<PhilosophicalConceptExtraction> {
  final Value<int> id;
  final Value<int> dialogueId;
  final Value<int?> messageId;
  final Value<String?> persona;
  final Value<String> conceptTitle;
  final Value<String> conceptBody;
  final Value<ConceptOrigin> conceptOrigin;
  final Value<ExtractionStatus> status;
  final Value<int?> conceptDictionaryId;
  final Value<DateTime> createdAt;
  const PhilosophicalConceptExtractionsCompanion({
    this.id = const Value.absent(),
    this.dialogueId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.persona = const Value.absent(),
    this.conceptTitle = const Value.absent(),
    this.conceptBody = const Value.absent(),
    this.conceptOrigin = const Value.absent(),
    this.status = const Value.absent(),
    this.conceptDictionaryId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PhilosophicalConceptExtractionsCompanion.insert({
    this.id = const Value.absent(),
    required int dialogueId,
    this.messageId = const Value.absent(),
    this.persona = const Value.absent(),
    required String conceptTitle,
    required String conceptBody,
    this.conceptOrigin = const Value.absent(),
    this.status = const Value.absent(),
    this.conceptDictionaryId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : dialogueId = Value(dialogueId),
       conceptTitle = Value(conceptTitle),
       conceptBody = Value(conceptBody);
  static Insertable<PhilosophicalConceptExtraction> custom({
    Expression<int>? id,
    Expression<int>? dialogueId,
    Expression<int>? messageId,
    Expression<String>? persona,
    Expression<String>? conceptTitle,
    Expression<String>? conceptBody,
    Expression<int>? conceptOrigin,
    Expression<int>? status,
    Expression<int>? conceptDictionaryId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dialogueId != null) 'dialogue_id': dialogueId,
      if (messageId != null) 'message_id': messageId,
      if (persona != null) 'persona': persona,
      if (conceptTitle != null) 'concept_title': conceptTitle,
      if (conceptBody != null) 'concept_body': conceptBody,
      if (conceptOrigin != null) 'concept_origin': conceptOrigin,
      if (status != null) 'status': status,
      if (conceptDictionaryId != null)
        'concept_dictionary_id': conceptDictionaryId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PhilosophicalConceptExtractionsCompanion copyWith({
    Value<int>? id,
    Value<int>? dialogueId,
    Value<int?>? messageId,
    Value<String?>? persona,
    Value<String>? conceptTitle,
    Value<String>? conceptBody,
    Value<ConceptOrigin>? conceptOrigin,
    Value<ExtractionStatus>? status,
    Value<int?>? conceptDictionaryId,
    Value<DateTime>? createdAt,
  }) {
    return PhilosophicalConceptExtractionsCompanion(
      id: id ?? this.id,
      dialogueId: dialogueId ?? this.dialogueId,
      messageId: messageId ?? this.messageId,
      persona: persona ?? this.persona,
      conceptTitle: conceptTitle ?? this.conceptTitle,
      conceptBody: conceptBody ?? this.conceptBody,
      conceptOrigin: conceptOrigin ?? this.conceptOrigin,
      status: status ?? this.status,
      conceptDictionaryId: conceptDictionaryId ?? this.conceptDictionaryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dialogueId.present) {
      map['dialogue_id'] = Variable<int>(dialogueId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (persona.present) {
      map['persona'] = Variable<String>(persona.value);
    }
    if (conceptTitle.present) {
      map['concept_title'] = Variable<String>(conceptTitle.value);
    }
    if (conceptBody.present) {
      map['concept_body'] = Variable<String>(conceptBody.value);
    }
    if (conceptOrigin.present) {
      map['concept_origin'] = Variable<int>(
        $PhilosophicalConceptExtractionsTable.$converterconceptOrigin.toSql(
          conceptOrigin.value,
        ),
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $PhilosophicalConceptExtractionsTable.$converterstatus.toSql(
          status.value,
        ),
      );
    }
    if (conceptDictionaryId.present) {
      map['concept_dictionary_id'] = Variable<int>(conceptDictionaryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhilosophicalConceptExtractionsCompanion(')
          ..write('id: $id, ')
          ..write('dialogueId: $dialogueId, ')
          ..write('messageId: $messageId, ')
          ..write('persona: $persona, ')
          ..write('conceptTitle: $conceptTitle, ')
          ..write('conceptBody: $conceptBody, ')
          ..write('conceptOrigin: $conceptOrigin, ')
          ..write('status: $status, ')
          ..write('conceptDictionaryId: $conceptDictionaryId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $EnglishLexiconsTable englishLexicons = $EnglishLexiconsTable(
    this,
  );
  late final $EntryAppendicesTable entryAppendices = $EntryAppendicesTable(
    this,
  );
  late final $BooksTable books = $BooksTable(this);
  late final $ReadingMemosTable readingMemos = $ReadingMemosTable(this);
  late final $ReadingReflectionsTable readingReflections =
      $ReadingReflectionsTable(this);
  late final $ConceptDictionariesTable conceptDictionaries =
      $ConceptDictionariesTable(this);
  late final $ConceptMemosTable conceptMemos = $ConceptMemosTable(this);
  late final $DailyMemosTable dailyMemos = $DailyMemosTable(this);
  late final $DictionaryDefinitionsTable dictionaryDefinitions =
      $DictionaryDefinitionsTable(this);
  late final $DictionaryFieldsTable dictionaryFields = $DictionaryFieldsTable(
    this,
  );
  late final $DictionaryEntriesTable dictionaryEntries =
      $DictionaryEntriesTable(this);
  late final $DictionaryEntryValuesTable dictionaryEntryValues =
      $DictionaryEntryValuesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $EntryTagsTable entryTags = $EntryTagsTable(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $EntrySourcesTable entrySources = $EntrySourcesTable(this);
  late final $AISessionsTable aISessions = $AISessionsTable(this);
  late final $PhilosophicalDialoguesTable philosophicalDialogues =
      $PhilosophicalDialoguesTable(this);
  late final $PhilosophicalMessagesTable philosophicalMessages =
      $PhilosophicalMessagesTable(this);
  late final $PhilosophicalConceptExtractionsTable
  philosophicalConceptExtractions = $PhilosophicalConceptExtractionsTable(this);
  late final EntriesDao entriesDao = EntriesDao(this as AppDatabase);
  late final ConceptMemosDao conceptMemosDao = ConceptMemosDao(
    this as AppDatabase,
  );
  late final DailyMemosDao dailyMemosDao = DailyMemosDao(this as AppDatabase);
  late final DictionariesDao dictionariesDao = DictionariesDao(
    this as AppDatabase,
  );
  late final PhilosophicalDialoguesDao philosophicalDialoguesDao =
      PhilosophicalDialoguesDao(this as AppDatabase);
  late final QuotesDao quotesDao = QuotesDao(this as AppDatabase);
  late final BooksDao booksDao = BooksDao(this as AppDatabase);
  late final ReadingMemosDao readingMemosDao = ReadingMemosDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    englishLexicons,
    entryAppendices,
    books,
    readingMemos,
    readingReflections,
    conceptDictionaries,
    conceptMemos,
    dailyMemos,
    dictionaryDefinitions,
    dictionaryFields,
    dictionaryEntries,
    dictionaryEntryValues,
    tags,
    entryTags,
    quotes,
    sources,
    entrySources,
    aISessions,
    philosophicalDialogues,
    philosophicalMessages,
    philosophicalConceptExtractions,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required EntryType type,
      required String title,
      required String body,
      Value<String?> genre,
      Value<DictionaryDomain> domain,
      Value<String> field,
      Value<int?> bookId,
      Value<String?> concept,
      Value<String> reading,
      Value<String> readingSource,
      Value<String> language,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<EntryType> type,
      Value<String> title,
      Value<String> body,
      Value<String?> genre,
      Value<DictionaryDomain> domain,
      Value<String> field,
      Value<int?> bookId,
      Value<String?> concept,
      Value<String> reading,
      Value<String> readingSource,
      Value<String> language,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EntryType, EntryType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DictionaryDomain, DictionaryDomain, int>
  get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concept => $composableBuilder(
    column: $table.concept,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingSource => $composableBuilder(
    column: $table.readingSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concept => $composableBuilder(
    column: $table.concept,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingSource => $composableBuilder(
    column: $table.readingSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EntryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DictionaryDomain, int> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<int> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get concept =>
      $composableBuilder(column: $table.concept, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get readingSource => $composableBuilder(
    column: $table.readingSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
          Entry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<EntryType> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<DictionaryDomain> domain = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<int?> bookId = const Value.absent(),
                Value<String?> concept = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> readingSource = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                type: type,
                title: title,
                body: body,
                genre: genre,
                domain: domain,
                field: field,
                bookId: bookId,
                concept: concept,
                reading: reading,
                readingSource: readingSource,
                language: language,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required EntryType type,
                required String title,
                required String body,
                Value<String?> genre = const Value.absent(),
                Value<DictionaryDomain> domain = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<int?> bookId = const Value.absent(),
                Value<String?> concept = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> readingSource = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                type: type,
                title: title,
                body: body,
                genre: genre,
                domain: domain,
                field: field,
                bookId: bookId,
                concept: concept,
                reading: reading,
                readingSource: readingSource,
                language: language,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, BaseReferences<_$AppDatabase, $EntriesTable, Entry>),
      Entry,
      PrefetchHooks Function()
    >;
typedef $$EnglishLexiconsTableCreateCompanionBuilder =
    EnglishLexiconsCompanion Function({
      Value<int> entryId,
      required String headword,
      required String language,
      required String ipa,
      Value<String> readingKana,
      required String pronunciationNote,
      required String partOfSpeech,
      required String countability,
      required String definitionEn,
      required String definitionJa,
      required String synonymsJson,
      required String antonymsJson,
      required String relatedTermsJson,
      required String examplesJson,
      required String phrasesJson,
      required String register,
      required String etymology,
      required String usageNote,
      Value<String> conceptMemo,
      Value<String> audioTtsText,
      Value<String> audioUrl,
      Value<String> audioNote,
    });
typedef $$EnglishLexiconsTableUpdateCompanionBuilder =
    EnglishLexiconsCompanion Function({
      Value<int> entryId,
      Value<String> headword,
      Value<String> language,
      Value<String> ipa,
      Value<String> readingKana,
      Value<String> pronunciationNote,
      Value<String> partOfSpeech,
      Value<String> countability,
      Value<String> definitionEn,
      Value<String> definitionJa,
      Value<String> synonymsJson,
      Value<String> antonymsJson,
      Value<String> relatedTermsJson,
      Value<String> examplesJson,
      Value<String> phrasesJson,
      Value<String> register,
      Value<String> etymology,
      Value<String> usageNote,
      Value<String> conceptMemo,
      Value<String> audioTtsText,
      Value<String> audioUrl,
      Value<String> audioNote,
    });

class $$EnglishLexiconsTableFilterComposer
    extends Composer<_$AppDatabase, $EnglishLexiconsTable> {
  $$EnglishLexiconsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipa => $composableBuilder(
    column: $table.ipa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readingKana => $composableBuilder(
    column: $table.readingKana,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciationNote => $composableBuilder(
    column: $table.pronunciationNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countability => $composableBuilder(
    column: $table.countability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definitionJa => $composableBuilder(
    column: $table.definitionJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedTermsJson => $composableBuilder(
    column: $table.relatedTermsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get register => $composableBuilder(
    column: $table.register,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etymology => $composableBuilder(
    column: $table.etymology,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usageNote => $composableBuilder(
    column: $table.usageNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptMemo => $composableBuilder(
    column: $table.conceptMemo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioTtsText => $composableBuilder(
    column: $table.audioTtsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioNote => $composableBuilder(
    column: $table.audioNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnglishLexiconsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnglishLexiconsTable> {
  $$EnglishLexiconsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipa => $composableBuilder(
    column: $table.ipa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readingKana => $composableBuilder(
    column: $table.readingKana,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciationNote => $composableBuilder(
    column: $table.pronunciationNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countability => $composableBuilder(
    column: $table.countability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definitionJa => $composableBuilder(
    column: $table.definitionJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedTermsJson => $composableBuilder(
    column: $table.relatedTermsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get register => $composableBuilder(
    column: $table.register,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etymology => $composableBuilder(
    column: $table.etymology,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usageNote => $composableBuilder(
    column: $table.usageNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptMemo => $composableBuilder(
    column: $table.conceptMemo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioTtsText => $composableBuilder(
    column: $table.audioTtsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioNote => $composableBuilder(
    column: $table.audioNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnglishLexiconsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnglishLexiconsTable> {
  $$EnglishLexiconsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get headword =>
      $composableBuilder(column: $table.headword, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get ipa =>
      $composableBuilder(column: $table.ipa, builder: (column) => column);

  GeneratedColumn<String> get readingKana => $composableBuilder(
    column: $table.readingKana,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pronunciationNote => $composableBuilder(
    column: $table.pronunciationNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countability => $composableBuilder(
    column: $table.countability,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionEn => $composableBuilder(
    column: $table.definitionEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definitionJa => $composableBuilder(
    column: $table.definitionJa,
    builder: (column) => column,
  );

  GeneratedColumn<String> get synonymsJson => $composableBuilder(
    column: $table.synonymsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get antonymsJson => $composableBuilder(
    column: $table.antonymsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedTermsJson => $composableBuilder(
    column: $table.relatedTermsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phrasesJson => $composableBuilder(
    column: $table.phrasesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get register =>
      $composableBuilder(column: $table.register, builder: (column) => column);

  GeneratedColumn<String> get etymology =>
      $composableBuilder(column: $table.etymology, builder: (column) => column);

  GeneratedColumn<String> get usageNote =>
      $composableBuilder(column: $table.usageNote, builder: (column) => column);

  GeneratedColumn<String> get conceptMemo => $composableBuilder(
    column: $table.conceptMemo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioTtsText => $composableBuilder(
    column: $table.audioTtsText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get audioNote =>
      $composableBuilder(column: $table.audioNote, builder: (column) => column);
}

class $$EnglishLexiconsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnglishLexiconsTable,
          EnglishLexicon,
          $$EnglishLexiconsTableFilterComposer,
          $$EnglishLexiconsTableOrderingComposer,
          $$EnglishLexiconsTableAnnotationComposer,
          $$EnglishLexiconsTableCreateCompanionBuilder,
          $$EnglishLexiconsTableUpdateCompanionBuilder,
          (
            EnglishLexicon,
            BaseReferences<
              _$AppDatabase,
              $EnglishLexiconsTable,
              EnglishLexicon
            >,
          ),
          EnglishLexicon,
          PrefetchHooks Function()
        > {
  $$EnglishLexiconsTableTableManager(
    _$AppDatabase db,
    $EnglishLexiconsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnglishLexiconsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnglishLexiconsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnglishLexiconsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                Value<String> headword = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> ipa = const Value.absent(),
                Value<String> readingKana = const Value.absent(),
                Value<String> pronunciationNote = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String> countability = const Value.absent(),
                Value<String> definitionEn = const Value.absent(),
                Value<String> definitionJa = const Value.absent(),
                Value<String> synonymsJson = const Value.absent(),
                Value<String> antonymsJson = const Value.absent(),
                Value<String> relatedTermsJson = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String> phrasesJson = const Value.absent(),
                Value<String> register = const Value.absent(),
                Value<String> etymology = const Value.absent(),
                Value<String> usageNote = const Value.absent(),
                Value<String> conceptMemo = const Value.absent(),
                Value<String> audioTtsText = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String> audioNote = const Value.absent(),
              }) => EnglishLexiconsCompanion(
                entryId: entryId,
                headword: headword,
                language: language,
                ipa: ipa,
                readingKana: readingKana,
                pronunciationNote: pronunciationNote,
                partOfSpeech: partOfSpeech,
                countability: countability,
                definitionEn: definitionEn,
                definitionJa: definitionJa,
                synonymsJson: synonymsJson,
                antonymsJson: antonymsJson,
                relatedTermsJson: relatedTermsJson,
                examplesJson: examplesJson,
                phrasesJson: phrasesJson,
                register: register,
                etymology: etymology,
                usageNote: usageNote,
                conceptMemo: conceptMemo,
                audioTtsText: audioTtsText,
                audioUrl: audioUrl,
                audioNote: audioNote,
              ),
          createCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                required String headword,
                required String language,
                required String ipa,
                Value<String> readingKana = const Value.absent(),
                required String pronunciationNote,
                required String partOfSpeech,
                required String countability,
                required String definitionEn,
                required String definitionJa,
                required String synonymsJson,
                required String antonymsJson,
                required String relatedTermsJson,
                required String examplesJson,
                required String phrasesJson,
                required String register,
                required String etymology,
                required String usageNote,
                Value<String> conceptMemo = const Value.absent(),
                Value<String> audioTtsText = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String> audioNote = const Value.absent(),
              }) => EnglishLexiconsCompanion.insert(
                entryId: entryId,
                headword: headword,
                language: language,
                ipa: ipa,
                readingKana: readingKana,
                pronunciationNote: pronunciationNote,
                partOfSpeech: partOfSpeech,
                countability: countability,
                definitionEn: definitionEn,
                definitionJa: definitionJa,
                synonymsJson: synonymsJson,
                antonymsJson: antonymsJson,
                relatedTermsJson: relatedTermsJson,
                examplesJson: examplesJson,
                phrasesJson: phrasesJson,
                register: register,
                etymology: etymology,
                usageNote: usageNote,
                conceptMemo: conceptMemo,
                audioTtsText: audioTtsText,
                audioUrl: audioUrl,
                audioNote: audioNote,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnglishLexiconsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnglishLexiconsTable,
      EnglishLexicon,
      $$EnglishLexiconsTableFilterComposer,
      $$EnglishLexiconsTableOrderingComposer,
      $$EnglishLexiconsTableAnnotationComposer,
      $$EnglishLexiconsTableCreateCompanionBuilder,
      $$EnglishLexiconsTableUpdateCompanionBuilder,
      (
        EnglishLexicon,
        BaseReferences<_$AppDatabase, $EnglishLexiconsTable, EnglishLexicon>,
      ),
      EnglishLexicon,
      PrefetchHooks Function()
    >;
typedef $$EntryAppendicesTableCreateCompanionBuilder =
    EntryAppendicesCompanion Function({
      Value<int> id,
      required int entryId,
      required AppendixType type,
      required String content,
      Value<DateTime> createdAt,
    });
typedef $$EntryAppendicesTableUpdateCompanionBuilder =
    EntryAppendicesCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<AppendixType> type,
      Value<String> content,
      Value<DateTime> createdAt,
    });

class $$EntryAppendicesTableFilterComposer
    extends Composer<_$AppDatabase, $EntryAppendicesTable> {
  $$EntryAppendicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AppendixType, AppendixType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryAppendicesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryAppendicesTable> {
  $$EntryAppendicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryAppendicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryAppendicesTable> {
  $$EntryAppendicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AppendixType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EntryAppendicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryAppendicesTable,
          EntryAppendix,
          $$EntryAppendicesTableFilterComposer,
          $$EntryAppendicesTableOrderingComposer,
          $$EntryAppendicesTableAnnotationComposer,
          $$EntryAppendicesTableCreateCompanionBuilder,
          $$EntryAppendicesTableUpdateCompanionBuilder,
          (
            EntryAppendix,
            BaseReferences<_$AppDatabase, $EntryAppendicesTable, EntryAppendix>,
          ),
          EntryAppendix,
          PrefetchHooks Function()
        > {
  $$EntryAppendicesTableTableManager(
    _$AppDatabase db,
    $EntryAppendicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryAppendicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryAppendicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryAppendicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<AppendixType> type = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntryAppendicesCompanion(
                id: id,
                entryId: entryId,
                type: type,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required AppendixType type,
                required String content,
                Value<DateTime> createdAt = const Value.absent(),
              }) => EntryAppendicesCompanion.insert(
                id: id,
                entryId: entryId,
                type: type,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryAppendicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryAppendicesTable,
      EntryAppendix,
      $$EntryAppendicesTableFilterComposer,
      $$EntryAppendicesTableOrderingComposer,
      $$EntryAppendicesTableAnnotationComposer,
      $$EntryAppendicesTableCreateCompanionBuilder,
      $$EntryAppendicesTableUpdateCompanionBuilder,
      (
        EntryAppendix,
        BaseReferences<_$AppDatabase, $EntryAppendicesTable, EntryAppendix>,
      ),
      EntryAppendix,
      PrefetchHooks Function()
    >;
typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      required String title,
      required String author,
      Value<String?> genre,
      Value<String?> publisher,
      Value<String?> publishedDate,
      Value<String?> isbn,
      Value<String?> synopsis,
      Value<String?> rating,
      Value<String?> relatedUrl,
      Value<String?> reviewSummary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> author,
      Value<String?> genre,
      Value<String?> publisher,
      Value<String?> publishedDate,
      Value<String?> isbn,
      Value<String?> synopsis,
      Value<String?> rating,
      Value<String?> relatedUrl,
      Value<String?> reviewSummary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedUrl => $composableBuilder(
    column: $table.relatedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewSummary => $composableBuilder(
    column: $table.reviewSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedUrl => $composableBuilder(
    column: $table.relatedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewSummary => $composableBuilder(
    column: $table.reviewSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get relatedUrl => $composableBuilder(
    column: $table.relatedUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewSummary => $composableBuilder(
    column: $table.reviewSummary,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
          Book,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> relatedUrl = const Value.absent(),
                Value<String?> reviewSummary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                author: author,
                genre: genre,
                publisher: publisher,
                publishedDate: publishedDate,
                isbn: isbn,
                synopsis: synopsis,
                rating: rating,
                relatedUrl: relatedUrl,
                reviewSummary: reviewSummary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String author,
                Value<String?> genre = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<String?> relatedUrl = const Value.absent(),
                Value<String?> reviewSummary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                author: author,
                genre: genre,
                publisher: publisher,
                publishedDate: publishedDate,
                isbn: isbn,
                synopsis: synopsis,
                rating: rating,
                relatedUrl: relatedUrl,
                reviewSummary: reviewSummary,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
      Book,
      PrefetchHooks Function()
    >;
typedef $$ReadingMemosTableCreateCompanionBuilder =
    ReadingMemosCompanion Function({
      Value<int> id,
      required int bookId,
      required String content,
      Value<String?> sectionTitle,
      Value<String?> pageNumber,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$ReadingMemosTableUpdateCompanionBuilder =
    ReadingMemosCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<String> content,
      Value<String?> sectionTitle,
      Value<String?> pageNumber,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$ReadingMemosTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingMemosTable> {
  $$ReadingMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingMemosTable> {
  $$ReadingMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingMemosTable> {
  $$ReadingMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReadingMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingMemosTable,
          ReadingMemo,
          $$ReadingMemosTableFilterComposer,
          $$ReadingMemosTableOrderingComposer,
          $$ReadingMemosTableAnnotationComposer,
          $$ReadingMemosTableCreateCompanionBuilder,
          $$ReadingMemosTableUpdateCompanionBuilder,
          (
            ReadingMemo,
            BaseReferences<_$AppDatabase, $ReadingMemosTable, ReadingMemo>,
          ),
          ReadingMemo,
          PrefetchHooks Function()
        > {
  $$ReadingMemosTableTableManager(_$AppDatabase db, $ReadingMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> sectionTitle = const Value.absent(),
                Value<String?> pageNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ReadingMemosCompanion(
                id: id,
                bookId: bookId,
                content: content,
                sectionTitle: sectionTitle,
                pageNumber: pageNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String content,
                Value<String?> sectionTitle = const Value.absent(),
                Value<String?> pageNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => ReadingMemosCompanion.insert(
                id: id,
                bookId: bookId,
                content: content,
                sectionTitle: sectionTitle,
                pageNumber: pageNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingMemosTable,
      ReadingMemo,
      $$ReadingMemosTableFilterComposer,
      $$ReadingMemosTableOrderingComposer,
      $$ReadingMemosTableAnnotationComposer,
      $$ReadingMemosTableCreateCompanionBuilder,
      $$ReadingMemosTableUpdateCompanionBuilder,
      (
        ReadingMemo,
        BaseReferences<_$AppDatabase, $ReadingMemosTable, ReadingMemo>,
      ),
      ReadingMemo,
      PrefetchHooks Function()
    >;
typedef $$ReadingReflectionsTableCreateCompanionBuilder =
    ReadingReflectionsCompanion Function({
      Value<int> id,
      required int bookId,
      required String content,
      Value<DateTime> createdAt,
    });
typedef $$ReadingReflectionsTableUpdateCompanionBuilder =
    ReadingReflectionsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<String> content,
      Value<DateTime> createdAt,
    });

class $$ReadingReflectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingReflectionsTable> {
  $$ReadingReflectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingReflectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingReflectionsTable> {
  $$ReadingReflectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingReflectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingReflectionsTable> {
  $$ReadingReflectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReadingReflectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingReflectionsTable,
          ReadingReflection,
          $$ReadingReflectionsTableFilterComposer,
          $$ReadingReflectionsTableOrderingComposer,
          $$ReadingReflectionsTableAnnotationComposer,
          $$ReadingReflectionsTableCreateCompanionBuilder,
          $$ReadingReflectionsTableUpdateCompanionBuilder,
          (
            ReadingReflection,
            BaseReferences<
              _$AppDatabase,
              $ReadingReflectionsTable,
              ReadingReflection
            >,
          ),
          ReadingReflection,
          PrefetchHooks Function()
        > {
  $$ReadingReflectionsTableTableManager(
    _$AppDatabase db,
    $ReadingReflectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingReflectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingReflectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingReflectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingReflectionsCompanion(
                id: id,
                bookId: bookId,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String content,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadingReflectionsCompanion.insert(
                id: id,
                bookId: bookId,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingReflectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingReflectionsTable,
      ReadingReflection,
      $$ReadingReflectionsTableFilterComposer,
      $$ReadingReflectionsTableOrderingComposer,
      $$ReadingReflectionsTableAnnotationComposer,
      $$ReadingReflectionsTableCreateCompanionBuilder,
      $$ReadingReflectionsTableUpdateCompanionBuilder,
      (
        ReadingReflection,
        BaseReferences<
          _$AppDatabase,
          $ReadingReflectionsTable,
          ReadingReflection
        >,
      ),
      ReadingReflection,
      PrefetchHooks Function()
    >;
typedef $$ConceptDictionariesTableCreateCompanionBuilder =
    ConceptDictionariesCompanion Function({
      Value<int> id,
      required String title,
      required String body,
      Value<String?> category,
      Value<String?> tags,
      Value<String?> memo,
      Value<String?> referenceUrls,
      Value<String?> similarConcepts,
      Value<String?> contrastingConcepts,
      Value<String?> relatedConcepts,
      Value<String?> culturalBackground,
      Value<String?> practicalAdvice,
      Value<String?> caseStudies,
      Value<String?> gyaruExplanation,
      Value<String?> childExplanation,
      Value<ConceptOrigin> origin,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ConceptDictionariesTableUpdateCompanionBuilder =
    ConceptDictionariesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> body,
      Value<String?> category,
      Value<String?> tags,
      Value<String?> memo,
      Value<String?> referenceUrls,
      Value<String?> similarConcepts,
      Value<String?> contrastingConcepts,
      Value<String?> relatedConcepts,
      Value<String?> culturalBackground,
      Value<String?> practicalAdvice,
      Value<String?> caseStudies,
      Value<String?> gyaruExplanation,
      Value<String?> childExplanation,
      Value<ConceptOrigin> origin,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ConceptDictionariesTableFilterComposer
    extends Composer<_$AppDatabase, $ConceptDictionariesTable> {
  $$ConceptDictionariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceUrls => $composableBuilder(
    column: $table.referenceUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get similarConcepts => $composableBuilder(
    column: $table.similarConcepts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contrastingConcepts => $composableBuilder(
    column: $table.contrastingConcepts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedConcepts => $composableBuilder(
    column: $table.relatedConcepts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get culturalBackground => $composableBuilder(
    column: $table.culturalBackground,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get practicalAdvice => $composableBuilder(
    column: $table.practicalAdvice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caseStudies => $composableBuilder(
    column: $table.caseStudies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gyaruExplanation => $composableBuilder(
    column: $table.gyaruExplanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get childExplanation => $composableBuilder(
    column: $table.childExplanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConceptOrigin, ConceptOrigin, int>
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConceptDictionariesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConceptDictionariesTable> {
  $$ConceptDictionariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceUrls => $composableBuilder(
    column: $table.referenceUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get similarConcepts => $composableBuilder(
    column: $table.similarConcepts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contrastingConcepts => $composableBuilder(
    column: $table.contrastingConcepts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedConcepts => $composableBuilder(
    column: $table.relatedConcepts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get culturalBackground => $composableBuilder(
    column: $table.culturalBackground,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get practicalAdvice => $composableBuilder(
    column: $table.practicalAdvice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caseStudies => $composableBuilder(
    column: $table.caseStudies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gyaruExplanation => $composableBuilder(
    column: $table.gyaruExplanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get childExplanation => $composableBuilder(
    column: $table.childExplanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConceptDictionariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConceptDictionariesTable> {
  $$ConceptDictionariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get referenceUrls => $composableBuilder(
    column: $table.referenceUrls,
    builder: (column) => column,
  );

  GeneratedColumn<String> get similarConcepts => $composableBuilder(
    column: $table.similarConcepts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contrastingConcepts => $composableBuilder(
    column: $table.contrastingConcepts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedConcepts => $composableBuilder(
    column: $table.relatedConcepts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get culturalBackground => $composableBuilder(
    column: $table.culturalBackground,
    builder: (column) => column,
  );

  GeneratedColumn<String> get practicalAdvice => $composableBuilder(
    column: $table.practicalAdvice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caseStudies => $composableBuilder(
    column: $table.caseStudies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gyaruExplanation => $composableBuilder(
    column: $table.gyaruExplanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get childExplanation => $composableBuilder(
    column: $table.childExplanation,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ConceptOrigin, int> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConceptDictionariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConceptDictionariesTable,
          ConceptDictionary,
          $$ConceptDictionariesTableFilterComposer,
          $$ConceptDictionariesTableOrderingComposer,
          $$ConceptDictionariesTableAnnotationComposer,
          $$ConceptDictionariesTableCreateCompanionBuilder,
          $$ConceptDictionariesTableUpdateCompanionBuilder,
          (
            ConceptDictionary,
            BaseReferences<
              _$AppDatabase,
              $ConceptDictionariesTable,
              ConceptDictionary
            >,
          ),
          ConceptDictionary,
          PrefetchHooks Function()
        > {
  $$ConceptDictionariesTableTableManager(
    _$AppDatabase db,
    $ConceptDictionariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptDictionariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptDictionariesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConceptDictionariesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> referenceUrls = const Value.absent(),
                Value<String?> similarConcepts = const Value.absent(),
                Value<String?> contrastingConcepts = const Value.absent(),
                Value<String?> relatedConcepts = const Value.absent(),
                Value<String?> culturalBackground = const Value.absent(),
                Value<String?> practicalAdvice = const Value.absent(),
                Value<String?> caseStudies = const Value.absent(),
                Value<String?> gyaruExplanation = const Value.absent(),
                Value<String?> childExplanation = const Value.absent(),
                Value<ConceptOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConceptDictionariesCompanion(
                id: id,
                title: title,
                body: body,
                category: category,
                tags: tags,
                memo: memo,
                referenceUrls: referenceUrls,
                similarConcepts: similarConcepts,
                contrastingConcepts: contrastingConcepts,
                relatedConcepts: relatedConcepts,
                culturalBackground: culturalBackground,
                practicalAdvice: practicalAdvice,
                caseStudies: caseStudies,
                gyaruExplanation: gyaruExplanation,
                childExplanation: childExplanation,
                origin: origin,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String body,
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> referenceUrls = const Value.absent(),
                Value<String?> similarConcepts = const Value.absent(),
                Value<String?> contrastingConcepts = const Value.absent(),
                Value<String?> relatedConcepts = const Value.absent(),
                Value<String?> culturalBackground = const Value.absent(),
                Value<String?> practicalAdvice = const Value.absent(),
                Value<String?> caseStudies = const Value.absent(),
                Value<String?> gyaruExplanation = const Value.absent(),
                Value<String?> childExplanation = const Value.absent(),
                Value<ConceptOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConceptDictionariesCompanion.insert(
                id: id,
                title: title,
                body: body,
                category: category,
                tags: tags,
                memo: memo,
                referenceUrls: referenceUrls,
                similarConcepts: similarConcepts,
                contrastingConcepts: contrastingConcepts,
                relatedConcepts: relatedConcepts,
                culturalBackground: culturalBackground,
                practicalAdvice: practicalAdvice,
                caseStudies: caseStudies,
                gyaruExplanation: gyaruExplanation,
                childExplanation: childExplanation,
                origin: origin,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConceptDictionariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConceptDictionariesTable,
      ConceptDictionary,
      $$ConceptDictionariesTableFilterComposer,
      $$ConceptDictionariesTableOrderingComposer,
      $$ConceptDictionariesTableAnnotationComposer,
      $$ConceptDictionariesTableCreateCompanionBuilder,
      $$ConceptDictionariesTableUpdateCompanionBuilder,
      (
        ConceptDictionary,
        BaseReferences<
          _$AppDatabase,
          $ConceptDictionariesTable,
          ConceptDictionary
        >,
      ),
      ConceptDictionary,
      PrefetchHooks Function()
    >;
typedef $$ConceptMemosTableCreateCompanionBuilder =
    ConceptMemosCompanion Function({
      Value<int> id,
      Value<String?> title,
      required String content,
      Value<String?> summary,
      Value<String> extractedJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ConceptMemosTableUpdateCompanionBuilder =
    ConceptMemosCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String> content,
      Value<String?> summary,
      Value<String> extractedJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ConceptMemosTableFilterComposer
    extends Composer<_$AppDatabase, $ConceptMemosTable> {
  $$ConceptMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedJson => $composableBuilder(
    column: $table.extractedJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConceptMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $ConceptMemosTable> {
  $$ConceptMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedJson => $composableBuilder(
    column: $table.extractedJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConceptMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConceptMemosTable> {
  $$ConceptMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get extractedJson => $composableBuilder(
    column: $table.extractedJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConceptMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConceptMemosTable,
          ConceptMemo,
          $$ConceptMemosTableFilterComposer,
          $$ConceptMemosTableOrderingComposer,
          $$ConceptMemosTableAnnotationComposer,
          $$ConceptMemosTableCreateCompanionBuilder,
          $$ConceptMemosTableUpdateCompanionBuilder,
          (
            ConceptMemo,
            BaseReferences<_$AppDatabase, $ConceptMemosTable, ConceptMemo>,
          ),
          ConceptMemo,
          PrefetchHooks Function()
        > {
  $$ConceptMemosTableTableManager(_$AppDatabase db, $ConceptMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConceptMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConceptMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConceptMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String> extractedJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConceptMemosCompanion(
                id: id,
                title: title,
                content: content,
                summary: summary,
                extractedJson: extractedJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required String content,
                Value<String?> summary = const Value.absent(),
                Value<String> extractedJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ConceptMemosCompanion.insert(
                id: id,
                title: title,
                content: content,
                summary: summary,
                extractedJson: extractedJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConceptMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConceptMemosTable,
      ConceptMemo,
      $$ConceptMemosTableFilterComposer,
      $$ConceptMemosTableOrderingComposer,
      $$ConceptMemosTableAnnotationComposer,
      $$ConceptMemosTableCreateCompanionBuilder,
      $$ConceptMemosTableUpdateCompanionBuilder,
      (
        ConceptMemo,
        BaseReferences<_$AppDatabase, $ConceptMemosTable, ConceptMemo>,
      ),
      ConceptMemo,
      PrefetchHooks Function()
    >;
typedef $$DailyMemosTableCreateCompanionBuilder =
    DailyMemosCompanion Function({
      Value<int> id,
      Value<String?> title,
      required String content,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DailyMemosTableUpdateCompanionBuilder =
    DailyMemosCompanion Function({
      Value<int> id,
      Value<String?> title,
      Value<String> content,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DailyMemosTableFilterComposer
    extends Composer<_$AppDatabase, $DailyMemosTable> {
  $$DailyMemosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyMemosTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyMemosTable> {
  $$DailyMemosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyMemosTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyMemosTable> {
  $$DailyMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyMemosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyMemosTable,
          DailyMemo,
          $$DailyMemosTableFilterComposer,
          $$DailyMemosTableOrderingComposer,
          $$DailyMemosTableAnnotationComposer,
          $$DailyMemosTableCreateCompanionBuilder,
          $$DailyMemosTableUpdateCompanionBuilder,
          (
            DailyMemo,
            BaseReferences<_$AppDatabase, $DailyMemosTable, DailyMemo>,
          ),
          DailyMemo,
          PrefetchHooks Function()
        > {
  $$DailyMemosTableTableManager(_$AppDatabase db, $DailyMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyMemosCompanion(
                id: id,
                title: title,
                content: content,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required String content,
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DailyMemosCompanion.insert(
                id: id,
                title: title,
                content: content,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyMemosTable,
      DailyMemo,
      $$DailyMemosTableFilterComposer,
      $$DailyMemosTableOrderingComposer,
      $$DailyMemosTableAnnotationComposer,
      $$DailyMemosTableCreateCompanionBuilder,
      $$DailyMemosTableUpdateCompanionBuilder,
      (DailyMemo, BaseReferences<_$AppDatabase, $DailyMemosTable, DailyMemo>),
      DailyMemo,
      PrefetchHooks Function()
    >;
typedef $$DictionaryDefinitionsTableCreateCompanionBuilder =
    DictionaryDefinitionsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<bool> isSystem,
      Value<bool> isWork,
      Value<String?> category,
      Value<String?> recommendedTags,
      Value<String?> recommendedCategories,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DictionaryDefinitionsTableUpdateCompanionBuilder =
    DictionaryDefinitionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> isSystem,
      Value<bool> isWork,
      Value<String?> category,
      Value<String?> recommendedTags,
      Value<String?> recommendedCategories,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DictionaryDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryDefinitionsTable> {
  $$DictionaryDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWork => $composableBuilder(
    column: $table.isWork,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedTags => $composableBuilder(
    column: $table.recommendedTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedCategories => $composableBuilder(
    column: $table.recommendedCategories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryDefinitionsTable> {
  $$DictionaryDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWork => $composableBuilder(
    column: $table.isWork,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedTags => $composableBuilder(
    column: $table.recommendedTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedCategories => $composableBuilder(
    column: $table.recommendedCategories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryDefinitionsTable> {
  $$DictionaryDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<bool> get isWork =>
      $composableBuilder(column: $table.isWork, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get recommendedTags => $composableBuilder(
    column: $table.recommendedTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedCategories => $composableBuilder(
    column: $table.recommendedCategories,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DictionaryDefinitionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryDefinitionsTable,
          DictionaryDefinition,
          $$DictionaryDefinitionsTableFilterComposer,
          $$DictionaryDefinitionsTableOrderingComposer,
          $$DictionaryDefinitionsTableAnnotationComposer,
          $$DictionaryDefinitionsTableCreateCompanionBuilder,
          $$DictionaryDefinitionsTableUpdateCompanionBuilder,
          (
            DictionaryDefinition,
            BaseReferences<
              _$AppDatabase,
              $DictionaryDefinitionsTable,
              DictionaryDefinition
            >,
          ),
          DictionaryDefinition,
          PrefetchHooks Function()
        > {
  $$DictionaryDefinitionsTableTableManager(
    _$AppDatabase db,
    $DictionaryDefinitionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryDefinitionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryDefinitionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryDefinitionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<bool> isWork = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> recommendedTags = const Value.absent(),
                Value<String?> recommendedCategories = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryDefinitionsCompanion(
                id: id,
                name: name,
                description: description,
                isSystem: isSystem,
                isWork: isWork,
                category: category,
                recommendedTags: recommendedTags,
                recommendedCategories: recommendedCategories,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<bool> isWork = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> recommendedTags = const Value.absent(),
                Value<String?> recommendedCategories = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryDefinitionsCompanion.insert(
                id: id,
                name: name,
                description: description,
                isSystem: isSystem,
                isWork: isWork,
                category: category,
                recommendedTags: recommendedTags,
                recommendedCategories: recommendedCategories,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryDefinitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryDefinitionsTable,
      DictionaryDefinition,
      $$DictionaryDefinitionsTableFilterComposer,
      $$DictionaryDefinitionsTableOrderingComposer,
      $$DictionaryDefinitionsTableAnnotationComposer,
      $$DictionaryDefinitionsTableCreateCompanionBuilder,
      $$DictionaryDefinitionsTableUpdateCompanionBuilder,
      (
        DictionaryDefinition,
        BaseReferences<
          _$AppDatabase,
          $DictionaryDefinitionsTable,
          DictionaryDefinition
        >,
      ),
      DictionaryDefinition,
      PrefetchHooks Function()
    >;
typedef $$DictionaryFieldsTableCreateCompanionBuilder =
    DictionaryFieldsCompanion Function({
      Value<int> id,
      required int dictionaryId,
      required String fieldKey,
      required String label,
      required DictionaryFieldType fieldType,
      Value<bool> isRequired,
      Value<bool> isEnabled,
      Value<int> sortOrder,
    });
typedef $$DictionaryFieldsTableUpdateCompanionBuilder =
    DictionaryFieldsCompanion Function({
      Value<int> id,
      Value<int> dictionaryId,
      Value<String> fieldKey,
      Value<String> label,
      Value<DictionaryFieldType> fieldType,
      Value<bool> isRequired,
      Value<bool> isEnabled,
      Value<int> sortOrder,
    });

class $$DictionaryFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryFieldsTable> {
  $$DictionaryFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DictionaryFieldType, DictionaryFieldType, int>
  get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryFieldsTable> {
  $$DictionaryFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fieldType => $composableBuilder(
    column: $table.fieldType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryFieldsTable> {
  $$DictionaryFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DictionaryFieldType, int> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DictionaryFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryFieldsTable,
          DictionaryField,
          $$DictionaryFieldsTableFilterComposer,
          $$DictionaryFieldsTableOrderingComposer,
          $$DictionaryFieldsTableAnnotationComposer,
          $$DictionaryFieldsTableCreateCompanionBuilder,
          $$DictionaryFieldsTableUpdateCompanionBuilder,
          (
            DictionaryField,
            BaseReferences<
              _$AppDatabase,
              $DictionaryFieldsTable,
              DictionaryField
            >,
          ),
          DictionaryField,
          PrefetchHooks Function()
        > {
  $$DictionaryFieldsTableTableManager(
    _$AppDatabase db,
    $DictionaryFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryFieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<DictionaryFieldType> fieldType = const Value.absent(),
                Value<bool> isRequired = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => DictionaryFieldsCompanion(
                id: id,
                dictionaryId: dictionaryId,
                fieldKey: fieldKey,
                label: label,
                fieldType: fieldType,
                isRequired: isRequired,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictionaryId,
                required String fieldKey,
                required String label,
                required DictionaryFieldType fieldType,
                Value<bool> isRequired = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => DictionaryFieldsCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                fieldKey: fieldKey,
                label: label,
                fieldType: fieldType,
                isRequired: isRequired,
                isEnabled: isEnabled,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryFieldsTable,
      DictionaryField,
      $$DictionaryFieldsTableFilterComposer,
      $$DictionaryFieldsTableOrderingComposer,
      $$DictionaryFieldsTableAnnotationComposer,
      $$DictionaryFieldsTableCreateCompanionBuilder,
      $$DictionaryFieldsTableUpdateCompanionBuilder,
      (
        DictionaryField,
        BaseReferences<_$AppDatabase, $DictionaryFieldsTable, DictionaryField>,
      ),
      DictionaryField,
      PrefetchHooks Function()
    >;
typedef $$DictionaryEntriesTableCreateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      Value<int> id,
      required int dictionaryId,
      required String headword,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DictionaryEntriesTableUpdateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      Value<int> id,
      Value<int> dictionaryId,
      Value<String> headword,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DictionaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headword => $composableBuilder(
    column: $table.headword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dictionaryId => $composableBuilder(
    column: $table.dictionaryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headword =>
      $composableBuilder(column: $table.headword, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DictionaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryEntriesTable,
          DictionaryEntry,
          $$DictionaryEntriesTableFilterComposer,
          $$DictionaryEntriesTableOrderingComposer,
          $$DictionaryEntriesTableAnnotationComposer,
          $$DictionaryEntriesTableCreateCompanionBuilder,
          $$DictionaryEntriesTableUpdateCompanionBuilder,
          (
            DictionaryEntry,
            BaseReferences<
              _$AppDatabase,
              $DictionaryEntriesTable,
              DictionaryEntry
            >,
          ),
          DictionaryEntry,
          PrefetchHooks Function()
        > {
  $$DictionaryEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dictionaryId = const Value.absent(),
                Value<String> headword = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryEntriesCompanion(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dictionaryId,
                required String headword,
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryEntriesCompanion.insert(
                id: id,
                dictionaryId: dictionaryId,
                headword: headword,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryEntriesTable,
      DictionaryEntry,
      $$DictionaryEntriesTableFilterComposer,
      $$DictionaryEntriesTableOrderingComposer,
      $$DictionaryEntriesTableAnnotationComposer,
      $$DictionaryEntriesTableCreateCompanionBuilder,
      $$DictionaryEntriesTableUpdateCompanionBuilder,
      (
        DictionaryEntry,
        BaseReferences<_$AppDatabase, $DictionaryEntriesTable, DictionaryEntry>,
      ),
      DictionaryEntry,
      PrefetchHooks Function()
    >;
typedef $$DictionaryEntryValuesTableCreateCompanionBuilder =
    DictionaryEntryValuesCompanion Function({
      Value<int> id,
      required int entryId,
      required int fieldId,
      required String value,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$DictionaryEntryValuesTableUpdateCompanionBuilder =
    DictionaryEntryValuesCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<int> fieldId,
      Value<String> value,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$DictionaryEntryValuesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryEntryValuesTable> {
  $$DictionaryEntryValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryEntryValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryEntryValuesTable> {
  $$DictionaryEntryValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fieldId => $composableBuilder(
    column: $table.fieldId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryEntryValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryEntryValuesTable> {
  $$DictionaryEntryValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DictionaryEntryValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryEntryValuesTable,
          DictionaryEntryValue,
          $$DictionaryEntryValuesTableFilterComposer,
          $$DictionaryEntryValuesTableOrderingComposer,
          $$DictionaryEntryValuesTableAnnotationComposer,
          $$DictionaryEntryValuesTableCreateCompanionBuilder,
          $$DictionaryEntryValuesTableUpdateCompanionBuilder,
          (
            DictionaryEntryValue,
            BaseReferences<
              _$AppDatabase,
              $DictionaryEntryValuesTable,
              DictionaryEntryValue
            >,
          ),
          DictionaryEntryValue,
          PrefetchHooks Function()
        > {
  $$DictionaryEntryValuesTableTableManager(
    _$AppDatabase db,
    $DictionaryEntryValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryEntryValuesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryEntryValuesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryEntryValuesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<int> fieldId = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryEntryValuesCompanion(
                id: id,
                entryId: entryId,
                fieldId: fieldId,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required int fieldId,
                required String value,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DictionaryEntryValuesCompanion.insert(
                id: id,
                entryId: entryId,
                fieldId: fieldId,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryEntryValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryEntryValuesTable,
      DictionaryEntryValue,
      $$DictionaryEntryValuesTableFilterComposer,
      $$DictionaryEntryValuesTableOrderingComposer,
      $$DictionaryEntryValuesTableAnnotationComposer,
      $$DictionaryEntryValuesTableCreateCompanionBuilder,
      $$DictionaryEntryValuesTableUpdateCompanionBuilder,
      (
        DictionaryEntryValue,
        BaseReferences<
          _$AppDatabase,
          $DictionaryEntryValuesTable,
          DictionaryEntryValue
        >,
      ),
      DictionaryEntryValue,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$EntryTagsTableCreateCompanionBuilder =
    EntryTagsCompanion Function({
      required int entryId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$EntryTagsTableUpdateCompanionBuilder =
    EntryTagsCompanion Function({
      Value<int> entryId,
      Value<int> tagId,
      Value<int> rowid,
    });

class $$EntryTagsTableFilterComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntryTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntryTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntryTagsTable> {
  $$EntryTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$EntryTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntryTagsTable,
          EntryTag,
          $$EntryTagsTableFilterComposer,
          $$EntryTagsTableOrderingComposer,
          $$EntryTagsTableAnnotationComposer,
          $$EntryTagsTableCreateCompanionBuilder,
          $$EntryTagsTableUpdateCompanionBuilder,
          (EntryTag, BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTag>),
          EntryTag,
          PrefetchHooks Function()
        > {
  $$EntryTagsTableTableManager(_$AppDatabase db, $EntryTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int entryId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntryTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntryTagsTable,
      EntryTag,
      $$EntryTagsTableFilterComposer,
      $$EntryTagsTableOrderingComposer,
      $$EntryTagsTableAnnotationComposer,
      $$EntryTagsTableCreateCompanionBuilder,
      $$EntryTagsTableUpdateCompanionBuilder,
      (EntryTag, BaseReferences<_$AppDatabase, $EntryTagsTable, EntryTag>),
      EntryTag,
      PrefetchHooks Function()
    >;
typedef $$QuotesTableCreateCompanionBuilder =
    QuotesCompanion Function({
      Value<int> id,
      required int entryId,
      required String quoteText,
      Value<String?> pageOrLoc,
      Value<String?> sectionTitle,
      Value<String?> note,
      Value<String?> sourceImagePath,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });
typedef $$QuotesTableUpdateCompanionBuilder =
    QuotesCompanion Function({
      Value<int> id,
      Value<int> entryId,
      Value<String> quoteText,
      Value<String?> pageOrLoc,
      Value<String?> sectionTitle,
      Value<String?> note,
      Value<String?> sourceImagePath,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
    });

class $$QuotesTableFilterComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageOrLoc => $composableBuilder(
    column: $table.pageOrLoc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteText => $composableBuilder(
    column: $table.quoteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageOrLoc => $composableBuilder(
    column: $table.pageOrLoc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get quoteText =>
      $composableBuilder(column: $table.quoteText, builder: (column) => column);

  GeneratedColumn<String> get pageOrLoc =>
      $composableBuilder(column: $table.pageOrLoc, builder: (column) => column);

  GeneratedColumn<String> get sectionTitle => $composableBuilder(
    column: $table.sectionTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get sourceImagePath => $composableBuilder(
    column: $table.sourceImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuotesTable,
          Quote,
          $$QuotesTableFilterComposer,
          $$QuotesTableOrderingComposer,
          $$QuotesTableAnnotationComposer,
          $$QuotesTableCreateCompanionBuilder,
          $$QuotesTableUpdateCompanionBuilder,
          (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
          Quote,
          PrefetchHooks Function()
        > {
  $$QuotesTableTableManager(_$AppDatabase db, $QuotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> entryId = const Value.absent(),
                Value<String> quoteText = const Value.absent(),
                Value<String?> pageOrLoc = const Value.absent(),
                Value<String?> sectionTitle = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> sourceImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => QuotesCompanion(
                id: id,
                entryId: entryId,
                quoteText: quoteText,
                pageOrLoc: pageOrLoc,
                sectionTitle: sectionTitle,
                note: note,
                sourceImagePath: sourceImagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int entryId,
                required String quoteText,
                Value<String?> pageOrLoc = const Value.absent(),
                Value<String?> sectionTitle = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> sourceImagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
              }) => QuotesCompanion.insert(
                id: id,
                entryId: entryId,
                quoteText: quoteText,
                pageOrLoc: pageOrLoc,
                sectionTitle: sectionTitle,
                note: note,
                sourceImagePath: sourceImagePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuotesTable,
      Quote,
      $$QuotesTableFilterComposer,
      $$QuotesTableOrderingComposer,
      $$QuotesTableAnnotationComposer,
      $$QuotesTableCreateCompanionBuilder,
      $$QuotesTableUpdateCompanionBuilder,
      (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
      Quote,
      PrefetchHooks Function()
    >;
typedef $$SourcesTableCreateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      Value<String?> url,
      Value<String?> title,
      Value<String?> note,
    });
typedef $$SourcesTableUpdateCompanionBuilder =
    SourcesCompanion Function({
      Value<int> id,
      Value<String?> url,
      Value<String?> title,
      Value<String?> note,
    });

class $$SourcesTableFilterComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourcesTable,
          Source,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
          Source,
          PrefetchHooks Function()
        > {
  $$SourcesTableTableManager(_$AppDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) =>
                  SourcesCompanion(id: id, url: url, title: title, note: note),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                url: url,
                title: title,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourcesTable,
      Source,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (Source, BaseReferences<_$AppDatabase, $SourcesTable, Source>),
      Source,
      PrefetchHooks Function()
    >;
typedef $$EntrySourcesTableCreateCompanionBuilder =
    EntrySourcesCompanion Function({
      required int entryId,
      required int sourceId,
      Value<int> rowid,
    });
typedef $$EntrySourcesTableUpdateCompanionBuilder =
    EntrySourcesCompanion Function({
      Value<int> entryId,
      Value<int> sourceId,
      Value<int> rowid,
    });

class $$EntrySourcesTableFilterComposer
    extends Composer<_$AppDatabase, $EntrySourcesTable> {
  $$EntrySourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntrySourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntrySourcesTable> {
  $$EntrySourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntrySourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntrySourcesTable> {
  $$EntrySourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<int> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$EntrySourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntrySourcesTable,
          EntrySource,
          $$EntrySourcesTableFilterComposer,
          $$EntrySourcesTableOrderingComposer,
          $$EntrySourcesTableAnnotationComposer,
          $$EntrySourcesTableCreateCompanionBuilder,
          $$EntrySourcesTableUpdateCompanionBuilder,
          (
            EntrySource,
            BaseReferences<_$AppDatabase, $EntrySourcesTable, EntrySource>,
          ),
          EntrySource,
          PrefetchHooks Function()
        > {
  $$EntrySourcesTableTableManager(_$AppDatabase db, $EntrySourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntrySourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntrySourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntrySourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> entryId = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntrySourcesCompanion(
                entryId: entryId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int entryId,
                required int sourceId,
                Value<int> rowid = const Value.absent(),
              }) => EntrySourcesCompanion.insert(
                entryId: entryId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntrySourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntrySourcesTable,
      EntrySource,
      $$EntrySourcesTableFilterComposer,
      $$EntrySourcesTableOrderingComposer,
      $$EntrySourcesTableAnnotationComposer,
      $$EntrySourcesTableCreateCompanionBuilder,
      $$EntrySourcesTableUpdateCompanionBuilder,
      (
        EntrySource,
        BaseReferences<_$AppDatabase, $EntrySourcesTable, EntrySource>,
      ),
      EntrySource,
      PrefetchHooks Function()
    >;
typedef $$AISessionsTableCreateCompanionBuilder =
    AISessionsCompanion Function({
      Value<int> id,
      required String subjectType,
      required int subjectId,
      required String role,
      required String content,
      Value<DateTime> createdAt,
    });
typedef $$AISessionsTableUpdateCompanionBuilder =
    AISessionsCompanion Function({
      Value<int> id,
      Value<String> subjectType,
      Value<int> subjectId,
      Value<String> role,
      Value<String> content,
      Value<DateTime> createdAt,
    });

class $$AISessionsTableFilterComposer
    extends Composer<_$AppDatabase, $AISessionsTable> {
  $$AISessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AISessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AISessionsTable> {
  $$AISessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AISessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AISessionsTable> {
  $$AISessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectType => $composableBuilder(
    column: $table.subjectType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AISessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AISessionsTable,
          AISession,
          $$AISessionsTableFilterComposer,
          $$AISessionsTableOrderingComposer,
          $$AISessionsTableAnnotationComposer,
          $$AISessionsTableCreateCompanionBuilder,
          $$AISessionsTableUpdateCompanionBuilder,
          (
            AISession,
            BaseReferences<_$AppDatabase, $AISessionsTable, AISession>,
          ),
          AISession,
          PrefetchHooks Function()
        > {
  $$AISessionsTableTableManager(_$AppDatabase db, $AISessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AISessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AISessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AISessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> subjectType = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AISessionsCompanion(
                id: id,
                subjectType: subjectType,
                subjectId: subjectId,
                role: role,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String subjectType,
                required int subjectId,
                required String role,
                required String content,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AISessionsCompanion.insert(
                id: id,
                subjectType: subjectType,
                subjectId: subjectId,
                role: role,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AISessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AISessionsTable,
      AISession,
      $$AISessionsTableFilterComposer,
      $$AISessionsTableOrderingComposer,
      $$AISessionsTableAnnotationComposer,
      $$AISessionsTableCreateCompanionBuilder,
      $$AISessionsTableUpdateCompanionBuilder,
      (AISession, BaseReferences<_$AppDatabase, $AISessionsTable, AISession>),
      AISession,
      PrefetchHooks Function()
    >;
typedef $$PhilosophicalDialoguesTableCreateCompanionBuilder =
    PhilosophicalDialoguesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> summary,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PhilosophicalDialoguesTableUpdateCompanionBuilder =
    PhilosophicalDialoguesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> summary,
      Value<String?> category,
      Value<String?> tags,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PhilosophicalDialoguesTableFilterComposer
    extends Composer<_$AppDatabase, $PhilosophicalDialoguesTable> {
  $$PhilosophicalDialoguesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhilosophicalDialoguesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhilosophicalDialoguesTable> {
  $$PhilosophicalDialoguesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhilosophicalDialoguesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhilosophicalDialoguesTable> {
  $$PhilosophicalDialoguesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PhilosophicalDialoguesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhilosophicalDialoguesTable,
          PhilosophicalDialogue,
          $$PhilosophicalDialoguesTableFilterComposer,
          $$PhilosophicalDialoguesTableOrderingComposer,
          $$PhilosophicalDialoguesTableAnnotationComposer,
          $$PhilosophicalDialoguesTableCreateCompanionBuilder,
          $$PhilosophicalDialoguesTableUpdateCompanionBuilder,
          (
            PhilosophicalDialogue,
            BaseReferences<
              _$AppDatabase,
              $PhilosophicalDialoguesTable,
              PhilosophicalDialogue
            >,
          ),
          PhilosophicalDialogue,
          PrefetchHooks Function()
        > {
  $$PhilosophicalDialoguesTableTableManager(
    _$AppDatabase db,
    $PhilosophicalDialoguesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhilosophicalDialoguesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PhilosophicalDialoguesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PhilosophicalDialoguesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PhilosophicalDialoguesCompanion(
                id: id,
                title: title,
                summary: summary,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> summary = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PhilosophicalDialoguesCompanion.insert(
                id: id,
                title: title,
                summary: summary,
                category: category,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhilosophicalDialoguesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhilosophicalDialoguesTable,
      PhilosophicalDialogue,
      $$PhilosophicalDialoguesTableFilterComposer,
      $$PhilosophicalDialoguesTableOrderingComposer,
      $$PhilosophicalDialoguesTableAnnotationComposer,
      $$PhilosophicalDialoguesTableCreateCompanionBuilder,
      $$PhilosophicalDialoguesTableUpdateCompanionBuilder,
      (
        PhilosophicalDialogue,
        BaseReferences<
          _$AppDatabase,
          $PhilosophicalDialoguesTable,
          PhilosophicalDialogue
        >,
      ),
      PhilosophicalDialogue,
      PrefetchHooks Function()
    >;
typedef $$PhilosophicalMessagesTableCreateCompanionBuilder =
    PhilosophicalMessagesCompanion Function({
      Value<int> id,
      required int dialogueId,
      required DialogueRole role,
      Value<DialogueInputType> inputType,
      Value<String> content,
      Value<String?> persona,
      Value<String?> imagePath,
      Value<DateTime> createdAt,
    });
typedef $$PhilosophicalMessagesTableUpdateCompanionBuilder =
    PhilosophicalMessagesCompanion Function({
      Value<int> id,
      Value<int> dialogueId,
      Value<DialogueRole> role,
      Value<DialogueInputType> inputType,
      Value<String> content,
      Value<String?> persona,
      Value<String?> imagePath,
      Value<DateTime> createdAt,
    });

class $$PhilosophicalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $PhilosophicalMessagesTable> {
  $$PhilosophicalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DialogueRole, DialogueRole, int> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DialogueInputType, DialogueInputType, int>
  get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhilosophicalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhilosophicalMessagesTable> {
  $$PhilosophicalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputType => $composableBuilder(
    column: $table.inputType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhilosophicalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhilosophicalMessagesTable> {
  $$PhilosophicalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DialogueRole, int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DialogueInputType, int> get inputType =>
      $composableBuilder(column: $table.inputType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get persona =>
      $composableBuilder(column: $table.persona, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PhilosophicalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhilosophicalMessagesTable,
          PhilosophicalMessage,
          $$PhilosophicalMessagesTableFilterComposer,
          $$PhilosophicalMessagesTableOrderingComposer,
          $$PhilosophicalMessagesTableAnnotationComposer,
          $$PhilosophicalMessagesTableCreateCompanionBuilder,
          $$PhilosophicalMessagesTableUpdateCompanionBuilder,
          (
            PhilosophicalMessage,
            BaseReferences<
              _$AppDatabase,
              $PhilosophicalMessagesTable,
              PhilosophicalMessage
            >,
          ),
          PhilosophicalMessage,
          PrefetchHooks Function()
        > {
  $$PhilosophicalMessagesTableTableManager(
    _$AppDatabase db,
    $PhilosophicalMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhilosophicalMessagesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PhilosophicalMessagesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PhilosophicalMessagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dialogueId = const Value.absent(),
                Value<DialogueRole> role = const Value.absent(),
                Value<DialogueInputType> inputType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> persona = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhilosophicalMessagesCompanion(
                id: id,
                dialogueId: dialogueId,
                role: role,
                inputType: inputType,
                content: content,
                persona: persona,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dialogueId,
                required DialogueRole role,
                Value<DialogueInputType> inputType = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> persona = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhilosophicalMessagesCompanion.insert(
                id: id,
                dialogueId: dialogueId,
                role: role,
                inputType: inputType,
                content: content,
                persona: persona,
                imagePath: imagePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhilosophicalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhilosophicalMessagesTable,
      PhilosophicalMessage,
      $$PhilosophicalMessagesTableFilterComposer,
      $$PhilosophicalMessagesTableOrderingComposer,
      $$PhilosophicalMessagesTableAnnotationComposer,
      $$PhilosophicalMessagesTableCreateCompanionBuilder,
      $$PhilosophicalMessagesTableUpdateCompanionBuilder,
      (
        PhilosophicalMessage,
        BaseReferences<
          _$AppDatabase,
          $PhilosophicalMessagesTable,
          PhilosophicalMessage
        >,
      ),
      PhilosophicalMessage,
      PrefetchHooks Function()
    >;
typedef $$PhilosophicalConceptExtractionsTableCreateCompanionBuilder =
    PhilosophicalConceptExtractionsCompanion Function({
      Value<int> id,
      required int dialogueId,
      Value<int?> messageId,
      Value<String?> persona,
      required String conceptTitle,
      required String conceptBody,
      Value<ConceptOrigin> conceptOrigin,
      Value<ExtractionStatus> status,
      Value<int?> conceptDictionaryId,
      Value<DateTime> createdAt,
    });
typedef $$PhilosophicalConceptExtractionsTableUpdateCompanionBuilder =
    PhilosophicalConceptExtractionsCompanion Function({
      Value<int> id,
      Value<int> dialogueId,
      Value<int?> messageId,
      Value<String?> persona,
      Value<String> conceptTitle,
      Value<String> conceptBody,
      Value<ConceptOrigin> conceptOrigin,
      Value<ExtractionStatus> status,
      Value<int?> conceptDictionaryId,
      Value<DateTime> createdAt,
    });

class $$PhilosophicalConceptExtractionsTableFilterComposer
    extends Composer<_$AppDatabase, $PhilosophicalConceptExtractionsTable> {
  $$PhilosophicalConceptExtractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptTitle => $composableBuilder(
    column: $table.conceptTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conceptBody => $composableBuilder(
    column: $table.conceptBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ConceptOrigin, ConceptOrigin, int>
  get conceptOrigin => $composableBuilder(
    column: $table.conceptOrigin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ExtractionStatus, ExtractionStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get conceptDictionaryId => $composableBuilder(
    column: $table.conceptDictionaryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhilosophicalConceptExtractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhilosophicalConceptExtractionsTable> {
  $$PhilosophicalConceptExtractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get persona => $composableBuilder(
    column: $table.persona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptTitle => $composableBuilder(
    column: $table.conceptTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conceptBody => $composableBuilder(
    column: $table.conceptBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conceptOrigin => $composableBuilder(
    column: $table.conceptOrigin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get conceptDictionaryId => $composableBuilder(
    column: $table.conceptDictionaryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhilosophicalConceptExtractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhilosophicalConceptExtractionsTable> {
  $$PhilosophicalConceptExtractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dialogueId => $composableBuilder(
    column: $table.dialogueId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get persona =>
      $composableBuilder(column: $table.persona, builder: (column) => column);

  GeneratedColumn<String> get conceptTitle => $composableBuilder(
    column: $table.conceptTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conceptBody => $composableBuilder(
    column: $table.conceptBody,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ConceptOrigin, int> get conceptOrigin =>
      $composableBuilder(
        column: $table.conceptOrigin,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ExtractionStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get conceptDictionaryId => $composableBuilder(
    column: $table.conceptDictionaryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PhilosophicalConceptExtractionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhilosophicalConceptExtractionsTable,
          PhilosophicalConceptExtraction,
          $$PhilosophicalConceptExtractionsTableFilterComposer,
          $$PhilosophicalConceptExtractionsTableOrderingComposer,
          $$PhilosophicalConceptExtractionsTableAnnotationComposer,
          $$PhilosophicalConceptExtractionsTableCreateCompanionBuilder,
          $$PhilosophicalConceptExtractionsTableUpdateCompanionBuilder,
          (
            PhilosophicalConceptExtraction,
            BaseReferences<
              _$AppDatabase,
              $PhilosophicalConceptExtractionsTable,
              PhilosophicalConceptExtraction
            >,
          ),
          PhilosophicalConceptExtraction,
          PrefetchHooks Function()
        > {
  $$PhilosophicalConceptExtractionsTableTableManager(
    _$AppDatabase db,
    $PhilosophicalConceptExtractionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhilosophicalConceptExtractionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PhilosophicalConceptExtractionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PhilosophicalConceptExtractionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dialogueId = const Value.absent(),
                Value<int?> messageId = const Value.absent(),
                Value<String?> persona = const Value.absent(),
                Value<String> conceptTitle = const Value.absent(),
                Value<String> conceptBody = const Value.absent(),
                Value<ConceptOrigin> conceptOrigin = const Value.absent(),
                Value<ExtractionStatus> status = const Value.absent(),
                Value<int?> conceptDictionaryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhilosophicalConceptExtractionsCompanion(
                id: id,
                dialogueId: dialogueId,
                messageId: messageId,
                persona: persona,
                conceptTitle: conceptTitle,
                conceptBody: conceptBody,
                conceptOrigin: conceptOrigin,
                status: status,
                conceptDictionaryId: conceptDictionaryId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dialogueId,
                Value<int?> messageId = const Value.absent(),
                Value<String?> persona = const Value.absent(),
                required String conceptTitle,
                required String conceptBody,
                Value<ConceptOrigin> conceptOrigin = const Value.absent(),
                Value<ExtractionStatus> status = const Value.absent(),
                Value<int?> conceptDictionaryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PhilosophicalConceptExtractionsCompanion.insert(
                id: id,
                dialogueId: dialogueId,
                messageId: messageId,
                persona: persona,
                conceptTitle: conceptTitle,
                conceptBody: conceptBody,
                conceptOrigin: conceptOrigin,
                status: status,
                conceptDictionaryId: conceptDictionaryId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhilosophicalConceptExtractionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhilosophicalConceptExtractionsTable,
      PhilosophicalConceptExtraction,
      $$PhilosophicalConceptExtractionsTableFilterComposer,
      $$PhilosophicalConceptExtractionsTableOrderingComposer,
      $$PhilosophicalConceptExtractionsTableAnnotationComposer,
      $$PhilosophicalConceptExtractionsTableCreateCompanionBuilder,
      $$PhilosophicalConceptExtractionsTableUpdateCompanionBuilder,
      (
        PhilosophicalConceptExtraction,
        BaseReferences<
          _$AppDatabase,
          $PhilosophicalConceptExtractionsTable,
          PhilosophicalConceptExtraction
        >,
      ),
      PhilosophicalConceptExtraction,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$EnglishLexiconsTableTableManager get englishLexicons =>
      $$EnglishLexiconsTableTableManager(_db, _db.englishLexicons);
  $$EntryAppendicesTableTableManager get entryAppendices =>
      $$EntryAppendicesTableTableManager(_db, _db.entryAppendices);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ReadingMemosTableTableManager get readingMemos =>
      $$ReadingMemosTableTableManager(_db, _db.readingMemos);
  $$ReadingReflectionsTableTableManager get readingReflections =>
      $$ReadingReflectionsTableTableManager(_db, _db.readingReflections);
  $$ConceptDictionariesTableTableManager get conceptDictionaries =>
      $$ConceptDictionariesTableTableManager(_db, _db.conceptDictionaries);
  $$ConceptMemosTableTableManager get conceptMemos =>
      $$ConceptMemosTableTableManager(_db, _db.conceptMemos);
  $$DailyMemosTableTableManager get dailyMemos =>
      $$DailyMemosTableTableManager(_db, _db.dailyMemos);
  $$DictionaryDefinitionsTableTableManager get dictionaryDefinitions =>
      $$DictionaryDefinitionsTableTableManager(_db, _db.dictionaryDefinitions);
  $$DictionaryFieldsTableTableManager get dictionaryFields =>
      $$DictionaryFieldsTableTableManager(_db, _db.dictionaryFields);
  $$DictionaryEntriesTableTableManager get dictionaryEntries =>
      $$DictionaryEntriesTableTableManager(_db, _db.dictionaryEntries);
  $$DictionaryEntryValuesTableTableManager get dictionaryEntryValues =>
      $$DictionaryEntryValuesTableTableManager(_db, _db.dictionaryEntryValues);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$EntryTagsTableTableManager get entryTags =>
      $$EntryTagsTableTableManager(_db, _db.entryTags);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db, _db.quotes);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$EntrySourcesTableTableManager get entrySources =>
      $$EntrySourcesTableTableManager(_db, _db.entrySources);
  $$AISessionsTableTableManager get aISessions =>
      $$AISessionsTableTableManager(_db, _db.aISessions);
  $$PhilosophicalDialoguesTableTableManager get philosophicalDialogues =>
      $$PhilosophicalDialoguesTableTableManager(
        _db,
        _db.philosophicalDialogues,
      );
  $$PhilosophicalMessagesTableTableManager get philosophicalMessages =>
      $$PhilosophicalMessagesTableTableManager(_db, _db.philosophicalMessages);
  $$PhilosophicalConceptExtractionsTableTableManager
  get philosophicalConceptExtractions =>
      $$PhilosophicalConceptExtractionsTableTableManager(
        _db,
        _db.philosophicalConceptExtractions,
      );
}
