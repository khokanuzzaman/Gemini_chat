import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';
import 'backup_exception.dart';
import 'backup_models.dart';
import 'backup_orchestrator.dart';

/// SharedPreferences keys owned by the auto-backup policy (G2).
class AutoBackupKeys {
  const AutoBackupKeys._();

  static const enabled = BackupOrchestrator.autoBackupEnabledKey;
  static const lastSuccessAt = BackupOrchestrator.backupLastTimeKey;

  /// Epoch-ms of the latest FAILED attempt, cleared by any later success.
  static const lastFailedAt = 'auto_backup_last_failed_at';

  /// [BackupErrorCode.key] of that failure. No messages, no account data.
  static const lastErrorCode = 'auto_backup_last_error_code';

  /// Existing free users who already had auto-backup on when it became Premium
  /// keep it (one-time migration), until they switch it off.
  static const grandfathered = 'auto_backup_grandfathered';
  static const policyApplied = 'auto_backup_policy_applied';
  static const grandfatherNoteDismissed =
      'auto_backup_grandfather_note_dismissed';

  /// First time a G2+ build ran: the only install-age marker the app has.
  static const firstSeenAt = 'app_first_seen_at';
}

enum AutoBackupOutcome {
  skippedDisabled,
  skippedPremiumUnknown,
  skippedNotAllowed,
  skippedRecentBackup,
  skippedBusy,
  skippedBackoff,
  skippedOffline,
  succeeded,
  failed,
}

/// Runs the silent daily backup. Pure orchestration over injected functions so
/// every rule is unit-testable.
///
/// * Triggered on cold start AND every resume; each trigger re-evaluates the
///   rules, so a long-lived process still backs up.
/// * **Offline is a skip, not a failure** — nothing is recorded, we just wait.
/// * A real failure is logged (cause code only) and stored so Settings can show
///   "শেষ ব্যাকআপ ব্যর্থ"; a failed attempt isn't retried for [retryBackoff].
/// * Never touches the manual-backup usage quota: its own accounting is the
///   24-hour gap and the retry backoff.
class AutoBackupCoordinator {
  AutoBackupCoordinator({
    required SharedPreferences prefs,
    required Future<bool> Function() isOnline,
    required Future<bool?> Function() isPremium,
    required Future<bool> Function() ensureSignedIn,
    required Future<BackupResult> Function() runBackup,
    required bool Function() isManualBusy,
    DateTime Function()? clock,
    void Function()? onFinished,
    this.minGap = const Duration(hours: 24),
    this.retryBackoff = const Duration(hours: 1),
  }) : _prefs = prefs,
       _isOnline = isOnline,
       _isPremium = isPremium,
       _ensureSignedIn = ensureSignedIn,
       _runBackup = runBackup,
       _isManualBusy = isManualBusy,
       _clock = clock ?? DateTime.now,
       _onFinished = onFinished;

  final SharedPreferences _prefs;
  final Future<bool> Function() _isOnline;
  final Future<bool?> Function() _isPremium;
  final Future<bool> Function() _ensureSignedIn;
  final Future<BackupResult> Function() _runBackup;
  final bool Function() _isManualBusy;
  final DateTime Function() _clock;
  final void Function()? _onFinished;
  final Duration minGap;
  final Duration retryBackoff;

  bool _running = false;

  /// True while an attempt is in flight (the manual button refuses meanwhile).
  bool get isRunning => _running;

  /// [force] is the user pressing "আবার চেষ্টা": skips the 24h gap and the retry
  /// backoff (and the "manual backup in progress" check, since the caller owns it)
  /// but still needs the setting, eligibility, connectivity and sign-in.
  Future<AutoBackupOutcome> run({bool force = false}) async {
    if (_running) {
      return AutoBackupOutcome.skippedBusy;
    }
    _running = true;
    try {
      return await _run(force: force);
    } catch (error) {
      AppLogger.debug('auto-backup coordinator error: ${error.runtimeType}');
      return AutoBackupOutcome.failed;
    } finally {
      _running = false;
    }
  }

  Future<AutoBackupOutcome> _run({required bool force}) async {
    final now = _clock();
    _markFirstSeen(now);

    // One-time policy migration needs a KNOWN premium status.
    if (!(_prefs.getBool(AutoBackupKeys.policyApplied) ?? false)) {
      final premium = await _isPremium();
      if (premium == null) {
        return AutoBackupOutcome.skippedPremiumUnknown;
      }
      final enabled = _prefs.getBool(AutoBackupKeys.enabled) ?? false;
      await _prefs.setBool(AutoBackupKeys.grandfathered, enabled && !premium);
      await _prefs.setBool(AutoBackupKeys.policyApplied, true);
    }

    if (!(_prefs.getBool(AutoBackupKeys.enabled) ?? false)) {
      return AutoBackupOutcome.skippedDisabled;
    }

    if (!(_prefs.getBool(AutoBackupKeys.grandfathered) ?? false)) {
      final premium = await _isPremium();
      if (premium == null) {
        return AutoBackupOutcome.skippedPremiumUnknown;
      }
      if (!premium) {
        return AutoBackupOutcome.skippedNotAllowed;
      }
    }

    if (!force) {
      final lastSuccess = _readDate(AutoBackupKeys.lastSuccessAt);
      if (lastSuccess != null && now.difference(lastSuccess) < minGap) {
        return AutoBackupOutcome.skippedRecentBackup;
      }
      if (_isManualBusy()) {
        return AutoBackupOutcome.skippedBusy;
      }
      final lastFailed = _readDate(AutoBackupKeys.lastFailedAt);
      if (lastFailed != null && now.difference(lastFailed) < retryBackoff) {
        return AutoBackupOutcome.skippedBackoff;
      }
    }

    // Live check at the moment of the attempt (the app-wide provider starts
    // optimistic). Offline: wait quietly — it is not a fault.
    if (!await _isOnline()) {
      return AutoBackupOutcome.skippedOffline;
    }

    if (!await _ensureSignedIn()) {
      await _recordFailure(now, BackupErrorCode.auth);
      return AutoBackupOutcome.failed;
    }

    final BackupResult result;
    try {
      result = await _runBackup();
    } catch (error) {
      await _recordFailure(now, BackupErrorCode.unknown);
      return AutoBackupOutcome.failed;
    }

    if (!result.success) {
      await _recordFailure(now, result.errorCode ?? BackupErrorCode.unknown);
      return AutoBackupOutcome.failed;
    }

    await _prefs.remove(AutoBackupKeys.lastFailedAt);
    await _prefs.remove(AutoBackupKeys.lastErrorCode);
    _onFinished?.call();
    return AutoBackupOutcome.succeeded;
  }

  Future<void> _recordFailure(DateTime now, BackupErrorCode code) async {
    AppLogger.debug('auto-backup failed: ${code.key}');
    await _prefs.setInt(
      AutoBackupKeys.lastFailedAt,
      now.millisecondsSinceEpoch,
    );
    await _prefs.setString(AutoBackupKeys.lastErrorCode, code.key);
    _onFinished?.call();
  }

  void _markFirstSeen(DateTime now) {
    if (!_prefs.containsKey(AutoBackupKeys.firstSeenAt)) {
      _prefs.setInt(AutoBackupKeys.firstSeenAt, now.millisecondsSinceEpoch);
    }
  }

  DateTime? _readDate(String key) {
    final millis = _prefs.getInt(key);
    if (millis == null || millis <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
