import 'package:drift/drift.dart';

enum TalkingTopicMessageRole { system, user, assistant }

@DataClassName('TalkingTopicMessage')
class TalkingTopicMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().named('topic_id')();
  IntColumn get role =>
      intEnum<TalkingTopicMessageRole>().withDefault(const Constant(1))();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
