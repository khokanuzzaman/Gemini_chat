import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import 'package:gemini_chat/core/theme/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled font has its OFL text on the licenses page', () async {
    registerFontLicenses();

    final byPackage = <String, String>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        byPackage[package] = entry.paragraphs.map((p) => p.text).join('\n');
      }
    }

    for (final font in ['Inter', 'Sora', 'Noto Sans Bengali']) {
      expect(byPackage, contains(font), reason: '$font license not registered');
      expect(
        byPackage[font],
        contains('SIL OPEN FONT LICENSE Version 1.1'),
        reason: '$font entry is not the OFL text',
      );
    }
  });

  test('registered assets are exactly the files shipped in pubspec', () {
    expect(fontLicenseAssets.keys, hasLength(3));
  });
}
