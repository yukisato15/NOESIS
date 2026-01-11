import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/concept_memos_table.dart';

part 'concept_memos_dao.g.dart';

@DriftAccessor(tables: [ConceptMemos])
class ConceptMemosDao extends DatabaseAccessor<AppDatabase>
    with _$ConceptMemosDaoMixin {
  ConceptMemosDao(super.db);

  // 全ての概念メモを取得
  Future<List<ConceptMemo>> getAllConceptMemos() {
    return (select(conceptMemos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // 概念メモの作成
  Future<int> createConceptMemo(ConceptMemosCompanion memo) {
    return into(conceptMemos).insert(memo);
  }

  // 概念メモの更新
  Future<bool> updateConceptMemo(ConceptMemo memo) {
    return update(conceptMemos).replace(memo);
  }

  // 概念メモの削除
  Future<int> deleteConceptMemo(int id) {
    return (delete(conceptMemos)..where((t) => t.id.equals(id))).go();
  }

  // ID指定で概念メモ取得
  Future<ConceptMemo?> getConceptMemoById(int id) {
    return (select(conceptMemos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // FTS5全文検索
  Future<List<ConceptMemo>> searchConceptMemos(String query) async {
    final results = await customSelect(
      '''
      SELECT cm.* FROM concept_memos cm
      JOIN concept_memos_fts f ON cm.id = f.rowid
      WHERE concept_memos_fts MATCH ?
      ORDER BY cm.updated_at DESC
      ''',
      variables: [Variable.withString(query)],
      readsFrom: {conceptMemos},
    ).get();

    return results.map((row) => conceptMemos.map(row.data)).toList();
  }

  // 最近の概念メモを取得
  Future<List<ConceptMemo>> getRecentConceptMemos({int limit = 20}) {
    return (select(conceptMemos)
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  // タグでフィルター（後で実装する結合クエリ用）
  Future<List<ConceptMemo>> getConceptMemosByTag(String tagName) async {
    final results = await customSelect(
      '''
      SELECT DISTINCT cm.* FROM concept_memos cm
      JOIN entry_tags et ON cm.id = et.entry_id
      JOIN tags t ON et.tag_id = t.id
      WHERE t.name = ?
      ORDER BY cm.updated_at DESC
      ''',
      variables: [Variable.withString(tagName)],
      readsFrom: {conceptMemos},
    ).get();

    return results.map((row) => conceptMemos.map(row.data)).toList();
  }
}
