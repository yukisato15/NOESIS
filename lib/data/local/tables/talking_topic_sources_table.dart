import 'package:drift/drift.dart';

enum TalkingTopicSourceArchiveType {
  dictionary,
  reading,
  concept,
  dialogue,
  daily,
  manual,
}

extension TalkingTopicSourceArchiveTypeLabel on TalkingTopicSourceArchiveType {
  String get label {
    switch (this) {
      case TalkingTopicSourceArchiveType.dictionary:
        return '辞書';
      case TalkingTopicSourceArchiveType.reading:
        return '読書';
      case TalkingTopicSourceArchiveType.concept:
        return '概念';
      case TalkingTopicSourceArchiveType.dialogue:
        return '対話';
      case TalkingTopicSourceArchiveType.daily:
        return '日常';
      case TalkingTopicSourceArchiveType.manual:
        return '手入力';
    }
  }
}

@DataClassName('TalkingTopicSource')
class TalkingTopicSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().named('topic_id')();
  IntColumn get sourceArchiveType =>
      intEnum<TalkingTopicSourceArchiveType>().named('source_archive_type')();
  IntColumn get sourceEntryId =>
      integer().named('source_entry_id').nullable()();
  TextColumn get sourceTitle => text().named('source_title').nullable()();
  TextColumn get sourceExcerpt => text().named('source_excerpt').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
