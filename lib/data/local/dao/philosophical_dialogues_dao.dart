import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/philosophical_dialogues_table.dart';
import '../tables/philosophical_messages_table.dart';
import '../tables/philosophical_concept_extractions_table.dart';

part 'philosophical_dialogues_dao.g.dart';

@DriftAccessor(
  tables: [
    PhilosophicalDialogues,
    PhilosophicalMessages,
    PhilosophicalConceptExtractions,
  ],
)
class PhilosophicalDialoguesDao extends DatabaseAccessor<AppDatabase>
    with _$PhilosophicalDialoguesDaoMixin {
  PhilosophicalDialoguesDao(super.db);

  Future<List<PhilosophicalDialogue>> getAllDialogues() {
    return (select(philosophicalDialogues)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> createDialogue(PhilosophicalDialoguesCompanion dialogue) {
    return into(philosophicalDialogues).insert(dialogue);
  }

  Future<bool> updateDialogue(PhilosophicalDialogue dialogue) {
    return update(philosophicalDialogues).replace(dialogue);
  }

  Future<int> deleteDialogue(int id) {
    return (delete(philosophicalDialogues)..where((t) => t.id.equals(id))).go();
  }

  Future<List<PhilosophicalMessage>> getMessagesByDialogue(int dialogueId) {
    return (select(philosophicalMessages)
          ..where((t) => t.dialogueId.equals(dialogueId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> addMessage(PhilosophicalMessagesCompanion message) {
    return into(philosophicalMessages).insert(message);
  }

  Future<List<PhilosophicalConceptExtraction>> getExtractionsByDialogue(
    int dialogueId,
  ) {
    return (select(philosophicalConceptExtractions)
          ..where((t) => t.dialogueId.equals(dialogueId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> addExtraction(PhilosophicalConceptExtractionsCompanion extraction) {
    return into(philosophicalConceptExtractions).insert(extraction);
  }
}
