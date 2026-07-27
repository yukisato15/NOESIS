import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'local_llm_model_info.dart';

class LocalModelDownloader {
  static final Map<String, double> _downloadProgress = {};

  /// モデルファイルの保存ディレクトリを取得
  static Future<Directory> getModelDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docsDir.path}/noesis_models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// 指定モデルの保存済みファイルパスを取得（未保存時はnull）
  static Future<File?> getDownloadedModelFile(LocalModelPreset preset) async {
    final dir = await getModelDirectory();
    final file = File('${dir.path}/${preset.fileName}');
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// 指定モデルがダウンロード済みかチェック
  static Future<bool> isModelDownloaded(LocalModelPreset preset) async {
    final file = await getDownloadedModelFile(preset);
    return file != null;
  }

  /// 現在のダウンロード進捗率 (0.0 ～ 1.0)
  static double getProgress(LocalModelPreset preset) {
    return _downloadProgress[preset.id] ?? 0.0;
  }

  /// モデルファイルのダウンロード実行
  static Future<File> downloadModel(
    LocalModelPreset preset, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getModelDirectory();
    final targetFile = File('${dir.path}/${preset.fileName}');

    if (await targetFile.exists()) {
      return targetFile;
    }

    final tempFile = File('${targetFile.path}.tmp');

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(preset.downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      var receivedBytes = 0;

      final sink = tempFile.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0) {
          final progress = receivedBytes / contentLength;
          _downloadProgress[preset.id] = progress;
          onProgress?.call(progress);
        }
      });

      await sink.flush();
      await sink.close();

      await tempFile.rename(targetFile.path);
      _downloadProgress[preset.id] = 1.0;
      onProgress?.call(1.0);
      return targetFile;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      _downloadProgress[preset.id] = 0.0;
      rethrow;
    }
  }

  /// ダウンロード済みモデルの削除
  static Future<void> deleteModel(LocalModelPreset preset) async {
    final file = await getDownloadedModelFile(preset);
    if (file != null && await file.exists()) {
      await file.delete();
      _downloadProgress[preset.id] = 0.0;
    }
  }
}
