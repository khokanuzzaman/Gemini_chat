import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics events, in a fixed whitelist. New events must be added here — the
/// service accepts nothing else, so no free-text or sensitive value can be
/// logged by accident.
enum AnalyticsFeature {
  smsImport('sms_import'),
  analytics('analytics'),
  budget('budget'),
  goals('goals'),
  debt('debt'),
  recurring('recurring'),
  wallets('wallets'),
  categories('categories'),
  export('export'),
  split('split'),
  settings('settings');

  const AnalyticsFeature(this.key);
  final String key;
}

enum AnalyticsEntryMethod {
  manualExpense('manual_expense'),
  manualIncome('manual_income'),
  smsImport('sms_import'),
  markRecurring('mark_recurring');

  const AnalyticsEntryMethod(this.key);
  final String key;
}

enum BackupReminderAction {
  shown('shown'),
  tapped('tapped'),
  dismissed('dismissed');

  const BackupReminderAction(this.key);
  final String key;
}

/// Abstract sink so tests inject a fake instead of hitting the real SDK.
abstract class AnalyticsLogger {
  Future<void> logEvent(String name, Map<String, Object>? params);
  Future<void> setCollectionEnabled(bool enabled);
}

class FirebaseAnalyticsLogger implements AnalyticsLogger {
  const FirebaseAnalyticsLogger();

  // Accessed lazily (not in the constructor) and every call is guarded, so
  // analytics can never crash the app — e.g. if Firebase is not initialized.
  @override
  Future<void> logEvent(String name, Map<String, Object>? params) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {
      // Swallow — analytics is best-effort and must not affect the user.
    }
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (_) {
      // Swallow — see above.
    }
  }
}

/// Anonymous usage analytics.
///
/// PRIVACY (finance app): logs only the whitelisted feature-open / entry-method
/// events below — never amounts, balances, descriptions, category values, SMS
/// content, wallet names, dates, PII or tokens. Events are not tied to the
/// account or any financial record. Gated by the user's opt-out preference: when
/// disabled, nothing is logged and collection is turned off in the SDK.
class UsageAnalytics {
  /// FAIL-CLOSED: nothing is logged until [initialize] has read the user's saved
  /// preference. (The manifest also ships with SDK collection OFF, so there is no
  /// window — before this object exists or before the preference is read — in which
  /// an opted-out user's launch can be counted.) [enabled] is for tests only.
  UsageAnalytics(this._logger, {bool enabled = false}) : _enabled = enabled;

  final AnalyticsLogger _logger;
  bool _enabled;

  /// Seeds the enabled flag from the saved preference and applies it to the SDK.
  Future<void> initialize({required bool enabled}) => setEnabled(enabled);

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _logger.setCollectionEnabled(enabled);
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    if (!_enabled) {
      return;
    }
    await _logger.logEvent(name, params);
  }

  Future<void> appOpen() => _log('app_open');

  Future<void> onboardingComplete() => _log('onboarding_complete');

  Future<void> smsPermissionResult({required bool granted}) =>
      _log('sms_permission_result', {'granted': granted});

  Future<void> tabOpen(String tab) => _log('tab_open', {'tab': tab});

  Future<void> featureOpen(AnalyticsFeature feature) =>
      _log('feature_open', {'feature': feature.key});

  /// Home "no recent backup" card: shown / tapped / dismissed. No data values.
  Future<void> backupReminder(BackupReminderAction action) =>
      _log('backup_reminder', {'action': action.key});

  Future<void> entryMethodUsed(AnalyticsEntryMethod method) =>
      _log('entry_method_used', {'method': method.key});
}

/// App start-up for analytics, in the only safe order: READ the saved opt-out
/// preference first, only then turn SDK collection on (it is off in the manifest) —
/// and only then count the launch. An opted-out user's launch sends nothing, ever.
Future<bool> bootAnalytics(
  UsageAnalytics analytics, {
  required Future<bool> Function() readEnabled,
}) async {
  final enabled = await readEnabled();
  await analytics.initialize(enabled: enabled);
  await analytics.appOpen();
  return enabled;
}
