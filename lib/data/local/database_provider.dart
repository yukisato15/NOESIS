import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';

/// データベースのシングルトンプロバイダー
/// アプリ全体で単一のデータベースインスタンスを共有
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  // プロバイダーが破棄されるときにデータベースをクローズ
  ref.onDispose(() {
    database.close();
  });

  return database;
});
