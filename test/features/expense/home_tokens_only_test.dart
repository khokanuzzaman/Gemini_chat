import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// R1/R2 raised the bar for the Home and add-entry widgets: they take EVERY colour from
/// `context.tokens` (or the `brassGlyph` helper). Not even the static
/// `AppColors.*` fills the global ratchet tolerates, and no colour literals.
void main() {
  for (final folder in ['home', 'add_entry']) {
    test('lib/.../widgets/$folder/ uses design tokens only', () {
      _check('lib/features/expense/presentation/widgets/$folder');
    });
  }
}

void _check(String path) {
  {
    final dir = Directory(path);
    final offenders = <String>[];
    final banned = RegExp(
      r'AppColors\.|Color\(0x|(?<![A-Za-z0-9_])Colors\.(?!white\b|black\b|transparent\b)[a-zA-Z]+',
    );
    for (final file in dir.listSync().whereType<File>()) {
      var n = 0;
      for (final line in file.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        n += banned.allMatches(line).length;
      }
      if (n > 0) offenders.add('${file.path}: $n');
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  }
}
