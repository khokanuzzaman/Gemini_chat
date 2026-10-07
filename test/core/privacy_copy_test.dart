// Copy honesty (see CONTRIBUTING "Privacy claims in UI copy"): the app's database is
// not encrypted at rest and a backup is not secret, so no user-visible string may say
// data is "সুরক্ষিত"/"নিরাপদ" or that nothing leaves the phone. Say WHERE it is.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'no in-app string claims data is secure/safe or never leaves the phone',
    () {
      final claim = RegExp(
        r'সুরক্ষিত|নিরাপদ|ফোনের বাইরে কিছু যায় না|কোথাও পাঠানো|কোথাও যায় না',
      );
      final literal = RegExp(
        r"'(?:[^'\\\n]|\\.)*'|"
        r'"(?:[^"\\\n]|\\.)*"',
      );
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
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
}
