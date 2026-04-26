import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;

import 'backup_exception.dart';
import 'backup_models.dart';
import 'google_auth_service.dart';

class DriveBackupService {
  DriveBackupService(this._authService);

  // NOTE: Backup files are stored in Google Drive `appDataFolder`, not Firebase
  // Storage. Firebase Storage rules do not apply to this backup flow.
  static const latestBackupName = 'backup_latest.enc';
  static const _uploadChunkSize = 64 * 1024;

  final GoogleAuthService _authService;

  Future<BackupUploadResult> uploadBackup(
    Uint8List data, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) {
    return _withDriveApi((driveApi) async {
      final uploadTimestamp = DateTime.now().toUtc();
      final file = drive.File()
        ..name = _archivedBackupName(uploadTimestamp)
        ..parents = ['appDataFolder'];
      final media = drive.Media(
        _chunkedUploadStream(data, onProgress: onProgress),
        data.length,
      );
      final created = await driveApi.files.create(
        file,
        uploadMedia: media,
        $fields: 'id,size,modifiedTime',
      );

      final promoted = await driveApi.files.update(
        drive.File()..name = latestBackupName,
        created.id!,
        $fields: 'id,size,modifiedTime',
      );

      await _archivePreviousLatestBackups(driveApi, keepFileId: promoted.id);
      await _cleanupOldArchiveBackups(driveApi);

      return BackupUploadResult(
        fileId: promoted.id ?? '',
        sizeBytes: int.tryParse(promoted.size ?? '') ?? data.length,
        uploadedAt: promoted.modifiedTime?.toUtc() ?? uploadTimestamp,
      );
    });
  }

  Future<Uint8List?> downloadLatestBackup({
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) {
    return _withDriveApi((driveApi) async {
      final latest = await _findLatestBackupFile(driveApi);
      if (latest?.id == null) {
        return null;
      }

      final response = await driveApi.files.get(
        latest!.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (response is! drive.Media) {
        throw const BackupException(
          'ব্যাকআপ ফাইল ডাউনলোড করা যায়নি',
          isRecoverable: false,
        );
      }

      final expectedBytes = int.tryParse(latest.size ?? '') ?? 0;
      final bytes = await _collectBytes(
        response.stream,
        onProgress: (receivedBytes) {
          onProgress?.call(
            receivedBytes,
            expectedBytes > 0 ? expectedBytes : receivedBytes,
          );
        },
      );
      return Uint8List.fromList(bytes);
    });
  }

  Future<BackupFileInfo?> getLatestBackupInfo() {
    return _withDriveApi((driveApi) async {
      final latest = await _findLatestBackupFile(driveApi);
      if (latest == null) {
        return null;
      }
      return _toBackupFileInfo(latest);
    });
  }

  Future<void> deleteAllBackups() {
    return _withDriveApi((driveApi) async {
      final files = await _listBackupFiles(driveApi);
      for (final file in files) {
        final fileId = file.id;
        if (fileId == null || fileId.isEmpty) {
          continue;
        }
        await driveApi.files.delete(fileId);
      }
    });
  }

  Future<List<BackupFileInfo>> listAllBackups() {
    return _withDriveApi((driveApi) async {
      final files = await _listBackupFiles(driveApi);
      return files.map(_toBackupFileInfo).toList(growable: false);
    });
  }

  Future<T> _withDriveApi<T>(
    Future<T> Function(drive.DriveApi driveApi) action,
  ) async {
    final client = await _authService.getDriveHttpClient();
    if (client == null) {
      throw const BackupException('সাইন ইন করুন');
    }

    final driveApi = drive.DriveApi(client);
    try {
      return await action(driveApi);
    } on SocketException {
      throw const BackupException('ইন্টারনেট সংযোগ নেই');
    } on HttpException {
      throw const BackupException('ইন্টারনেট সংযোগ নেই');
    } on TimeoutException {
      throw const BackupException('ইন্টারনেট সংযোগ নেই');
    } catch (error) {
      if (error is BackupException) {
        rethrow;
      }
      final raw = error.toString().toLowerCase();
      if (raw.contains('socketexception') ||
          raw.contains('failed host lookup') ||
          raw.contains('connection closed')) {
        throw const BackupException('ইন্টারনেট সংযোগ নেই');
      }
      if (raw.contains('sign_in_failed') ||
          raw.contains('clientconfigurationerror') ||
          raw.contains('12500') ||
          raw.contains('apiexception: 10') ||
          raw.contains('platformexception(sign_in_failed')) {
        throw const BackupException(
          'Google Sign-In configure করা নেই। SHA-1, package name, আর google-services.json আবার check করুন।',
          isRecoverable: false,
        );
      }
      if (raw.contains('accessnotconfigured') ||
          raw.contains('service_disabled') ||
          raw.contains('api has not been used') ||
          raw.contains('google drive api has not been used') ||
          raw.contains('drive.googleapis.com') && raw.contains('disabled')) {
        throw const BackupException(
          'Google Drive API চালু নেই। Google Cloud Console এ এই project-এর Drive API enable করুন।',
          isRecoverable: false,
        );
      }
      if (raw.contains('insufficient') ||
          raw.contains('authentication scopes') ||
          raw.contains('insufficientpermissions') ||
          raw.contains('access_denied') ||
          raw.contains('permission')) {
        throw const BackupException(
          'Google Drive অনুমতি মেলেনি। আবার Google দিয়ে সাইন ইন করুন।',
        );
      }
      if (raw.contains('invalid credentials') ||
          raw.contains('unauthorized') ||
          raw.contains('401')) {
        throw const BackupException(
          'Google অ্যাকাউন্টের অনুমতি নতুন করে দরকার। সাইন আউট করে আবার সাইন ইন করুন।',
        );
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<drive.File?> _findLatestBackupFile(drive.DriveApi driveApi) async {
    final files = await _findLatestBackupFiles(driveApi);
    if (files.isEmpty) {
      return null;
    }
    return files.first;
  }

  Future<List<drive.File>> _findLatestBackupFiles(
    drive.DriveApi driveApi,
  ) async {
    final response = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$latestBackupName' and 'appDataFolder' in parents and trashed = false",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,size,createdTime,modifiedTime)',
      pageSize: 100,
    );
    return response.files ?? const <drive.File>[];
  }

  Future<void> _archivePreviousLatestBackups(
    drive.DriveApi driveApi, {
    String? keepFileId,
  }) async {
    final latestFiles = await _findLatestBackupFiles(driveApi);
    for (var index = 0; index < latestFiles.length; index++) {
      final file = latestFiles[index];
      final fileId = file.id;
      if (fileId == null || fileId.isEmpty || fileId == keepFileId) {
        continue;
      }
      await driveApi.files.update(
        drive.File()
          ..name = _archivedBackupName(
            DateTime.now().toUtc(),
            suffix: '${index}_${_archiveSuffix(fileId)}',
          ),
        fileId,
      );
    }
  }

  Future<void> _cleanupOldArchiveBackups(drive.DriveApi driveApi) async {
    final all = await _listBackupFiles(driveApi);
    final archives =
        all
            .where((file) => (file.name ?? '') != latestBackupName)
            .toList(growable: false)
          ..sort((first, second) {
            final firstDate =
                first.modifiedTime ?? first.createdTime ?? DateTime(0);
            final secondDate =
                second.modifiedTime ?? second.createdTime ?? DateTime(0);
            return secondDate.compareTo(firstDate);
          });

    if (archives.length <= 3) {
      return;
    }

    for (final file in archives.skip(3)) {
      final fileId = file.id;
      if (fileId == null || fileId.isEmpty) {
        continue;
      }
      await driveApi.files.delete(fileId);
    }
  }

  Future<List<drive.File>> _listBackupFiles(drive.DriveApi driveApi) async {
    final response = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "'appDataFolder' in parents and trashed = false and name contains 'backup_'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,size,createdTime,modifiedTime)',
      pageSize: 100,
    );
    return response.files ?? const <drive.File>[];
  }

  BackupFileInfo _toBackupFileInfo(drive.File file) {
    final modifiedAt =
        file.modifiedTime?.toUtc() ??
        file.createdTime?.toUtc() ??
        DateTime.now().toUtc();
    return BackupFileInfo(
      fileId: file.id ?? '',
      name: file.name ?? latestBackupName,
      sizeBytes: int.tryParse(file.size ?? '') ?? 0,
      modifiedAt: modifiedAt,
    );
  }

  String _archivedBackupName(DateTime nowUtc, {String? suffix}) {
    final y = nowUtc.year.toString().padLeft(4, '0');
    final m = nowUtc.month.toString().padLeft(2, '0');
    final d = nowUtc.day.toString().padLeft(2, '0');
    final hh = nowUtc.hour.toString().padLeft(2, '0');
    final mm = nowUtc.minute.toString().padLeft(2, '0');
    final ss = nowUtc.second.toString().padLeft(2, '0');
    final ms = nowUtc.millisecond.toString().padLeft(3, '0');
    final suffixPart = suffix == null || suffix.isEmpty ? '' : '_$suffix';
    return 'backup_$y$m${d}_$hh$mm$ss$ms$suffixPart.enc';
  }

  String _archiveSuffix(String fileId) {
    if (fileId.length <= 6) {
      return fileId;
    }
    return fileId.substring(fileId.length - 6);
  }

  Stream<List<int>> _chunkedUploadStream(
    Uint8List data, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async* {
    var sentBytes = 0;
    while (sentBytes < data.length) {
      final end = math.min(sentBytes + _uploadChunkSize, data.length);
      final chunk = Uint8List.sublistView(data, sentBytes, end);
      yield chunk;
      sentBytes = end;
      onProgress?.call(sentBytes, data.length);
    }
  }

  Future<List<int>> _collectBytes(
    Stream<List<int>> stream, {
    void Function(int receivedBytes)? onProgress,
  }) async {
    final chunks = <int>[];
    var receivedBytes = 0;
    await for (final chunk in stream) {
      chunks.addAll(chunk);
      receivedBytes += chunk.length;
      onProgress?.call(receivedBytes);
    }
    return chunks;
  }
}
