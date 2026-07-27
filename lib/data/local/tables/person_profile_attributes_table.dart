import 'package:drift/drift.dart';

enum PersonDataType { fact, observation, userInterpretation, aiHypothesis }

extension PersonDataTypeLabel on PersonDataType {
  String get label {
    switch (this) {
      case PersonDataType.fact:
        return 'FACT';
      case PersonDataType.observation:
        return 'OBSERVATION';
      case PersonDataType.userInterpretation:
        return 'USER_INTERPRETATION';
      case PersonDataType.aiHypothesis:
        return 'AI_HYPOTHESIS';
    }
  }

  String get shortLabel {
    switch (this) {
      case PersonDataType.fact:
        return '事実';
      case PersonDataType.observation:
        return '観察';
      case PersonDataType.userInterpretation:
        return '解釈';
      case PersonDataType.aiHypothesis:
        return 'AI仮説';
    }
  }

  String get description {
    switch (this) {
      case PersonDataType.fact:
        return '本人が明言したことや、公的情報など確認しやすい事実。';
      case PersonDataType.observation:
        return '見聞きした行動や反応など、観察した内容。';
      case PersonDataType.userInterpretation:
        return 'あなた自身が考えた解釈や読み取り。';
      case PersonDataType.aiHypothesis:
        return 'AIが会話や記録から推測した仮説。断定ではありません。';
    }
  }
}

@DataClassName('PersonProfileAttribute')
class PersonProfileAttributes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetId => integer()();
  TextColumn get category => text()();
  TextColumn get attributeName => text().named('attribute_name')();
  TextColumn get attributeValue => text().named('attribute_value')();
  IntColumn get dataType => intEnum<PersonDataType>()();
  IntColumn get confidenceScore =>
      integer().named('confidence_score').withDefault(const Constant(50))();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
