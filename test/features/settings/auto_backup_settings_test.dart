import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/analytics/analytics_providers.dart';
import 'package:gemini_chat/core/analytics/usage_analytics.dart';
import 'package:gemini_chat/core/backup/auto_backup_coordinator.dart';
import 'package:gemini_chat/core/backup/backup_encryption_service.dart';
import 'package:gemini_chat/core/backup/backup_exception.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_orchestrator.dart';
import 'package:gemini_chat/core/backup/backup_progress.dart';
import 'package:gemini_chat/core/backup/backup_providers.dart';
import 'package:gemini_chat/core/backup/backup_reminder_policy.dart';
import 'package:gemini_chat/core/backup/backup_reminder_provider.dart';
import 'package:gemini_chat/core/backup/drive_backup_service.dart';
import 'package:gemini_chat/core/backup/google_auth_service.dart';
import 'package:gemini_chat/core/backup/isar_export_service.dart';
import 'package:gemini_chat/core/network/connectivity_provider.dart';
import 'package:gemini_chat/core/network/connectivity_service.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/usage/usage_providers.dart';
import 'package:gemini_chat/core/usage/usage_tracker_service.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/dashboard/backup_reminder_card.dart';
import 'package:gemini_chat/features/settings/backup_screen.dart';

class _MockUsageTracker extends Mock implements UsageTrackerService {}

class _FakeConnectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> isConnected() async => online;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _FakeAuth implements GoogleAuthService {
  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<void> reauthenticate() async {}

  @override
  String? get displayName => 'Test User';
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
  String? get userEmail => 'test@example.com';
  @override
  String? get userId => 'user-1';
}

class _FakeOrchestrator implements BackupOrchestrator {
  int createCalls = 0;
  Completer<void>? gate;
  BackupResult result = BackupResult(
    success: true,
    timestamp: DateTime.now(),
    sizeBytes: 2048,
  );

  @override
  Future<BackupResult> createBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async {
    createCalls++;
    await gate?.future;
    return result;
  }

  @override
  Future<BackupFileInfo?> getCloudBackupInfo() async => null;

  @override
  Future<RestoreResult> restoreBackup({
    void Function(BackupProgressState progress)? onProgress,
  }) async => const RestoreResult(success: true);

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

class _RecordingLogger implements AnalyticsLogger {
  final events = <String>[];
  final params = <Map<String, Object>?>[];

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    events.add(name);
    params.add(parameters);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

class _Env {
  _Env({required this.prefs, this.online = true}) {
    connectivity.online = online;
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        googleAuthServiceProvider.overrideWithValue(_FakeAuth()),
        backupOrchestratorProvider.overrideWithValue(orchestrator),
        connectivityServiceProvider.overrideWithValue(connectivity),
        usageTrackerServiceProvider.overrideWithValue(usage),
        usageAnalyticsProvider.overrideWithValue(
          UsageAnalytics(logger, enabled: true),
        ),
      ],
    );
  }

  final SharedPreferences prefs;
  final bool online;
  final orchestrator = _FakeOrchestrator();
  final connectivity = _FakeConnectivity();
  final usage = _MockUsageTracker();
  final logger = _RecordingLogger();
  late final ProviderContainer container;
}

Future<_Env> _env({
  Map<String, Object> prefs = const {},
  bool online = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return _Env(prefs: await SharedPreferences.getInstance(), online: online);
}

Future<void> _pumpScreen(WidgetTester tester, _Env env) async {
  await tester.binding.setSurfaceSize(const Size(900, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: env.container,
      child: MaterialApp(
        theme: AppTheme.lightTheme(),
        home: const BackupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  test(
    'state loaded for a signed-in user reflects the saved preferences',
    () async {
      // Regression: build() used to start refreshCloudInfo() inline, which wrote
      // BackupState.initial() over the real state (signed-out, auto-backup off).
      final env = await _env(
        prefs: {
          AutoBackupKeys.enabled: true,
          AutoBackupKeys.lastFailedAt: DateTime(
            2026,
            10,
            5,
          ).millisecondsSinceEpoch,
          AutoBackupKeys.lastErrorCode: 'auth',
        },
      );
      addTearDown(env.container.dispose);

      final state = await env.container.read(backupStateProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final after = env.container.read(backupStateProvider).requireValue;

      for (final s in [state, after]) {
        expect(s.isSignedIn, isTrue);
        expect(s.autoBackupEnabled, isTrue);
        expect(s.autoBackupErrorCode, BackupErrorCode.auth);
      }
    },
  );

  group('auto-backup is free for everyone', () {
    test('anyone can switch it on and off, as often as they like', () async {
      final env = await _env();
      addTearDown(env.container.dispose);
      final notifier = env.container.read(backupStateProvider.notifier);
      await env.container.read(backupStateProvider.future);

      await notifier.setAutoBackupEnabled(true);
      expect(env.prefs.getBool(AutoBackupKeys.enabled), isTrue);
      // Switching it on also kicks off a first run; let it finish before dispose.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setAutoBackupEnabled(false);
      expect(env.prefs.getBool(AutoBackupKeys.enabled), isFalse);

      await notifier.setAutoBackupEnabled(true);
      expect(env.prefs.getBool(AutoBackupKeys.enabled), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('no entitlement or grandfathering state is stored', () async {
      final env = await _env();
      addTearDown(env.container.dispose);
      await env.container
          .read(backupStateProvider.notifier)
          .setAutoBackupEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        env.prefs.getKeys().where(
          (k) => k.contains('grandfather') || k.contains('policy'),
        ),
        isEmpty,
      );
    });
  });

  group('auto-backup never touches any usage counter', () {
    test('a successful auto-backup makes zero usage-tracker calls', () async {
      final env = await _env(prefs: {AutoBackupKeys.enabled: true});
      addTearDown(env.container.dispose);

      final outcome = await env.container
          .read(autoBackupCoordinatorProvider)
          .run();

      expect(outcome, AutoBackupOutcome.succeeded);
      expect(env.orchestrator.createCalls, 1);
      verifyZeroInteractions(env.usage);
    });

    test(
      'a FAILED auto-backup does not burn the manual quota either',
      () async {
        final env = await _env(prefs: {AutoBackupKeys.enabled: true});
        addTearDown(env.container.dispose);
        env.orchestrator.result = const BackupResult(
          success: false,
          errorCode: BackupErrorCode.drive,
        );

        expect(
          await env.container.read(autoBackupCoordinatorProvider).run(),
          AutoBackupOutcome.failed,
        );
        verifyZeroInteractions(env.usage);
      },
    );

    test(
      'a manual backup is refused while an auto-backup is mid-flight',
      () async {
        final env = await _env(prefs: {AutoBackupKeys.enabled: true});
        addTearDown(env.container.dispose);
        env.orchestrator.gate = Completer<void>();
        await env.container.read(backupStateProvider.future);

        final auto = env.container.read(autoBackupCoordinatorProvider).run();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final manual = await env.container
            .read(backupStateProvider.notifier)
            .createBackup();

        expect(manual.success, isFalse);
        expect(env.orchestrator.createCalls, 1, reason: 'no second upload');

        env.orchestrator.gate!.complete();
        expect(await auto, AutoBackupOutcome.succeeded);
      },
    );
  });

  group('Backup screen', () {
    testWidgets(
      'shows "শেষ ব্যাকআপ ব্যর্থ" with the cause, and আবার চেষ্টা recovers',
      (tester) async {
        final env = await _env(
          prefs: {
            AutoBackupKeys.enabled: true,
            AutoBackupKeys.lastFailedAt: DateTime(
              2026,
              10,
              5,
              8,
            ).millisecondsSinceEpoch,
            AutoBackupKeys.lastErrorCode: 'network',
          },
        );
        addTearDown(env.container.dispose);
        await _pumpScreen(tester, env);

        expect(find.text('শেষ ব্যাকআপ ব্যর্থ'), findsOneWidget);
        expect(find.textContaining('ইন্টারনেট সমস্যা'), findsOneWidget);

        await tester.tap(find.text('আবার চেষ্টা'));
        await tester.pumpAndSettle();

        expect(env.orchestrator.createCalls, 1);
        expect(find.text('শেষ ব্যাকআপ ব্যর্থ'), findsNothing);
        expect(env.prefs.containsKey(AutoBackupKeys.lastFailedAt), isFalse);
        verifyZeroInteractions(env.usage);
      },
    );

    testWidgets('a failure older than the last good backup is not shown', (
      tester,
    ) async {
      final env = await _env(
        prefs: {
          BackupOrchestrator.backupLastTimeKey: DateTime(
            2026,
            10,
            6,
          ).millisecondsSinceEpoch,
          AutoBackupKeys.lastFailedAt: DateTime(
            2026,
            10,
            5,
          ).millisecondsSinceEpoch,
          AutoBackupKeys.lastErrorCode: 'drive',
        },
      );
      addTearDown(env.container.dispose);
      await _pumpScreen(tester, env);
      expect(find.text('শেষ ব্যাকআপ ব্যর্থ'), findsNothing);
    });

    testWidgets(
      'auto-backup is a plain switch: no upsell, no note, no Premium',
      (tester) async {
        final env = await _env();
        addTearDown(env.container.dispose);
        await _pumpScreen(tester, env);

        expect(find.text('স্বয়ংক্রিয় ব্যাকআপ'), findsOneWidget);
        expect(find.byType(Switch), findsWidgets);
        expect(find.textContaining('Premium'), findsNothing);
        expect(find.textContaining('আপগ্রেড'), findsNothing);
        expect(
          find.byKey(const Key('auto-backup-grandfather-note')),
          findsNothing,
        );
      },
    );
  });

  group('Home reminder', () {
    testWidgets(
      'card shows the real age, "পরে" snoozes it and logs the events',
      (tester) async {
        final env = await _env();
        addTearDown(env.container.dispose);
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(env.prefs),
            usageAnalyticsProvider.overrideWithValue(
              UsageAnalytics(env.logger, enabled: true),
            ),
            backupReminderProvider.overrideWith(
              (ref) async =>
                  const BackupReminderDecision(show: true, daysSinceBackup: 30),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme(),
              home: const Scaffold(body: BackupReminderCard()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('শেষ ব্যাকআপ ৩০ দিন আগে'), findsOneWidget);
        expect(env.logger.events, ['backup_reminder']);
        expect(env.logger.params.single, {'action': 'shown'});

        await tester.tap(find.text('পরে'));
        await tester.pumpAndSettle();

        expect(env.prefs.getInt(backupReminderSnoozedUntilKey), isNotNull);
        expect(env.logger.params.last, {'action': 'dismissed'});
      },
    );

    testWidgets('never backed up -> "এখনো কোনো ব্যাকআপ নেই"', (tester) async {
      final env = await _env();
      addTearDown(env.container.dispose);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(env.prefs),
          usageAnalyticsProvider.overrideWithValue(
            UsageAnalytics(env.logger, enabled: true),
          ),
          backupReminderProvider.overrideWith(
            (ref) async => const BackupReminderDecision(show: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const Scaffold(body: BackupReminderCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('এখনো কোনো ব্যাকআপ নেই'), findsOneWidget);
    });

    testWidgets('renders nothing when there is nothing to say', (tester) async {
      final env = await _env();
      addTearDown(env.container.dispose);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(env.prefs),
          backupReminderProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: const Scaffold(body: BackupReminderCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);
      expect(find.text('পরে'), findsNothing);
    });
  });
}
