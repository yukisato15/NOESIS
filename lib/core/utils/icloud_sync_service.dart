import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ICloudSyncStatus {
  final bool available;
  final bool hasBackup;
  final DateTime? modifiedAt;

  const ICloudSyncStatus({
    required this.available,
    required this.hasBackup,
    required this.modifiedAt,
  });
}

class ICloudSyncService {
  static const MethodChannel _channel = MethodChannel('noesis/icloud_sync');
  static const String _databaseFileName = 'noesis.db';

  static Future<ICloudSyncStatus> getStatus() async {
    Map<String, dynamic> payload;
    try {
      payload = await _channel.invokeMapMethod<String, dynamic>(
            'status',
            {'filename': _databaseFileName},
          ) ??
          const <String, dynamic>{};
    } on PlatformException {
      return const ICloudSyncStatus(
        available: false,
        hasBackup: false,
        modifiedAt: null,
      );
    } on MissingPluginException {
      return const ICloudSyncStatus(
        available: false,
        hasBackup: false,
        modifiedAt: null,
      );
    }

    final available = payload['available'] == true;
    final hasBackup = payload['hasBackup'] == true;
    final modifiedAtRaw = payload['modifiedAt'];
    DateTime? modifiedAt;
    if (modifiedAtRaw is num) {
      modifiedAt =
          DateTime.fromMillisecondsSinceEpoch((modifiedAtRaw * 1000).toInt());
    }

    return ICloudSyncStatus(
      available: available,
      hasBackup: hasBackup,
      modifiedAt: modifiedAt,
    );
  }

  static Future<void> backupDatabase() async {
    final localPath = await _localDatabasePath();
    await _channel.invokeMethod(
      'backup',
      {
        'localPath': localPath,
        'filename': _databaseFileName,
      },
    );
  }

  static Future<void> restoreDatabase() async {
    final localPath = await _localDatabasePath();
    await _channel.invokeMethod(
      'restore',
      {
        'localPath': localPath,
        'filename': _databaseFileName,
      },
    );
  }

  static Future<String> _localDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _databaseFileName);
  }
}
