import 'package:drift/drift.dart';

enum ArchiveTargetType { person, publicFigure, place, topic }

extension ArchiveTargetTypeLabel on ArchiveTargetType {
  String get label {
    switch (this) {
      case ArchiveTargetType.person:
        return '人物';
      case ArchiveTargetType.publicFigure:
        return '著名人';
      case ArchiveTargetType.place:
        return '場所';
      case ArchiveTargetType.topic:
        return '小ネタ';
    }
  }
}

@DataClassName('ArchiveTarget')
class ArchiveTargets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetType => intEnum<ArchiveTargetType>()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get tags => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get firstMetAt => text().nullable()();
  TextColumn get firstMetPlace => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get mapUrl => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get analysisSummary => text().nullable()();
  TextColumn get analysisTraits => text().nullable()();
  TextColumn get mbtiGuess => text().nullable()();
  TextColumn get mbtiNote => text().nullable()();
  TextColumn get extraJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
