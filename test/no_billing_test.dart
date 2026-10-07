// v1 is free for everyone: there is no Premium, paywall, upgrade or purchase code or
// text anywhere. If you add a paid tier later, this test is the thing to change — on
// purpose, together with the Play listing, the Data Safety form and the permission list.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no Dart file imports a purchase / billing library', () {
    final offenders = <String>[];
    for (final root in ['lib', 'test']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('no_billing_test.dart')) continue;
        for (final line in entity.readAsLinesSync()) {
          if (RegExp(
            r"^import\s+'package:(purchases_flutter|purchases_ui_flutter|in_app_purchase\w*)/",
          ).hasMatch(line)) {
            offenders.add('${entity.path}: $line');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
    'no user-visible string mentions Premium, subscription, upgrade or "free for now"',
    () {
      final claim = RegExp(
        r'premium|প্রিমিয়াম|subscri|সাবস্ক্রিপশন|upgrade|আপগ্রেড|paywall|কিনুন|free for now|আপাতত ফ্রি',
        caseSensitive: false,
      );
      // Not UI text: merchant keywords the SMS matcher looks for ("YouTube Premium"),
      // and the legacy Firestore path the account deletion still erases.
      const allowed = {
        'lib/core/sms/sms_category_mapper.dart',
        'lib/core/auth/user_cloud_data.dart',
      };
      final literal = RegExp(
        r"'(?:[^'\\\n]|\\.)*'|"
        r'"(?:[^"\\\n]|\\.)*"',
      );
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') || allowed.contains(entity.path)) {
          continue;
        }
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//') || line.startsWith('import ')) continue;
          for (final match in literal.allMatches(lines[i])) {
            if (claim.hasMatch(match.group(0)!)) {
              offenders.add('${entity.path}:${i + 1}: ${match.group(0)}');
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    },
  );

  test('the Premium flag and module are gone', () {
    expect(Directory('lib/core/premium').existsSync(), isFalse);
    expect(
      File('lib/features/settings/premium_screen.dart').existsSync(),
      isFalse,
    );
    final flags = File('lib/core/config/feature_flags.dart').readAsStringSync();
    expect(flags.contains('premiumEnabled'), isFalse);
    expect(flags.contains('PREMIUM_ENABLED'), isFalse);
  });
}
