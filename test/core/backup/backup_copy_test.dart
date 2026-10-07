// Copy honesty: the backup key is derived from the account id (not secret), so
// nothing the user can read may claim the backup is "encrypted". Describe WHERE it
// goes ("আপনার নিজের Google Drive-এ"), not how it is protected. If a user passphrase
// is added later, this test is the thing to relax — deliberately, with the claim.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no in-app string claims encryption', () {
    final claim = RegExp(
      r'encrypt|decrypt|এনক্রিপ্ট|ডিক্রিপ্ট',
      caseSensitive: false,
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
  });
}
