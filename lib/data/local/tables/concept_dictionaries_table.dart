import 'package:drift/drift.dart';

enum ConceptOrigin {
  direct,
  dialogue,
}

@DataClassName('ConceptDictionary')
class ConceptDictionaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get body => text()(); // 概念の説明
  TextColumn get category => text().nullable()(); // カテゴリ/ジャンル
  TextColumn get tags => text().nullable()(); // JSON array of strings

  // 詳細項目
  TextColumn get memo => text().nullable()(); // メモ
  TextColumn get referenceUrls => text().nullable()(); // 参考URL（JSON配列）
  TextColumn get similarConcepts => text().nullable()(); // 類似の概念（JSON配列）
  TextColumn get contrastingConcepts => text().nullable()(); // 対比される概念（JSON配列）
  TextColumn get relatedConcepts => text().nullable()(); // 関連する概念（JSON配列）
  TextColumn get culturalBackground => text().nullable()(); // 文化的・歴史的背景
  TextColumn get practicalAdvice => text().nullable()(); // ワンポイントアドバイス
  TextColumn get caseStudies => text().nullable()(); // 実践例・ケーススタディ
  TextColumn get gyaruExplanation => text().nullable()(); // ギャルによる説明
  TextColumn get childExplanation => text().nullable()(); // 幼稚園児でも理解できるよう説明

  IntColumn get origin =>
      intEnum<ConceptOrigin>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
