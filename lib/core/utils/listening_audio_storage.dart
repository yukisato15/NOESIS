import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ListeningAudioStorage {
  static const _managedDirs = {'listening_audio', 'listening_memos'};

  static Future<Directory> _ensureManagedDir(String folderName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> buildManagedPath({
    required String folderName,
    required String prefix,
    String extension = '.m4a',
  }) async {
    final dir = await _ensureManagedDir(folderName);
    return p.join(
      dir.path,
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
  }

  static Future<String> persistAudioFile(
    String inputPath, {
    required String folderName,
    required String prefix,
    String fallbackExtension = '.m4a',
  }) async {
    final source = File(inputPath);
    if (!await source.exists()) {
      throw Exception('音声ファイルが見つかりません');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    if (inputPath.startsWith(docsDir.path)) {
      return inputPath;
    }

    final extension = p.extension(inputPath).isEmpty
        ? fallbackExtension
        : p.extension(inputPath);
    final outputPath = await buildManagedPath(
      folderName: folderName,
      prefix: prefix,
      extension: extension,
    );
    return source.copy(outputPath).then((file) => file.path);
  }

  static bool isManagedAudioPath(String path) {
    return _managedDirs.any((dirName) => path.contains('/$dirName/'));
  }

  static bool isRescuableExternalPath(String path) {
    return path.isNotEmpty && !isManagedAudioPath(path);
  }
}
