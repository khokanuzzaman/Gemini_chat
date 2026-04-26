import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:gemini_chat/core/premium/premium_providers.dart';
import 'package:gemini_chat/core/premium/premium_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/usage/usage_gate_result.dart';
import 'package:gemini_chat/core/usage/usage_limits.dart';
import 'package:gemini_chat/core/usage/usage_providers.dart';
import 'package:gemini_chat/core/usage/usage_status.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';

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

    test('free users are blocked after daily manual backup limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = _FakeGoogleAuthService();
      final orchestrator = _FakeBackupOrchestrator();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.cloudBackup: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.cloudBackup,
              used: 1,
              limit: 1,
              isMonthly: false,
              resetAt: DateTime(2026, 4, 30),
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(auth),
          backupOrchestratorProvider.overrideWithValue(orchestrator),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: false),
          ),
          isPremiumProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupStateProvider.future);
      final result = await container
          .read(backupStateProvider.notifier)
          .createBackup();

      expect(result.success, isFalse);
      expect(orchestrator.createBackupCalls, 0);
      expect(
        container.read(backupStateProvider).valueOrNull?.errorMessage,
        'আজকের ব্যাকআপ সীমা শেষ। Premium এ স্বয়ংক্রিয় ব্যাকআপ পাবেন।',
      );
    });

    test('premium users bypass daily backup limit', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = _FakeGoogleAuthService();
      final orchestrator = _FakeBackupOrchestrator();
      final usageService = _FakeUsageTrackerService(
        results: {
          UsageLimits.cloudBackup: UsageGateResult.blocked(
            UsageStatus(
              feature: UsageLimits.cloudBackup,
              used: 1,
              limit: 1,
              isMonthly: false,
              resetAt: DateTime(2026, 4, 30),
            ),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          googleAuthServiceProvider.overrideWithValue(auth),
          backupOrchestratorProvider.overrideWithValue(orchestrator),
          usageTrackerServiceProvider.overrideWithValue(usageService),
          premiumServiceProvider.overrideWithValue(
            _FakePremiumService(isPremiumUser: true),
          ),
          isPremiumProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      await container.read(backupStateProvider.future);
      final future = container
          .read(backupStateProvider.notifier)
          .createBackup();
      await Future<void>.delayed(Duration.zero);
      orchestrator.completeBackup();
      final result = await future;

      expect(result.success, isTrue);
      expect(orchestrator.createBackupCalls, 1);
      expect(usageService.checkCalls, isEmpty);
    });
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

class _FakeUsageTrackerService implements UsageTrackerService {
  _FakeUsageTrackerService({required this.results});

  final Map<String, UsageGateResult> results;
  final List<String> checkCalls = [];

  @override
  FirebaseAuth get firebaseAuth => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  SharedPreferences get prefs => throw UnimplementedError();

  @override
  Future<UsageGateResult> checkAndConsume(String feature) async {
    checkCalls.add(feature);
    return results[feature] ??
        UsageGateResult.allowed(
          UsageStatus(
            feature: feature,
            used: 1,
            limit: UsageLimits.limitFor(feature),
            isMonthly: UsageLimits.isMonthly(feature),
            resetAt: DateTime(2026, 4, 30),
          ),
        );
  }

  @override
  Future<Map<String, UsageStatus>> getAllStatuses() async => const {};

  @override
  Future<int> getCount(String feature) async => 0;

  @override
  Future<UsageStatus> getStatus(String feature) async => UsageStatus(
    feature: feature,
    used: 0,
    limit: UsageLimits.limitFor(feature),
    isMonthly: UsageLimits.isMonthly(feature),
    resetAt: DateTime(2026, 4, 30),
  );

  @override
  Future<bool> hasReachedLimit(String feature) async =>
      !(results[feature]?.isAllowed ?? true);

  @override
  Future<void> increment(String feature) async {}

  @override
  Future<void> syncFromFirestore() async {}
}

class _FakePremiumService implements PremiumService {
  _FakePremiumService({required this.isPremiumUser});

  final bool isPremiumUser;

  @override
  RevenueCatKeyMode get keyMode => RevenueCatKeyMode.production;

  @override
  bool get isUsingTestStore => false;

  @override
  bool get hasUsableSdkKey => true;

  @override
  String? get configurationWarningBn => null;

  @override
  void setMockPremium(bool enabled) {}

  @override
  Future<PremiumStatus> getStatus() async => isPremiumUser
      ? const PremiumStatus(isPremium: true, activeProductId: 'premium_yearly')
      : const PremiumStatus.free();

  @override
  Future<List<PremiumPackage>> getOfferings() async => const [];

  @override
  Future<void> initialize({String? userId}) async {}

  @override
  Future<bool> isPremium() async => isPremiumUser;

  @override
  Future<PurchaseResult> purchase(PremiumPackage package) async =>
      const PurchaseResult.error('unused');

  @override
  Future<PurchaseResult> restorePurchases() async =>
      const PurchaseResult.error('unused');

  @override
  Future<void> syncUserId(String? userId) async {}
}
