import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// スポット写真をアプリ内に圧縮保存・削除するユーティリティ。
///
/// image_picker が返す一時ファイルパスは iOS にいつでも削除されるため、
/// アプリのドキュメントディレクトリにコピーしてから DB に保存する。
/// 圧縮により 1 枚あたり概ね 200〜400KB に収まる。
class SpotPhotoService {
  SpotPhotoService._();

  static const int _maxWidth = 1280;
  static const int _maxHeight = 1280;
  static const int _quality = 80;

  /// 一時ファイルパス（image_picker 等）から圧縮コピーを作り、
  /// アプリ内の永続パスを返す。
  ///
  /// [sourceImagePath] image_picker などが返した一時ファイルパス
  /// [prefix] ファイル名のプレフィックス（"spot", "visit" など）
  static Future<String> savePhoto({
    required String sourceImagePath,
    String prefix = 'spot',
  }) async {
    final dir = await _photoDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dest = '${dir.path}/${prefix}_$ts.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourceImagePath,
      dest,
      minWidth: _maxWidth,
      minHeight: _maxHeight,
      quality: _quality,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      // 圧縮失敗時はそのままコピー
      await File(sourceImagePath).copy(dest);
    }

    return dest;
  }

  /// 保存済み写真ファイルを削除する（スポット削除時など）。
  static Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// アプリ内の写真保存ディレクトリ（なければ作成）。
  static Future<Directory> _photoDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/spot_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// 合計使用容量をバイトで返す（設定画面等で表示用）。
  static Future<int> totalBytes() async {
    final dir = await _photoDirectory();
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
