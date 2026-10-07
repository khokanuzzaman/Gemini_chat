import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:gemini_chat/core/usage/usage_limits.dart';
import 'package:gemini_chat/core/usage/usage_providers.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakePremium extends PremiumNotifier {
  _FakePremium(this.isPremium);
  final bool isPremium;

  @override
  Future<PremiumStatus> build() async => PremiumStatus(isPremium: isPremium);
}

class _MockPremiumService extends Mock implements PremiumService {}

class _Auth implements GoogleAuthService {
  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<void> reauthenticate() async {}

  @override
  String? get displayName => 'T';
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
  String? get userEmail => 't@example.com';
  @override
  String? get userId => 'u1';
}

class _Orchestrator implements BackupOrchestrator {
  int calls = 0;
  BackupResult result = BackupResult(success: true, timestamp: DateTime.now());

  @override
  Future<BackupResult> createBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    calls++;
    return result;
  }

  @override
  Future<BackupFileInfo?> getCloudBackupInfo() async => null;

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
  @override
  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async => const RestoreResult(success: true);
}

class _Env {
  _Env(this.prefs, {required bool premium}) {
    final auth = _MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(null); // local counter only
    usage = UsageTrackerService(
      firebaseAuth: auth,
      firestore: FakeFirebaseFirestore(),
      prefs: prefs,
    );
    final premiumService = _MockPremiumService();
    when(() => premiumService.isPremium()).thenAnswer((_) async => premium);
    when(
      () => premiumService.getStatus(),
    ).thenAnswer((_) async => PremiumStatus(isPremium: premium));
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        googleAuthServiceProvider.overrideWithValue(_Auth()),
        backupOrchestratorProvider.overrideWithValue(orchestrator),
        usageTrackerServiceProvider.overrideWithValue(usage),
        premiumStatusProvider.overrideWith(() => _FakePremium(premium)),
        premiumServiceProvider.overrideWithValue(premiumService),
      ],
    );
  }

  final SharedPreferences prefs;
  final orchestrator = _Orchestrator();
  late final UsageTrackerService usage;
  late final ProviderContainer container;

  Future<int> used() => usage.getCount(UsageLimits.cloudBackup);

  Future<BackupResult> manualBackup() async {
    await container.read(backupStateProvider.future);
    return container.read(backupStateProvider.notifier).createBackup();
  }
}

Future<_Env> _env({required bool premium}) async {
  SharedPreferences.setMockInitialValues({});
  return _Env(await SharedPreferences.getInstance(), premium: premium);
}

void main() {
  test('a FAILED manual backup does not spend the day\'s quota', () async {
    final env = await _env(premium: false);
    addTearDown(env.container.dispose);
    env.orchestrator.result = const BackupResult(
      success: false,
      errorMessage: 'ইন্টারনেট সংযোগ নেই',
    );

    final failed = await env.manualBackup();
    expect(failed.success, isFalse);
    expect(await env.used(), 0, reason: 'failure must not consume');

    // The user fixes the network and tries again: allowed.
    env.orchestrator.result = BackupResult(
      success: true,
      timestamp: DateTime.now(),
    );
    final retry = await env.manualBackup();
    expect(retry.success, isTrue);
    expect(env.orchestrator.calls, 2);
    expect(await env.used(), 1);
  });

  test(
    'a SUCCESSFUL manual backup spends it, and the next one is blocked',
    () async {
      final env = await _env(premium: false);
      addTearDown(env.container.dispose);

      expect((await env.manualBackup()).success, isTrue);
      expect(await env.used(), 1);

      final second = await env.manualBackup();
      expect(second.success, isFalse);
      expect(second.errorMessage, contains('সীমা শেষ'));
      expect(env.orchestrator.calls, 1, reason: 'blocked BEFORE any upload');
      expect(await env.used(), 1, reason: 'a blocked attempt spends nothing');
    },
  );

  test('Premium: unlimited and never counted', () async {
    final env = await _env(premium: true);
    addTearDown(env.container.dispose);

    for (var i = 0; i < 3; i++) {
      expect((await env.manualBackup()).success, isTrue);
    }
    expect(env.orchestrator.calls, 3);
    expect(await env.used(), 0);
  });

  test('a throwing usage tracker never blocks a backup', () async {
    final env = await _env(premium: false);
    addTearDown(env.container.dispose);
    final broken = _MockUsageTracker();
    when(() => broken.hasReachedLimit(any())).thenThrow(StateError('x'));
    when(() => broken.increment(any())).thenThrow(StateError('x'));
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(env.prefs),
        googleAuthServiceProvider.overrideWithValue(_Auth()),
        backupOrchestratorProvider.overrideWithValue(env.orchestrator),
        usageTrackerServiceProvider.overrideWithValue(broken),
        premiumStatusProvider.overrideWith(() => _FakePremium(false)),
        premiumServiceProvider.overrideWithValue(_freeService()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(backupStateProvider.future);
    final result = await container
        .read(backupStateProvider.notifier)
        .createBackup();
    expect(result.success, isTrue);
  });
}

class _MockUsageTracker extends Mock implements UsageTrackerService {}

PremiumService _freeService() {
  final service = _MockPremiumService();
  when(() => service.isPremium()).thenAnswer((_) async => false);
  when(
    () => service.getStatus(),
  ).thenAnswer((_) async => const PremiumStatus.free());
  return service;
}
