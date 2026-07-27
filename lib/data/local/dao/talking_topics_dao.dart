import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/talking_topic_messages_table.dart';
import '../tables/talking_topic_sources_table.dart';
import '../tables/talking_topics_table.dart';
import '../tables/talking_topic_usages_table.dart';

part 'talking_topics_dao.g.dart';

@DriftAccessor(
  tables: [
    TalkingTopics,
    TalkingTopicSources,
    TalkingTopicUsages,
    TalkingTopicMessages,
  ],
)
class TalkingTopicsDao extends DatabaseAccessor<AppDatabase>
    with _$TalkingTopicsDaoMixin {
  TalkingTopicsDao(super.db);

  Future<List<TalkingTopic>> getAllTopics() {
    return (select(talkingTopics)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<TalkingTopic?> getTopicById(int id) {
    return (select(
      talkingTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTopic(TalkingTopicsCompanion topic) {
    return into(talkingTopics).insert(topic);
  }

  Future<bool> updateTopic(TalkingTopic topic) {
    return update(talkingTopics).replace(topic);
  }

  Future<void> deleteTopic(int id) async {
    await transaction(() async {
      await (delete(
        talkingTopicSources,
      )..where((t) => t.topicId.equals(id))).go();
      await (delete(
        talkingTopicUsages,
      )..where((t) => t.topicId.equals(id))).go();
      await (delete(
        talkingTopicMessages,
      )..where((t) => t.topicId.equals(id))).go();
      await (delete(talkingTopics)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<TalkingTopicSource>> getSources(int topicId) {
    return (select(talkingTopicSources)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> insertSource(TalkingTopicSourcesCompanion source) {
    return into(talkingTopicSources).insert(source);
  }

  Future<int> deleteSourcesForTopic(int topicId) {
    return (delete(
      talkingTopicSources,
    )..where((t) => t.topicId.equals(topicId))).go();
  }

  Future<List<TalkingTopicUsage>> getUsages(int topicId) {
    return (select(talkingTopicUsages)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.usedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> insertUsage(TalkingTopicUsagesCompanion usage) {
    return into(talkingTopicUsages).insert(usage);
  }

  Future<int> deleteUsage(int usageId) {
    return (delete(
      talkingTopicUsages,
    )..where((t) => t.id.equals(usageId))).go();
  }

  Future<List<TalkingTopicMessage>> getMessages(int topicId) {
    return (select(talkingTopicMessages)
          ..where((t) => t.topicId.equals(topicId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> insertMessage(TalkingTopicMessagesCompanion message) {
    return into(talkingTopicMessages).insert(message);
  }

  Future<int> touchTopic(int topicId) {
    return (update(talkingTopics)..where((t) => t.id.equals(topicId))).write(
      TalkingTopicsCompanion(updatedAt: Value(DateTime.now())),
    );
  }
}
