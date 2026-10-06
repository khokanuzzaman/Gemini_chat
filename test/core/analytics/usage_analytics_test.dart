import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/analytics/usage_analytics.dart';

class _FakeLogger implements AnalyticsLogger {
  final List<String> names = [];
  final List<Map<String, Object>?> params = [];
  final List<bool> collectionCalls = [];

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    names.add(name);
    params.add(parameters);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionCalls.add(enabled);
  }
}

void main() {
  test('opt-out: no events logged and SDK collection turned off', () async {
    final fake = _FakeLogger();
    final analytics = UsageAnalytics(fake);
    await analytics.initialize(enabled: false);

    await analytics.appOpen();
    await analytics.tabOpen('home');
    await analytics.featureOpen(AnalyticsFeature.split);
    await analytics.entryMethodUsed(AnalyticsEntryMethod.smsImport);
    await analytics.smsPermissionResult(granted: true);

    expect(fake.names, isEmpty, reason: 'opt-out must suppress every event');
    expect(fake.collectionCalls, [false]);
  });

  test('enabled: events logged with only their whitelisted params', () async {
    final fake = _FakeLogger();
    final analytics = UsageAnalytics(fake);
    await analytics.initialize(enabled: true);

    await analytics.appOpen();
    await analytics.featureOpen(AnalyticsFeature.recurring);
    await analytics.entryMethodUsed(AnalyticsEntryMethod.manualExpense);
    await analytics.smsPermissionResult(granted: false);

    expect(fake.collectionCalls, [true]);
    expect(fake.names, [
      'app_open',
      'feature_open',
      'entry_method_used',
      'sms_permission_result',
    ]);
    expect(fake.params[0], isNull);
    expect(fake.params[1], {'feature': 'recurring'});
    expect(fake.params[2], {'method': 'manual_expense'});
    expect(fake.params[3], {'granted': false});
  });

  test('split and recurring feature keys are logged distinctly (§6)', () async {
    final fake = _FakeLogger();
    final analytics = UsageAnalytics(fake);
    await analytics.initialize(enabled: true);

    await analytics.featureOpen(AnalyticsFeature.split);
    await analytics.featureOpen(AnalyticsFeature.recurring);

    expect(fake.params.map((p) => p?['feature']).toList(), [
      'split',
      'recurring',
    ]);
  });

  test('toggling off after enabled stops further events', () async {
    final fake = _FakeLogger();
    final analytics = UsageAnalytics(fake);
    await analytics.initialize(enabled: true);

    await analytics.appOpen();
    await analytics.setEnabled(false);
    await analytics.appOpen();

    expect(fake.names, ['app_open']); // only the first got through
    expect(fake.collectionCalls, [true, false]);
  });

  test('backup reminder: only the action is logged, nothing else', () async {
    final fake = _FakeLogger();
    final analytics = UsageAnalytics(fake);
    await analytics.initialize(enabled: true);

    await analytics.backupReminder(BackupReminderAction.shown);
    await analytics.backupReminder(BackupReminderAction.tapped);
    await analytics.backupReminder(BackupReminderAction.dismissed);

    expect(fake.names, everyElement('backup_reminder'));
    expect(fake.params, [
      {'action': 'shown'},
      {'action': 'tapped'},
      {'action': 'dismissed'},
    ]);

    final optedOut = _FakeLogger();
    final off = UsageAnalytics(optedOut);
    await off.initialize(enabled: false);
    await off.backupReminder(BackupReminderAction.shown);
    expect(optedOut.names, isEmpty);
  });
}
