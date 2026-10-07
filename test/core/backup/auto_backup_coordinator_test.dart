import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/backup/auto_backup_coordinator.dart';
import 'package:gemini_chat/core/backup/backup_exception.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';

class _Harness {
  _Harness(this.prefs, {DateTime? now}) : now = now ?? DateTime(2026, 10, 6, 9);

  final SharedPreferences prefs;
  DateTime now;

  bool online = true;
  bool signedIn = true;
  bool manualBusy = false;
  int backups = 0;
  int finished = 0;
  BackupResult Function() backupResult = () =>
      const BackupResult(success: true);
  Object? backupThrows;

  late final AutoBackupCoordinator coordinator = AutoBackupCoordinator(
    prefs: prefs,
    clock: () => now,
    isOnline: () async => online,
    ensureSignedIn: () async => signedIn,
    isManualBusy: () => manualBusy,
    onFinished: () => finished++,
    runBackup: () async {
      backups++;
      if (backupThrows != null) {
        throw backupThrows!;
      }
      final result = backupResult();
      if (result.success) {
        // The real orchestrator records the success time.
        await prefs.setInt(
          AutoBackupKeys.lastSuccessAt,
          now.millisecondsSinceEpoch,
        );
      }
      return result;
    },
  );
}

Future<_Harness> _harness({
  bool enabled = true,
  Map<String, Object> extra = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    AutoBackupKeys.enabled: enabled,
    ...extra,
  });
  return _Harness(await SharedPreferences.getInstance());
}

void main() {
  group('eligibility rules', () {
    test('setting off -> nothing happens', () async {
      final h = await _harness(enabled: false);
      expect(await h.coordinator.run(), AutoBackupOutcome.skippedDisabled);
      expect(h.backups, 0);
    });

    test(
      'enabled, never backed up -> runs (free for everyone: no entitlement check)',
      () async {
        final h = await _harness();
        expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
        expect(h.backups, 1);
      },
    );

    test('a backup less than 24h ago blocks it; 24h later it runs', () async {
      final h = await _harness(
        extra: {
          AutoBackupKeys.lastSuccessAt: DateTime(
            2026,
            10,
            6,
            1,
          ).millisecondsSinceEpoch,
        },
      );
      expect(await h.coordinator.run(), AutoBackupOutcome.skippedRecentBackup);

      h.now = DateTime(2026, 10, 7, 1, 1);
      expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
    });

    test(
      'a MANUAL backup counts toward the 24h gap (shared last-success)',
      () async {
        final h = await _harness();
        await h.prefs.setInt(
          AutoBackupKeys.lastSuccessAt,
          h.now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        );
        expect(
          await h.coordinator.run(),
          AutoBackupOutcome.skippedRecentBackup,
        );
      },
    );

    test('manual backup/restore in progress -> waits', () async {
      final h = await _harness()
        ..manualBusy = true;
      expect(await h.coordinator.run(), AutoBackupOutcome.skippedBusy);
      expect(h.backups, 0);
    });

    test('two overlapping triggers run only one backup', () async {
      final h = await _harness();
      final first = h.coordinator.run();
      final second = h.coordinator.run();
      expect(await second, AutoBackupOutcome.skippedBusy);
      expect(await first, AutoBackupOutcome.succeeded);
      expect(h.backups, 1);
    });

    test('offline is a SKIP: nothing recorded, no failure', () async {
      final h = await _harness()
        ..online = false;
      expect(await h.coordinator.run(), AutoBackupOutcome.skippedOffline);
      expect(h.backups, 0);
      expect(h.prefs.containsKey(AutoBackupKeys.lastFailedAt), isFalse);

      h.online = true; // next resume, network is back
      expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
    });
  });

  group('failures', () {
    test('signed out -> recorded as an auth failure', () async {
      final h = await _harness()
        ..signedIn = false;
      expect(await h.coordinator.run(), AutoBackupOutcome.failed);
      expect(h.prefs.getString(AutoBackupKeys.lastErrorCode), 'auth');
      expect(
        h.prefs.getInt(AutoBackupKeys.lastFailedAt),
        h.now.millisecondsSinceEpoch,
      );
      expect(h.finished, 1, reason: 'UI is told to reload');
    });

    test('backup failure records only the cause code', () async {
      final h = await _harness();
      h.backupResult = () => const BackupResult(
        success: false,
        errorMessage: 'ইন্টারনেট সংযোগ নেই',
        errorCode: BackupErrorCode.network,
      );
      expect(await h.coordinator.run(), AutoBackupOutcome.failed);
      expect(h.prefs.getString(AutoBackupKeys.lastErrorCode), 'network');
      // No message / account data is stored anywhere.
      expect(
        h.prefs.getKeys().where((k) => k.startsWith('auto_backup')),
        everyElement(isNot(contains('message'))),
      );
    });

    test('an exception is a failure with code unknown, never thrown', () async {
      final h = await _harness()
        ..backupThrows = StateError('boom');
      expect(await h.coordinator.run(), AutoBackupOutcome.failed);
      expect(h.prefs.getString(AutoBackupKeys.lastErrorCode), 'unknown');
    });

    test(
      '1h retry backoff: no retry on the next resume, retry after an hour',
      () async {
        final h = await _harness()
          ..signedIn = false;
        await h.coordinator.run();

        h.signedIn = true;
        h.now = h.now.add(const Duration(minutes: 20));
        expect(await h.coordinator.run(), AutoBackupOutcome.skippedBackoff);
        expect(h.backups, 0);

        h.now = h.now.add(const Duration(minutes: 41));
        expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
      },
    );

    test('a success clears the stored failure', () async {
      final h = await _harness()
        ..signedIn = false;
      await h.coordinator.run();
      expect(h.prefs.containsKey(AutoBackupKeys.lastFailedAt), isTrue);

      h.signedIn = true;
      h.now = h.now.add(const Duration(hours: 2));
      expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
      expect(h.prefs.containsKey(AutoBackupKeys.lastFailedAt), isFalse);
      expect(h.prefs.containsKey(AutoBackupKeys.lastErrorCode), isFalse);
    });

    test(
      'force ("আবার চেষ্টা") skips gap/backoff/busy but not offline',
      () async {
        final h = await _harness()
          ..signedIn = false;
        await h.coordinator.run();
        h.signedIn = true;
        h.manualBusy = true;

        expect(
          await h.coordinator.run(force: true),
          AutoBackupOutcome.succeeded,
        );

        h.now = h.now.add(const Duration(minutes: 1));
        h.online = false;
        expect(
          await h.coordinator.run(force: true),
          AutoBackupOutcome.skippedOffline,
        );
      },
    );
  });

  test('auto-backup is free: nothing but the setting gates it', () async {
    // There is no entitlement/grandfathering state any more — only the setting,
    // the 24h gap, connectivity and sign-in.
    final h = await _harness();
    expect(await h.coordinator.run(), AutoBackupOutcome.succeeded);
    expect(h.backups, 1);
    expect(
      h.prefs.getKeys().where(
        (k) => k.contains('grandfather') || k.contains('policy'),
      ),
      isEmpty,
    );
  });

  test('first-seen marker is written once and never moved', () async {
    final h = await _harness();
    await h.coordinator.run();
    final first = h.prefs.getInt(AutoBackupKeys.firstSeenAt);
    expect(first, h.now.millisecondsSinceEpoch);

    h.now = h.now.add(const Duration(days: 9));
    await h.coordinator.run();
    expect(h.prefs.getInt(AutoBackupKeys.firstSeenAt), first);
  });
}
