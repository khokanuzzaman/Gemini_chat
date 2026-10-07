import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/backup/backup_encryption_service.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_orchestrator.dart';
import 'package:gemini_chat/core/backup/backup_progress.dart';
import 'package:gemini_chat/core/backup/backup_providers.dart';
import 'package:gemini_chat/core/backup/drive_backup_service.dart';
import 'package:gemini_chat/core/backup/google_auth_service.dart';
import 'package:gemini_chat/core/backup/isar_export_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupNotifier', () {
    test('createBackup exposes and clears active progress', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = _FakeGoogleAuthService();
      final orchestrator = _FakeBackupOrchestrator();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(auth),
          backupOrchestratorProvider.overrideWithValue(orchestrator),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupStateProvider.future);

      final future = container
          .read(backupStateProvider.notifier)
          .createBackup();
      await Future<void>.delayed(Duration.zero);

      final midState = container.read(backupStateProvider).valueOrNull!;
      expect(midState.isBackingUp, isTrue);
      expect(midState.isBusy, isTrue);
      expect(midState.progressTitle, 'ব্যাকআপ চলছে');
      expect(midState.activeProgress?.stage, BackupProgressStage.uploading);

      orchestrator.completeBackup();
      final result = await future;

      expect(result.success, isTrue);
      final endState = container.read(backupStateProvider).valueOrNull!;
      expect(endState.isBackingUp, isFalse);
      expect(endState.activeProgress, isNull);
      expect(endState.progressTitle, isNull);
      expect(endState.lastBackupSizeBytes, 4096);
    });

    test('restoreBackup exposes blocking progress and clears it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = _FakeGoogleAuthService();
      final orchestrator = _FakeBackupOrchestrator()
        ..restoreResult = const RestoreResult(
          success: false,
          errorMessage: 'রিস্টোর ব্যর্থ হয়েছে',
        );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(auth),
          backupOrchestratorProvider.overrideWithValue(orchestrator),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupStateProvider.future);

      final future = container
          .read(backupStateProvider.notifier)
          .restoreBackup();
      await Future<void>.delayed(Duration.zero);

      final midState = container.read(backupStateProvider).valueOrNull!;
      expect(midState.isRestoring, isTrue);
      expect(midState.isBusy, isTrue);
      expect(midState.progressTitle, 'রিস্টোর চলছে');
      expect(midState.activeProgress?.isBlocking, isTrue);
      expect(midState.activeProgress?.stage, BackupProgressStage.importing);

      orchestrator.completeRestore();
      final result = await future;

      expect(result.success, isFalse);
      final endState = container.read(backupStateProvider).valueOrNull!;
      expect(endState.isRestoring, isFalse);
      expect(endState.activeProgress, isNull);
      expect(endState.progressDetail, isNull);
      expect(endState.errorMessage, 'রিস্টোর ব্যর্থ হয়েছে');
    });

    test(
      'manual backups are free and unlimited: no daily quota exists',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final orchestrator = _FakeBackupOrchestrator();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            googleAuthServiceProvider.overrideWithValue(
              _FakeGoogleAuthService(),
            ),
            backupOrchestratorProvider.overrideWithValue(orchestrator),
          ],
        );
        addTearDown(container.dispose);

        await container.read(backupStateProvider.future);
        for (var run = 1; run <= 3; run++) {
          final future = container
              .read(backupStateProvider.notifier)
              .createBackup();
          await Future<void>.delayed(Duration.zero);
          orchestrator.completeBackup();
          final result = await future;
          expect(result.success, isTrue, reason: 'backup #$run');
          expect(orchestrator.createBackupCalls, run);
        }
      },
    );
  });
}

class _FakeGoogleAuthService implements GoogleAuthService {
  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<void> reauthenticate() async {}

  @override
  String? get displayName => 'Backup Test User';

  @override
  Future<http.Client?> getDriveHttpClient() async => null;

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<bool> signIn() async => true;

  @override
  Future<void> signInSilently() async {}

  @override
  Future<void> signOut() async {}

  @override
  String? get userEmail => 'backup-test@example.com';

  @override
  String? get userId => 'backup-user-1';
}

class _FakeBackupOrchestrator implements BackupOrchestrator {
  final Completer<void> _backupCompleter = Completer<void>();
  final Completer<void> _restoreCompleter = Completer<void>();
  int createBackupCalls = 0;
  BackupResult backupResult = BackupResult(
    success: true,
    timestamp: DateTime(2026, 4, 29, 10, 5),
    sizeBytes: 4096,
  );
  RestoreResult restoreResult = RestoreResult(
    success: true,
    timestamp: DateTime(2026, 4, 29, 10, 15),
    sizeBytes: 4096,
  );

  @override
  Future<BackupResult> createBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    createBackupCalls++;
    final startedAt = DateTime(2026, 4, 29, 10, 0);
    onProgress?.call(
      BackupProgressState(
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.exporting,
        currentStep: 2,
        totalSteps: 6,
        overallProgress: 0.2,
        startedAt: startedAt,
        isBlocking: false,
      ),
    );
    onProgress?.call(
      BackupProgressState(
        operation: BackupOperationKind.backup,
        stage: BackupProgressStage.uploading,
        currentStep: 5,
        totalSteps: 6,
        overallProgress: 0.82,
        processedBytes: 2048,
        totalBytes: 4096,
        startedAt: startedAt,
        isBlocking: false,
      ),
    );
    await _backupCompleter.future;
    return backupResult;
  }

  @override
  Future<BackupFileInfo?> getCloudBackupInfo() async => BackupFileInfo(
    fileId: 'cloud-file',
    name: 'backup_latest.enc',
    sizeBytes: 4096,
    modifiedAt: DateTime(2026, 4, 29, 10, 5),
  );

  @override
  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    final startedAt = DateTime(2026, 4, 29, 10, 10);
    onProgress?.call(
      BackupProgressState(
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.downloading,
        currentStep: 2,
        totalSteps: 6,
        overallProgress: 0.25,
        processedBytes: 1024,
        totalBytes: 4096,
        startedAt: startedAt,
        isBlocking: true,
      ),
    );
    onProgress?.call(
      BackupProgressState(
        operation: BackupOperationKind.restore,
        stage: BackupProgressStage.importing,
        currentStep: 5,
        totalSteps: 6,
        overallProgress: 0.84,
        processedBytes: 4096,
        totalBytes: 4096,
        startedAt: startedAt,
        isBlocking: true,
      ),
    );
    await _restoreCompleter.future;
    return restoreResult;
  }

  void completeBackup() {
    if (!_backupCompleter.isCompleted) {
      _backupCompleter.complete();
    }
  }

  void completeRestore() {
    if (!_restoreCompleter.isCompleted) {
      _restoreCompleter.complete();
    }
  }

  @override
  GoogleAuthService get authService => throw UnimplementedError();

  @override
  DriveBackupService get driveService => throw UnimplementedError();

  @override
  BackupEncryptionService get encryptionService => throw UnimplementedError();

  @override
  Isar get isar => throw UnimplementedError();

  @override
  IsarExportService get exportService => throw UnimplementedError();
}
