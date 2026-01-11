import 'package:drift/drift.dart';
import 'concept_dictionaries_table.dart';

enum ExtractionStatus {
  pending,
  accepted,
  rejected,
}

@DataClassName('PhilosophicalConceptExtraction')
class PhilosophicalConceptExtractions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dialogueId => integer()();
  IntColumn get messageId => integer().nullable()();
  TextColumn get persona => text().nullable()();
  TextColumn get conceptTitle => text()();
  TextColumn get conceptBody => text()();
  IntColumn get conceptOrigin =>
      intEnum<ConceptOrigin>().withDefault(const Constant(1))();
  IntColumn get status =>
      intEnum<ExtractionStatus>().withDefault(const Constant(0))();
  IntColumn get conceptDictionaryId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
