// The Play-facing permission list is a decision, not an accident. This pins the
// app's own AndroidManifest.xml: only these permissions are DECLARED, and the ones
// a plugin would otherwise add (RECORD_AUDIO, USE_FINGERPRINT…) are explicitly
// removed/limited. (The final merged list is checked with
// `./gradlew :app:processReleaseMainManifest`; CONTRIBUTING shows how.)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

  Iterable<RegExpMatch> permissions() => RegExp(
    r'<uses-permission\b[^>]*?android:name="([^"]+)"[^>]*?/>',
    dotAll: true,
  ).allMatches(manifest);

  String tag(String name) => permissions()
      .firstWhere(
        (m) => m.group(1) == 'android.permission.$name' || m.group(1) == name,
      )
      .group(0)!;

  test('declares exactly the permissions the app uses', () {
    final declared = {
      for (final m in permissions())
        if (!m.group(0)!.contains('tools:node="remove"')) m.group(1)!,
    };
    expect(declared, {
      'com.android.vending.BILLING',
      'android.permission.POST_NOTIFICATIONS', // reminders
      'android.permission.READ_SMS', // SMS import (inbox read; no receiver)
      'android.permission.RECEIVE_BOOT_COMPLETED', // re-arm reminders after reboot
      'android.permission.USE_BIOMETRIC', // app lock
      'android.permission.VIBRATE', // notifications
      'android.permission.USE_FINGERPRINT', // API <= 27 only (see below)
    });
  });

  test('unused permissions are removed even if a plugin adds them', () {
    for (final name in [
      'RECORD_AUDIO',
      'WRITE_EXTERNAL_STORAGE',
      'SCHEDULE_EXACT_ALARM',
      'USE_EXACT_ALARM',
    ]) {
      expect(tag(name), contains('tools:node="remove"'), reason: name);
    }
  });

  test('USE_FINGERPRINT is limited to the API levels that need it', () {
    final fingerprint = tag('USE_FINGERPRINT');
    expect(fingerprint, contains('android:maxSdkVersion="27"'));
    expect(fingerprint, contains('tools:node="replace"'));
  });

  test(
    'no Android backup / device transfer: our Drive backup is the only path',
    () {
      expect(manifest, contains('android:allowBackup="false"'));
      expect(
        manifest,
        contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
      );
      final rules = File(
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      for (final section in ['cloud-backup', 'device-transfer']) {
        final block = RegExp(
          '<$section>(.*?)</$section>',
          dotAll: true,
        ).firstMatch(rules)?.group(1);
        expect(block, isNotNull, reason: section);
        for (final domain in [
          'root',
          'file',
          'database',
          'sharedpref',
          'external',
          'device_root',
          'device_file',
        ]) {
          expect(
            block,
            contains('<exclude domain="$domain" />'),
            reason: '$section/$domain',
          );
        }
        expect(block, isNot(contains('<include')), reason: section);
      }
    },
  );

  test('RECEIVE_SMS is not declared (no SMS receiver exists)', () {
    expect(manifest.contains('RECEIVE_SMS'), isFalse);
  });

  test(
    'reminders are scheduled inexactly (no exact-alarm permission needed)',
    () {
      final source = File(
        'lib/core/notifications/notification_service.dart',
      ).readAsStringSync();
      expect(
        source.contains('AndroidScheduleMode.exactAllowWhileIdle'),
        isFalse,
      );
      expect(source.contains('requestExactAlarmsPermission'), isFalse);
    },
  );
}
