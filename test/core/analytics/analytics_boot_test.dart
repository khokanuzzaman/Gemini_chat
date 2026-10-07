// An opted-out user's launch must send NOTHING, from the first moment: the manifest
// ships with SDK collection off, the preference is read before collection is turned
// on, and UsageAnalytics is fail-closed until then.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/analytics/usage_analytics.dart';
import 'package:gemini_chat/core/preferences/app_preferences.dart';

class _Sequence implements AnalyticsLogger {
  /// Everything the SDK was asked to do, in order.
  final calls = <String>[];

  @override
  Future<void> logEvent(String name, Map<String, Object>? params) async =>
      calls.add('event:$name');

  @override
  Future<void> setCollectionEnabled(bool enabled) async =>
      calls.add('collection:$enabled');
}

void main() {
  test(
    'opted-out user, first launch: no event, collection never enabled',
    () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.analyticsEnabledKey: false,
      });
      final sdk = _Sequence();
      final analytics = UsageAnalytics(sdk);

      // Things the app can fire during start-up, before AND after the boot.
      await analytics.tabOpen('home');
      await bootAnalytics(
        analytics,
        readEnabled: AppPreferences.isAnalyticsEnabled,
      );
      await analytics.tabOpen('home');
      await analytics.featureOpen(AnalyticsFeature.smsImport);
      await analytics.entryMethodUsed(AnalyticsEntryMethod.manualExpense);

      expect(sdk.calls.where((c) => c.startsWith('event:')), isEmpty);
      expect(sdk.calls, ['collection:false']);
      expect(sdk.calls, isNot(contains('collection:true')));
    },
  );

  test(
    'opted-in user: the preference is read first, THEN collection, THEN the launch',
    () async {
      SharedPreferences.setMockInitialValues({}); // default: on
      final sdk = _Sequence();
      await bootAnalytics(
        UsageAnalytics(sdk),
        readEnabled: AppPreferences.isAnalyticsEnabled,
      );
      expect(sdk.calls, ['collection:true', 'event:app_open']);
    },
  );

  test(
    'fail-closed: before the preference is read nothing is logged, even for an opted-in user',
    () async {
      final sdk = _Sequence();
      final analytics = UsageAnalytics(sdk);
      await analytics.appOpen();
      await analytics.tabOpen('plan');
      await analytics.onboardingComplete();
      expect(sdk.calls, isEmpty);
    },
  );

  test('the Android manifest ships with SDK collection OFF', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(
      RegExp(
        r'android:name="firebase_analytics_collection_enabled"\s+android:value="false"',
      ).hasMatch(manifest),
      isTrue,
    );
  });

  test('the iOS Info.plist ships with SDK collection OFF too', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      RegExp(
        r'<key>FIREBASE_ANALYTICS_COLLECTION_ENABLED</key>\s*<false/>',
      ).hasMatch(plist),
      isTrue,
    );
  });

  test('main boots analytics through bootAnalytics (not a bare appOpen)', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('bootAnalytics('));
    expect(RegExp(r'analytics\s*\.appOpen\(\)').hasMatch(main), isFalse);
  });
}
