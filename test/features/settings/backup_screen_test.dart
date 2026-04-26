import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/settings/backup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  testWidgets('shows inline progress card while manual backup is running', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final orchestrator = _FakeBackupOrchestrator();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        googleAuthServiceProvider.overrideWithValue(_FakeGoogleAuthService()),
        backupOrchestratorProvider.overrideWithValue(orchestrator),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const BackupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.text('এখনই ব্যাকআপ করুন'));
    await tester.pump();

    expect(find.byKey(const Key('backup-progress-card')), findsOneWidget);
    expect(find.text('ব্যাকআপ চলছে'), findsOneWidget);

    final accountButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'পরিবর্তন'),
    );
    expect(accountButton.onPressed, isNull);

    orchestrator.completeBackup();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('shows blocking overlay while restore is running', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final orchestrator =
        _FakeBackupOrchestrator(
            cloudInfo: BackupFileInfo(
              fileId: 'cloud-file',
              name: 'backup_latest.enc',
              sizeBytes: 4096,
              modifiedAt: DateTime(2026, 4, 29, 10, 5),
            ),
          )
          ..restoreResult = const RestoreResult(
            success: false,
            errorMessage: 'রিস্টোর ব্যর্থ হয়েছে',
          );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        googleAuthServiceProvider.overrideWithValue(_FakeGoogleAuthService()),
        backupOrchestratorProvider.overrideWithValue(orchestrator),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const BackupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    final restoreFuture = container
        .read(backupStateProvider.notifier)
        .restoreBackup();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('backup-progress-overlay')), findsOneWidget);
    expect(find.text('রিস্টোর চলছে'), findsOneWidget);

    orchestrator.completeRestore();
    await restoreFuture;
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
  });
}

class _FakeGoogleAuthService implements GoogleAuthService {
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
  _FakeBackupOrchestrator({this.cloudInfo});

  final BackupFileInfo? cloudInfo;
  final Completer<void> _backupCompleter = Completer<void>();
  final Completer<void> _restoreCompleter = Completer<void>();
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
    final startedAt = DateTime(2026, 4, 29, 10, 0);
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
  Future<BackupFileInfo?> getCloudBackupInfo() async => cloudInfo;

  @override
  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    final startedAt = DateTime(2026, 4, 29, 10, 10);
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
