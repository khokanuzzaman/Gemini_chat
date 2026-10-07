import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/feature_flags.dart';
import '../logging/app_logger.dart';
import '../network/connectivity_provider.dart';
import '../../features/anomaly/presentation/providers/anomaly_provider.dart';
import '../../features/budget/presentation/providers/budget_provider.dart';
import '../../features/category/presentation/providers/category_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/debt/presentation/providers/debt_providers.dart';
import '../../features/expense/presentation/providers/expense_providers.dart';
import '../../features/goals/presentation/providers/goal_provider.dart';
import '../../features/income/presentation/providers/income_providers.dart';
import '../../features/prediction/presentation/providers/prediction_provider.dart';
import '../../features/recurring/presentation/providers/recurring_provider.dart';
import '../../features/sms_import/presentation/providers/sms_history_provider.dart';
import '../../features/sms_import/presentation/providers/sms_import_provider.dart';
import '../../features/split/presentation/providers/split_bill_provider.dart';
import '../../features/wallet/presentation/providers/wallet_provider.dart';
import '../providers/database_providers.dart';
import '../providers/shared_preferences_provider.dart';
import '../premium/premium_providers.dart';
import '../usage/usage_limits.dart';
import '../usage/usage_providers.dart';
import 'auto_backup_coordinator.dart';
import 'backup_encryption_service.dart';
import 'backup_exception.dart';
import 'backup_models.dart';
import 'backup_orchestrator.dart';
import 'backup_reminder_provider.dart';
import 'backup_progress.dart';
import 'drive_backup_service.dart';
import 'google_auth_service.dart';
import 'isar_export_service.dart';

/// Shown when the daily manual-backup quota is used. Mentions Premium only in a
/// build that actually offers it.
const _backupLimitMessage = FeatureFlags.premiumEnabled
    ? 'আজকের ব্যাকআপ সীমা শেষ। Premium এ স্বয়ংক্রিয় ব্যাকআপ পাবেন।'
    : 'আজকের ব্যাকআপ সীমা শেষ। আগামীকাল আবার ব্যাকআপ নিতে পারবেন।';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final driveBackupServiceProvider = Provider<DriveBackupService>((ref) {
  return DriveBackupService(ref.read(googleAuthServiceProvider));
});

final backupOrchestratorProvider = Provider<BackupOrchestrator>((ref) {
  return BackupOrchestrator(
    exportService: IsarExportService(),
    encryptionService: BackupEncryptionService(),
    driveService: ref.read(driveBackupServiceProvider),
    authService: ref.read(googleAuthServiceProvider),
    isar: ref.read(isarProvider),
  );
});

final autoBackupCoordinatorProvider = Provider<AutoBackupCoordinator>((ref) {
  return AutoBackupCoordinator(
    prefs: ref.read(sharedPreferencesProvider),
    isOnline: () => ref.read(connectivityServiceProvider).isConnected(),
    // null = unknown (e.g. RevenueCat unreachable): never treated as "free".
    isPremium: () async {
      if (ref.read(isPremiumProvider)) {
        return true;
      }
      try {
        return (await ref.read(premiumServiceProvider).getStatus()).isPremium;
      } catch (_) {
        return null;
      }
    },
    ensureSignedIn: () async {
      final auth = ref.read(googleAuthServiceProvider);
      try {
        if (await auth.isSignedIn()) {
          return true;
        }
        await auth.signInSilently();
        return await auth.isSignedIn();
      } catch (_) {
        return false;
      }
    },
    runBackup: () => ref.read(backupOrchestratorProvider).createBackup(),
    isManualBusy: () =>
        ref.exists(backupStateProvider) &&
        (ref.read(backupStateProvider).valueOrNull?.isBusy ?? false),
    onFinished: () {
      ref.invalidate(backupReminderProvider);
      if (ref.exists(backupStateProvider)) {
        unawaited(ref.read(backupStateProvider.notifier).reloadFromPrefs());
      }
    },
  );
});

final backupStateProvider = AsyncNotifierProvider<BackupNotifier, BackupState>(
  BackupNotifier.new,
);

final restorePromptProvider = StateProvider<BackupFileInfo?>((ref) => null);

class BackupState {
  const BackupState({
    required this.isSignedIn,
    required this.userEmail,
    required this.displayName,
    required this.isBackingUp,
    required this.isRestoring,
    required this.lastBackupTime,
    required this.lastBackupSizeBytes,
    required this.cloudBackupInfo,
    required this.errorMessage,
    required this.autoBackupEnabled,
    required this.activeProgress,
    required this.progressTitle,
    required this.progressDetail,
    this.autoBackupFailedAt,
    this.autoBackupErrorCode,
    this.autoBackupGrandfathered = false,
    this.grandfatherNoteDismissed = false,
  });

  factory BackupState.initial() {
    return const BackupState(
      isSignedIn: false,
      userEmail: null,
      displayName: null,
      isBackingUp: false,
      isRestoring: false,
      lastBackupTime: null,
      lastBackupSizeBytes: null,
      cloudBackupInfo: null,
      errorMessage: null,
      autoBackupEnabled: false,
      activeProgress: null,
      progressTitle: null,
      progressDetail: null,
    );
  }

  final bool isSignedIn;
  final String? userEmail;
  final String? displayName;
  final bool isBackingUp;
  final bool isRestoring;
  final DateTime? lastBackupTime;
  final int? lastBackupSizeBytes;
  final BackupFileInfo? cloudBackupInfo;
  final String? errorMessage;
  final bool autoBackupEnabled;
  final BackupProgressState? activeProgress;
  final String? progressTitle;
  final String? progressDetail;

  /// Latest failed AUTO attempt not yet followed by a success; null when OK.
  final DateTime? autoBackupFailedAt;
  final BackupErrorCode? autoBackupErrorCode;

  /// Free user who had auto-backup on before it became Premium: it keeps
  /// running until they switch it off.
  final bool autoBackupGrandfathered;
  final bool grandfatherNoteDismissed;

  bool get isBusy => isBackingUp || isRestoring;

  /// A failure only counts while it is newer than the last successful backup.
  bool get hasAutoBackupFailure {
    final failedAt = autoBackupFailedAt;
    if (failedAt == null) {
      return false;
    }
    final lastBackup = lastBackupTime;
    return lastBackup == null || failedAt.isAfter(lastBackup);
  }

  BackupState copyWith({
    bool? isSignedIn,
    Object? userEmail = _backupStateUnset,
    Object? displayName = _backupStateUnset,
    bool? isBackingUp,
    bool? isRestoring,
    Object? lastBackupTime = _backupStateUnset,
    Object? lastBackupSizeBytes = _backupStateUnset,
    Object? cloudBackupInfo = _backupStateUnset,
    Object? errorMessage = _backupStateUnset,
    bool? autoBackupEnabled,
    Object? activeProgress = _backupStateUnset,
    Object? progressTitle = _backupStateUnset,
    Object? progressDetail = _backupStateUnset,
    Object? autoBackupFailedAt = _backupStateUnset,
    Object? autoBackupErrorCode = _backupStateUnset,
    bool? autoBackupGrandfathered,
    bool? grandfatherNoteDismissed,
  }) {
    return BackupState(
      autoBackupFailedAt: autoBackupFailedAt == _backupStateUnset
          ? this.autoBackupFailedAt
          : autoBackupFailedAt as DateTime?,
      autoBackupErrorCode: autoBackupErrorCode == _backupStateUnset
          ? this.autoBackupErrorCode
          : autoBackupErrorCode as BackupErrorCode?,
      autoBackupGrandfathered:
          autoBackupGrandfathered ?? this.autoBackupGrandfathered,
      grandfatherNoteDismissed:
          grandfatherNoteDismissed ?? this.grandfatherNoteDismissed,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      userEmail: userEmail == _backupStateUnset
          ? this.userEmail
          : userEmail as String?,
      displayName: displayName == _backupStateUnset
          ? this.displayName
          : displayName as String?,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      lastBackupTime: lastBackupTime == _backupStateUnset
          ? this.lastBackupTime
          : lastBackupTime as DateTime?,
      lastBackupSizeBytes: lastBackupSizeBytes == _backupStateUnset
          ? this.lastBackupSizeBytes
          : lastBackupSizeBytes as int?,
      cloudBackupInfo: cloudBackupInfo == _backupStateUnset
          ? this.cloudBackupInfo
          : cloudBackupInfo as BackupFileInfo?,
      errorMessage: errorMessage == _backupStateUnset
          ? this.errorMessage
          : errorMessage as String?,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      activeProgress: activeProgress == _backupStateUnset
          ? this.activeProgress
          : activeProgress as BackupProgressState?,
      progressTitle: progressTitle == _backupStateUnset
          ? this.progressTitle
          : progressTitle as String?,
      progressDetail: progressDetail == _backupStateUnset
          ? this.progressDetail
          : progressDetail as String?,
    );
  }
}

const _backupStateUnset = Object();

class BackupNotifier extends AsyncNotifier<BackupState> {
  @override
  Future<BackupState> build() async {
    final auth = ref.read(googleAuthServiceProvider);
    await auth.signInSilently();
    final isSignedIn = await auth.isSignedIn();
    final prefs = ref.read(sharedPreferencesProvider);
    final initial = BackupState(
      isSignedIn: isSignedIn,
      userEmail: auth.userEmail,
      displayName: auth.displayName,
      isBackingUp: false,
      isRestoring: false,
      lastBackupTime: _readDate(
        prefs.getInt(BackupOrchestrator.backupLastTimeKey),
      ),
      lastBackupSizeBytes: prefs.getInt(BackupOrchestrator.backupLastSizeKey),
      cloudBackupInfo: null,
      errorMessage: null,
      autoBackupEnabled:
          prefs.getBool(BackupOrchestrator.autoBackupEnabledKey) ?? false,
      activeProgress: null,
      progressTitle: null,
      progressDetail: null,
      autoBackupFailedAt: _readDate(prefs.getInt(AutoBackupKeys.lastFailedAt)),
      autoBackupErrorCode: prefs.containsKey(AutoBackupKeys.lastErrorCode)
          ? BackupErrorCode.fromKey(
              prefs.getString(AutoBackupKeys.lastErrorCode),
            )
          : null,
      autoBackupGrandfathered:
          prefs.getBool(AutoBackupKeys.grandfathered) ?? false,
      grandfatherNoteDismissed:
          prefs.getBool(AutoBackupKeys.grandfatherNoteDismissed) ?? false,
    );
    if (isSignedIn) {
      // One event-loop turn later, NOT inline: refreshCloudInfo() reads `state`,
      // which is still empty while build() runs, so calling it here replaced
      // the state with BackupState.initial() (signed-out, auto-backup off).
      unawaited(Future<void>.delayed(Duration.zero, refreshCloudInfo));
    }
    return initial;
  }

  Future<bool> signIn() async {
    final current = _current;
    state = const AsyncLoading<BackupState>().copyWithPrevious(state);
    try {
      final signedIn = await ref.read(googleAuthServiceProvider).signIn();
      if (!signedIn) {
        state = AsyncData(
          current.copyWith(errorMessage: 'সাইন ইন বাতিল করা হয়েছে'),
        );
        return false;
      }

      final auth = ref.read(googleAuthServiceProvider);
      final next = current.copyWith(
        isSignedIn: true,
        userEmail: auth.userEmail,
        displayName: auth.displayName,
        errorMessage: null,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      );
      state = AsyncData(next);
      unawaited(refreshCloudInfo());
      return true;
    } catch (error) {
      AppLogger.error('Backup sign-in failed', error);
      state = AsyncData(
        current.copyWith(errorMessage: _friendlySignInError(error)),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    final current = _current;
    try {
      await ref.read(googleAuthServiceProvider).signOut();
    } catch (_) {}

    ref.read(restorePromptProvider.notifier).state = null;
    state = AsyncData(
      current.copyWith(
        isSignedIn: false,
        userEmail: null,
        displayName: null,
        cloudBackupInfo: null,
        errorMessage: null,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );
  }

  Future<void> resetLocalState() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(BackupOrchestrator.backupLastTimeKey);
    await prefs.remove(BackupOrchestrator.backupLastSizeKey);
    await prefs.remove(BackupOrchestrator.autoBackupEnabledKey);
    // Delete-all switches auto-backup off, so the grandfathering ends with it.
    await prefs.remove(AutoBackupKeys.grandfathered);
    await prefs.remove(AutoBackupKeys.lastFailedAt);
    await prefs.remove(AutoBackupKeys.lastErrorCode);
    await prefs.remove(backupReminderSnoozedUntilKey);
    ref.invalidate(backupReminderProvider);
    ref.read(restorePromptProvider.notifier).state = null;
    state = AsyncData(
      _current.copyWith(
        autoBackupFailedAt: null,
        autoBackupErrorCode: null,
        autoBackupGrandfathered: false,
        lastBackupTime: null,
        lastBackupSizeBytes: null,
        cloudBackupInfo: null,
        errorMessage: null,
        autoBackupEnabled: false,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );
  }

  /// Returns false when a free, non-grandfathered user tries to switch it ON
  /// (the screen then shows the Premium upsell). Switching OFF always works; where
  /// Premium exists it also ends any grandfathering (turning it back on then needs
  /// Premium), while in Phase 1 the grandfathering is kept.
  Future<bool> setAutoBackupEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (enabled && !await canEnableAutoBackup()) {
      return false;
    }
    await prefs.setBool(BackupOrchestrator.autoBackupEnabledKey, enabled);
    // Switching OFF ends the grandfathering — but only where Premium can actually
    // be bought. While it is hidden (Phase 1) there is nothing to upgrade to, so the
    // user keeps the right to switch it back on.
    final endsGrandfathering = !enabled && FeatureFlags.premiumEnabled;
    if (endsGrandfathering) {
      await prefs.remove(AutoBackupKeys.grandfathered);
    }
    state = AsyncData(
      _current.copyWith(
        autoBackupEnabled: enabled,
        autoBackupGrandfathered: endsGrandfathering
            ? false
            : _current.autoBackupGrandfathered,
      ),
    );
    if (enabled) {
      // Don't wait for the next resume for the first backup (24h rule still applies).
      unawaited(ref.read(autoBackupCoordinatorProvider).run());
    }
    return true;
  }

  Future<bool> canEnableAutoBackup() async {
    if (_current.autoBackupGrandfathered || await _isPremiumUser()) {
      return true;
    }
    return false;
  }

  Future<void> dismissGrandfatherNote() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AutoBackupKeys.grandfatherNoteDismissed, true);
    state = AsyncData(_current.copyWith(grandfatherNoteDismissed: true));
  }

  /// Re-reads everything a background auto-backup attempt can change.
  Future<void> reloadFromPrefs() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final failedAt = _readDate(prefs.getInt(AutoBackupKeys.lastFailedAt));
    state = AsyncData(
      _current.copyWith(
        lastBackupTime: _readDate(
          prefs.getInt(BackupOrchestrator.backupLastTimeKey),
        ),
        lastBackupSizeBytes: prefs.getInt(BackupOrchestrator.backupLastSizeKey),
        autoBackupEnabled:
            prefs.getBool(BackupOrchestrator.autoBackupEnabledKey) ?? false,
        autoBackupFailedAt: failedAt,
        autoBackupErrorCode: failedAt == null
            ? null
            : BackupErrorCode.fromKey(
                prefs.getString(AutoBackupKeys.lastErrorCode),
              ),
        autoBackupGrandfathered:
            prefs.getBool(AutoBackupKeys.grandfathered) ?? false,
        isBackingUp: false,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );
  }

  /// "আবার চেষ্টা" on the failure line. Uses the auto-backup path, so it never
  /// consumes the manual 1/day quota.
  Future<AutoBackupOutcome> retryAutoBackup() async {
    state = AsyncData(_current.copyWith(isBackingUp: true, errorMessage: null));
    final outcome = await ref
        .read(autoBackupCoordinatorProvider)
        .run(force: true);
    await reloadFromPrefs();
    if (outcome == AutoBackupOutcome.succeeded) {
      unawaited(refreshCloudInfo());
    }
    return outcome;
  }

  Future<BackupResult> createBackup() async {
    if (ref.read(autoBackupCoordinatorProvider).isRunning) {
      return const BackupResult(
        success: false,
        errorMessage: 'স্বয়ংক্রিয় ব্যাকআপ চলছে। একটু পরে চেষ্টা করুন।',
      );
    }
    if (!await _canStartManualBackup()) {
      return BackupResult(success: false, errorMessage: _backupLimitMessage);
    }

    final start = _current;
    state = AsyncData(
      start.copyWith(
        isBackingUp: true,
        errorMessage: null,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );

    final result = await ref
        .read(backupOrchestratorProvider)
        .createBackup(onProgress: _setActiveProgress);
    if (!result.success) {
      state = AsyncData(
        _current.copyWith(
          isBackingUp: false,
          errorMessage: result.errorMessage,
          activeProgress: null,
          progressTitle: null,
          progressDetail: null,
        ),
      );
      return result;
    }

    await _consumeManualBackupUsage();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(AutoBackupKeys.lastFailedAt);
    await prefs.remove(AutoBackupKeys.lastErrorCode);
    ref.invalidate(backupReminderProvider);
    final updated = _current.copyWith(
      autoBackupFailedAt: null,
      autoBackupErrorCode: null,
      isBackingUp: false,
      lastBackupTime: result.timestamp,
      lastBackupSizeBytes: result.sizeBytes,
      errorMessage: null,
      activeProgress: null,
      progressTitle: null,
      progressDetail: null,
    );
    state = AsyncData(updated);
    unawaited(refreshCloudInfo());
    return result;
  }

  Future<RestoreResult> restoreBackup() async {
    final start = _current;
    state = AsyncData(
      start.copyWith(
        isRestoring: true,
        errorMessage: null,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );

    final result = await ref
        .read(backupOrchestratorProvider)
        .restoreBackup(onProgress: _setActiveProgress);
    if (!result.success) {
      state = AsyncData(
        _current.copyWith(
          isRestoring: false,
          errorMessage: result.errorMessage,
          activeProgress: null,
          progressTitle: null,
          progressDetail: null,
        ),
      );
      return result;
    }

    await _invalidateAfterRestore();
    state = AsyncData(
      _current.copyWith(
        isRestoring: false,
        errorMessage: null,
        activeProgress: null,
        progressTitle: null,
        progressDetail: null,
      ),
    );
    ref.read(restorePromptProvider.notifier).state = null;
    return result;
  }

  Future<void> refreshCloudInfo() async {
    final current = _current;
    if (!current.isSignedIn) {
      state = AsyncData(current.copyWith(cloudBackupInfo: null));
      return;
    }

    try {
      final info = await ref
          .read(backupOrchestratorProvider)
          .getCloudBackupInfo();
      state = AsyncData(
        _current.copyWith(cloudBackupInfo: info, errorMessage: null),
      );
    } catch (error) {
      state = AsyncData(
        _current.copyWith(errorMessage: 'ক্লাউড ব্যাকআপ তথ্য আনা যায়নি'),
      );
    }
  }

  Future<bool> deleteAllBackups() async {
    try {
      await ref.read(driveBackupServiceProvider).deleteAllBackups();
      state = AsyncData(
        _current.copyWith(cloudBackupInfo: null, errorMessage: null),
      );
      ref.read(restorePromptProvider.notifier).state = null;
      return true;
    } on BackupException catch (error) {
      state = AsyncData(_current.copyWith(errorMessage: error.message));
      return false;
    } catch (error) {
      state = AsyncData(
        _current.copyWith(errorMessage: 'ব্যাকআপ মুছতে সমস্যা হয়েছে'),
      );
      return false;
    }
  }

  BackupState get _current => state.valueOrNull ?? BackupState.initial();

  void _setActiveProgress(BackupProgressState progress) {
    state = AsyncData(
      _current.copyWith(
        isBackingUp: progress.operation == BackupOperationKind.backup,
        isRestoring: progress.operation == BackupOperationKind.restore,
        activeProgress: progress,
        progressTitle: _progressTitle(progress),
        progressDetail: _progressDetail(progress),
        errorMessage: null,
      ),
    );
  }

  DateTime? _readDate(int? millis) {
    if (millis == null || millis <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  String _friendlySignInError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('operation-not-allowed')) {
      return 'Firebase Authentication এ Google Sign-In চালু নেই। Firebase Console -> Authentication -> Sign-in method থেকে Google enable করুন।';
    }
    if (raw.contains('sign_in_failed') ||
        raw.contains('clientconfigurationerror') ||
        raw.contains('12500') ||
        raw.contains('apiexception: 10') ||
        raw.contains('developer_error')) {
      return 'Google Sign-In configure করা নেই। SHA-1, package name, আর google-services.json আবার check করুন।';
    }
    if (raw.contains('network')) {
      return 'নেটওয়ার্ক সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
    return 'সাইন ইন ব্যর্থ হয়েছে';
  }

  Future<void> _invalidateAfterRestore() async {
    ref.read(expenseRefreshTokenProvider.notifier).state++;
    ref.read(incomeRefreshTokenProvider.notifier).state++;
    ref.read(debtRefreshTokenProvider.notifier).state++;
    ref.invalidate(walletProvider);
    ref.invalidate(categoryProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(debtListProvider);
    ref.invalidate(splitBillProvider);
    ref.invalidate(budgetProvider);
    ref.invalidate(incomeListControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(recurringProvider);
    ref.invalidate(chatProvider);
    ref.invalidate(smsImportStatusProvider);
    ref.invalidate(smsImportControllerProvider);
    ref.invalidate(smsHistoryControllerProvider);
    ref.invalidate(smsAutoImportProvider);
    ref.invalidate(anomalyProvider);
    ref.invalidate(predictionProvider);
  }

  /// Gate only — does NOT consume. The daily manual-backup allowance is spent
  /// by [_consumeManualBackupUsage] after the upload SUCCEEDS, so a network
  /// glitch never burns the day's backup.
  Future<bool> _canStartManualBackup() async {
    if (await _isPremiumUser()) {
      return true;
    }

    try {
      final reached = await ref
          .read(usageTrackerServiceProvider)
          .hasReachedLimit(UsageLimits.cloudBackup);
      if (reached) {
        state = AsyncData(
          _current.copyWith(
            isBackingUp: false,
            errorMessage: _backupLimitMessage,
            activeProgress: null,
            progressTitle: null,
            progressDetail: null,
          ),
        );
        return false;
      }
      return true;
    } catch (_) {
      // Usage tracking is best-effort: never block a backup on it.
      return true;
    }
  }

  /// Spends one manual backup for today. Called only after a successful upload.
  Future<void> _consumeManualBackupUsage() async {
    if (await _isPremiumUser()) {
      return;
    }

    try {
      await ref
          .read(usageTrackerServiceProvider)
          .increment(UsageLimits.cloudBackup);
      ref.read(usageRefreshTokenProvider.notifier).state++;
    } catch (_) {
      // Best-effort, as above.
    }
  }

  Future<bool> _isPremiumUser() async {
    if (ref.read(isPremiumProvider)) {
      return true;
    }

    try {
      return await ref.read(premiumServiceProvider).isPremium();
    } catch (_) {
      return false;
    }
  }
}

String _progressTitle(BackupProgressState progress) {
  return switch (progress.operation) {
    BackupOperationKind.backup
        when progress.stage == BackupProgressStage.failed =>
      'ব্যাকআপ সম্পন্ন হয়নি',
    BackupOperationKind.backup
        when progress.stage == BackupProgressStage.completed =>
      'ব্যাকআপ সম্পন্ন',
    BackupOperationKind.backup => 'ব্যাকআপ চলছে',
    BackupOperationKind.restore
        when progress.stage == BackupProgressStage.failed =>
      'রিস্টোর সম্পন্ন হয়নি',
    BackupOperationKind.restore
        when progress.stage == BackupProgressStage.completed =>
      'রিস্টোর সম্পন্ন',
    BackupOperationKind.restore => 'রিস্টোর চলছে',
  };
}

String _progressDetail(BackupProgressState progress) {
  return switch (progress.stage) {
    BackupProgressStage.preparing => 'প্রস্তুতি নেওয়া হচ্ছে',
    BackupProgressStage.exporting => 'ডেটা এক্সপোর্ট করা হচ্ছে',
    BackupProgressStage.compressing => 'ডেটা কম্প্রেস করা হচ্ছে',
    BackupProgressStage.encrypting => 'ব্যাকআপ ফাইল তৈরি হচ্ছে',
    BackupProgressStage.uploading => 'Google Drive-এ আপলোড করা হচ্ছে',
    BackupProgressStage.downloading => 'Google Drive থেকে ডাউনলোড করা হচ্ছে',
    BackupProgressStage.decrypting => 'ব্যাকআপ ফাইল পড়া হচ্ছে',
    BackupProgressStage.decoding => 'ব্যাকআপ ফাইল খোলা হচ্ছে',
    BackupProgressStage.importing => 'ডেটা রিস্টোর করা হচ্ছে',
    BackupProgressStage.finalizing => 'শেষ কাজগুলো সম্পন্ন হচ্ছে',
    BackupProgressStage.completed
        when progress.operation == BackupOperationKind.backup =>
      'ব্যাকআপ আপনার Google Drive-এ সংরক্ষণ করা হয়েছে',
    BackupProgressStage.completed => 'Drive ব্যাকআপ থেকে ডেটা ফিরে এসেছে',
    BackupProgressStage.failed
        when progress.operation == BackupOperationKind.backup =>
      'ব্যাকআপ করার সময় সমস্যা হয়েছে',
    BackupProgressStage.failed => 'রিস্টোর করার সময় সমস্যা হয়েছে',
  };
}
