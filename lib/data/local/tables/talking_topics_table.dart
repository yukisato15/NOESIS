import 'package:drift/drift.dart';

enum TalkingTopicTone { light, balanced, intellectual, funny }

enum TalkingTopicDifficulty { easy, medium, deep }

@DataClassName('TalkingTopic')
class TalkingTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get hook => text().nullable()();
  TextColumn get corePoint => text().named('core_point').nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get twist => text().nullable()();
  TextColumn get useCase => text().named('use_case').nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get tags => text().nullable()();
  IntColumn get tone =>
      intEnum<TalkingTopicTone>().withDefault(const Constant(1))();
  IntColumn get difficulty =>
      intEnum<TalkingTopicDifficulty>().withDefault(const Constant(1))();
  TextColumn get bestFor => text().named('best_for').nullable()();
  TextColumn get avoidFor => text().named('avoid_for').nullable()();
  TextColumn get delivery30s => text().named('delivery_30s').nullable()();
  TextColumn get delivery1m => text().named('delivery_1m').nullable()();
  TextColumn get delivery3m => text().named('delivery_3m').nullable()();
  TextColumn get deliveryCasual => text().named('delivery_casual').nullable()();
  TextColumn get deliveryIntellectual =>
      text().named('delivery_intellectual').nullable()();
  TextColumn get deliveryHumorous =>
      text().named('delivery_humorous').nullable()();
  TextColumn get followUpQuestion =>
      text().named('follow_up_question').nullable()();
  TextColumn get escapeLine => text().named('escape_line').nullable()();
  IntColumn get credibilityScore =>
      integer().named('credibility_score').withDefault(const Constant(50))();
  TextColumn get sourceNote => text().named('source_note').nullable()();
  TextColumn get referenceUrls => text().named('reference_urls').nullable()();
  TextColumn get aiSummary => text().named('ai_summary').nullable()();
  TextColumn get aiAngle => text().named('ai_angle').nullable()();
  TextColumn get aiPolishNote => text().named('ai_polish_note').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
