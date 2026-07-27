import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Handles local backup and restore of the app database.
class DataBackupService {
  static const String _dbFileName = 'noesis.db';

  /// Export the current database to a temporary file.
  static Future<File> exportDatabase() async {
    final dbFile = await _getDatabaseFile();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final backupPath = '${tempDir.path}/noesis_backup_$timestamp.db';
    return dbFile.copy(backupPath);
  }

  /// Import a database file and replace the current one.
  /// Keeps a .bak backup of the previous database.
  static Future<void> importDatabase(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('バックアップファイルが見つかりません');
    }

    final dbFile = await _getDatabaseFile();
    if (await dbFile.exists()) {
      await dbFile.copy('${dbFile.path}.bak');
    }

    await sourceFile.copy(dbFile.path);
  }

  static Future<File> _getDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_dbFileName');
  }
}
