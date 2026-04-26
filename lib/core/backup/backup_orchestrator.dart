import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_encryption_service.dart';
import 'backup_exception.dart';
import 'backup_models.dart';
import 'backup_progress.dart';
import 'drive_backup_service.dart';
import 'google_auth_service.dart';
import 'isar_export_service.dart';

class BackupOrchestrator {
  BackupOrchestrator({
    required this.exportService,
    required this.encryptionService,
    required this.driveService,
    required this.authService,
    required this.isar,
  });

  static const backupLastTimeKey = 'backup_last_time';
  static const backupLastSizeKey = 'backup_last_size';
  static const autoBackupEnabledKey = 'auto_backup_enabled';

  final IsarExportService exportService;
  final BackupEncryptionService encryptionService;
  final DriveBackupService driveService;
  final GoogleAuthService authService;
  final Isar isar;

  Future<BackupResult> createBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    const totalSteps = 6;
    final startedAt = DateTime.now();
    try {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.preparing,
        currentStep: 1,
        totalSteps: totalSteps,
        startedAt: startedAt,
      );
      await _ensureSignedIn();
      final userId = authService.userId;
      if (userId == null || userId.isEmpty) {
        throw const BackupException('সাইন ইন করুন');
      }

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.exporting,
        currentStep: 2,
        totalSteps: totalSteps,
        startedAt: startedAt,
      );
      final exported = await exportService.exportAll(isar);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(exported)));

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.compressing,
        currentStep: 3,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: jsonBytes.length,
        totalBytes: jsonBytes.length,
      );
      final compressed = GZipEncoder().encode(jsonBytes);

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.encrypting,
        currentStep: 4,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: compressed.length,
        totalBytes: compressed.length,
      );
      final encrypted = encryptionService.encrypt(
        Uint8List.fromList(compressed),
        userId,
      );
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.uploading,
        currentStep: 5,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: 0,
        totalBytes: encrypted.length,
      );
      final upload = await driveService.uploadBackup(
        encrypted,
        onProgress: (sentBytes, totalBytes) {
          _emitProgress(
            onProgress,
            operation: BackupOperationKind.backup,
            stage: BackupProgressStage.uploading,
            currentStep: 5,
            totalSteps: totalSteps,
            startedAt: startedAt,
            processedBytes: sentBytes,
            totalBytes: totalBytes,
          );
        },
      );

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.finalizing,
        currentStep: 6,
        totalSteps: totalSteps,
        startedAt: startedAt,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        backupLastTimeKey,
        upload.uploadedAt.millisecondsSinceEpoch,
      );
      await prefs.setInt(backupLastSizeKey, upload.sizeBytes);

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.completed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: upload.sizeBytes,
        totalBytes: upload.sizeBytes,
        overrideProgress: 1,
      );
      return BackupResult(
        success: true,
        timestamp: upload.uploadedAt,
        sizeBytes: upload.sizeBytes,
      );
    } on BackupException catch (error) {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.failed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        overrideProgress: 1,
      );
      return BackupResult(success: false, errorMessage: error.message);
    } catch (error) {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.failed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        overrideProgress: 1,
      );
      return BackupResult(
        success: false,
        errorMessage: _friendlyUnexpectedError(error),
      );
    }
  }

  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    const totalSteps = 6;
    final startedAt = DateTime.now();
    try {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.preparing,
        currentStep: 1,
        totalSteps: totalSteps,
        startedAt: startedAt,
      );
      await _ensureSignedIn();
      final userId = authService.userId;
      if (userId == null || userId.isEmpty) {
        throw const BackupException('সাইন ইন করুন');
      }

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.downloading,
        currentStep: 2,
        totalSteps: totalSteps,
        startedAt: startedAt,
      );
      final encryptedBytes = await driveService.downloadLatestBackup(
        onProgress: (receivedBytes, totalBytes) {
          _emitProgress(
            onProgress,
            operation: BackupOperationKind.restore,
            stage: BackupProgressStage.downloading,
            currentStep: 2,
            totalSteps: totalSteps,
            startedAt: startedAt,
            processedBytes: receivedBytes,
            totalBytes: totalBytes,
          );
        },
      );
      if (encryptedBytes == null) {
        throw const BackupException('কোনো ব্যাকআপ পাওয়া যায়নি');
      }

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.decrypting,
        currentStep: 3,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: encryptedBytes.length,
        totalBytes: encryptedBytes.length,
      );
      final decrypted = encryptionService.decrypt(encryptedBytes, userId);

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.decoding,
        currentStep: 4,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: decrypted.length,
        totalBytes: decrypted.length,
      );
      final decompressed = GZipDecoder().decodeBytes(decrypted);
      final decoded = jsonDecode(utf8.decode(decompressed));
      if (decoded is! Map<String, dynamic>) {
        throw const BackupException(
          'ব্যাকআপ ফরম্যাট সঠিক নয়',
          isRecoverable: false,
        );
      }

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.importing,
        currentStep: 5,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: decompressed.length,
        totalBytes: decompressed.length,
      );
      await exportService.importAll(isar, decoded);

      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.finalizing,
        currentStep: 6,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: encryptedBytes.length,
        totalBytes: encryptedBytes.length,
      );
      final restoredAt = DateTime.now().toUtc();
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.completed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        processedBytes: encryptedBytes.length,
        totalBytes: encryptedBytes.length,
        overrideProgress: 1,
      );
      return RestoreResult(
        success: true,
        timestamp: restoredAt,
        sizeBytes: encryptedBytes.length,
      );
    } on BackupException catch (error) {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.failed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        overrideProgress: 1,
      );
      return RestoreResult(success: false, errorMessage: error.message);
    } catch (error) {
      _emitProgress(
        onProgress,
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.failed,
        currentStep: totalSteps,
        totalSteps: totalSteps,
        startedAt: startedAt,
        overrideProgress: 1,
      );
      return RestoreResult(
        success: false,
        errorMessage: _friendlyUnexpectedError(
          error,
          fallback: 'রিস্টোর করতে সমস্যা হয়েছে',
        ),
      );
    }
  }

  Future<BackupFileInfo?> getCloudBackupInfo() async {
    try {
      await _ensureSignedIn();
      return driveService.getLatestBackupInfo();
    } on BackupException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void _emitProgress(
    void Function(BackupProgressState progress)? callback, {
    required BackupOperationKind operation,
    required BackupProgressStage stage,
    required int currentStep,
    required int totalSteps,
    required DateTime startedAt,
    int? processedBytes,
    int? totalBytes,
    double? overrideProgress,
  }) {
    if (callback == null) {
      return;
    }
    final stageFraction = switch (stage) {
      BackupProgressStage.uploading || BackupProgressStage.downloading
          when processedBytes != null && totalBytes != null && totalBytes > 0 =>
        (processedBytes / totalBytes).clamp(0.0, 1.0),
      BackupProgressStage.completed || BackupProgressStage.failed => 1.0,
      _ => 0.0,
    };
    final progress =
        overrideProgress ??
        (((currentStep - 1) + stageFraction) / totalSteps).clamp(0.0, 1.0);

    callback(
      BackupProgressState(
        operation: operation,
        stage: stage,
        currentStep: currentStep,
        totalSteps: totalSteps,
        overallProgress: progress,
        processedBytes: processedBytes,
        totalBytes: totalBytes,
        startedAt: startedAt,
        isBlocking: operation == BackupOperationKind.restore,
      ),
    );
  }

  Future<void> _ensureSignedIn() async {
    if (await authService.isSignedIn()) {
      return;
    }
    await authService.signInSilently();
    if (!await authService.isSignedIn()) {
      throw const BackupException('সাইন ইন করুন');
    }
  }

  String _friendlyUnexpectedError(
    Object error, {
    String fallback = 'ব্যাকআপ করতে সমস্যা হয়েছে',
  }) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('network') ||
        raw.contains('socketexception') ||
        raw.contains('failed host lookup')) {
      return 'ইন্টারনেট সংযোগ নেই';
    }
    if (raw.contains('sign_in_failed') ||
        raw.contains('clientconfigurationerror') ||
        raw.contains('12500') ||
        raw.contains('apiexception: 10')) {
      return 'Google Sign-In configure করা নেই। SHA-1, package name, আর google-services.json আবার check করুন।';
    }
    if (raw.contains('accessnotconfigured') ||
        raw.contains('service_disabled') ||
        raw.contains('api has not been used') ||
        raw.contains('google drive api has not been used') ||
        raw.contains('drive.googleapis.com') && raw.contains('disabled')) {
      return 'Google Drive API চালু নেই। Google Cloud Console এ এই project-এর Drive API enable করুন।';
    }
    if (raw.contains('insufficient') ||
        raw.contains('authentication scopes') ||
        raw.contains('invalid credentials') ||
        raw.contains('unauthorized')) {
      return 'Google Drive অনুমতি বা সাইন-ইন সমস্যা হয়েছে। আবার Google দিয়ে সাইন ইন করুন।';
    }
    return fallback;
  }
}
