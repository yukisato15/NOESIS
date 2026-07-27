import 'package:drift/drift.dart';

@DataClassName('TalkingTopicUsage')
class TalkingTopicUsages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().named('topic_id')();
  DateTimeColumn get usedAt => dateTime().named('used_at')();
  TextColumn get targetPersonNote =>
      text().named('target_person_note').nullable()();
  TextColumn get situation => text().nullable()();
  TextColumn get reactionNote => text().named('reaction_note').nullable()();
  IntColumn get successScore => integer().named('success_score').nullable()();
  IntColumn get easeScore => integer().named('ease_score').nullable()();
  TextColumn get improvementNote =>
      text().named('improvement_note').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
