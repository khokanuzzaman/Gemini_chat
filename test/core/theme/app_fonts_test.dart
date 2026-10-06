import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';

import '../../helpers/app_fonts.dart';

const _styles = <String, TextStyle>{
  'displayLarge': AppTextStyles.displayLarge,
  'displayMedium': AppTextStyles.displayMedium,
  'titleLarge': AppTextStyles.titleLarge,
  'titleMedium': AppTextStyles.titleMedium,
  'bodyLarge': AppTextStyles.bodyLarge,
  'bodyMedium': AppTextStyles.bodyMedium,
  'bodySmall': AppTextStyles.bodySmall,
  'caption': AppTextStyles.caption,
  'heroAmount': AppTextStyles.heroAmount,
  'heroLabel': AppTextStyles.heroLabel,
  'statValue': AppTextStyles.statValue,
  'statLabel': AppTextStyles.statLabel,
  'sectionTitle': AppTextStyles.sectionTitle,
  'sectionSubtitle': AppTextStyles.sectionSubtitle,
  'chipLabel': AppTextStyles.chipLabel,
};

double _width(String family, String text, int weight) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: family,
        fontFamilyFallback: const ['NotoSansBengali'],
        fontSize: 30,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  setUpAll(loadAppFonts);

  group('AppTextStyles typography contract', () {
    test('no style tracks negatively (it breaks Bengali conjuncts)', () {
      for (final entry in _styles.entries) {
        expect(
          entry.value.letterSpacing ?? 0,
          greaterThanOrEqualTo(0),
          reason: '${entry.key} has negative letterSpacing',
        );
      }
    });

    test('every style is Inter or Sora with a Bengali fallback', () {
      for (final entry in _styles.entries) {
        expect(
          entry.value.fontFamily,
          anyOf('Inter', 'Sora'),
          reason: entry.key,
        );
        expect(
          entry.value.fontFamilyFallback,
          contains('NotoSansBengali'),
          reason: entry.key,
        );
      }
    });

    test('running text is 1.5 (Bangla), single-line figures >= 1.2', () {
      for (final name in [
        'bodyLarge',
        'bodyMedium',
        'bodySmall',
        'sectionSubtitle',
      ]) {
        expect(_styles[name]!.height, 1.5, reason: name);
      }
      for (final entry in _styles.entries) {
        expect(
          entry.value.height,
          greaterThanOrEqualTo(1.2),
          reason: entry.key,
        );
      }
    });

    test('headings are Sora, body is Inter', () {
      expect(AppTextStyles.heroAmount.fontFamily, 'Sora');
      expect(AppTextStyles.statValue.fontFamily, 'Sora');
      expect(AppTextStyles.bodyMedium.fontFamily, 'Inter');
    });

    test('big money figures sit at 600–700, not heavier', () {
      for (final style in [AppTextStyles.heroAmount, AppTextStyles.statValue]) {
        expect(style.fontWeight!.value, inInclusiveRange(600, 700));
      }
    });

    test('ThemeData applies the same families and keeps Sora headings', () {
      for (final theme in [AppTheme.lightTheme(), AppTheme.darkTheme()]) {
        expect(theme.textTheme.displayLarge!.fontFamily, 'Sora');
        expect(theme.textTheme.titleLarge!.fontFamily, 'Sora');
        expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
        // Material styles we don't override still get Inter + Bengali.
        expect(theme.textTheme.labelLarge!.fontFamily, 'Inter');
        expect(
          theme.textTheme.labelLarge!.fontFamilyFallback,
          contains('NotoSansBengali'),
        );
      }
    });
  });

  group('variable weight is selected by FontWeight alone', () {
    // The permanent form of the R0b experiment: if the engine ever stopped
    // mapping FontWeight onto the `wght` axis, all four widths would collapse
    // to one value (a variable font registered once has no static faces).
    const samples = <String, (String, String)>{
      'Inter (Latin)': ('Inter', 'Balance Total 1,234'),
      'Sora (Latin)': ('Sora', 'Balance Total 1,234'),
      'Bengali via fallback': ('Inter', '৳ ১,২৪,৯৫০ মোট সম্পদ'),
    };

    for (final entry in samples.entries) {
      test('${entry.key}: 400 < 500 < 600 < 700', () {
        final (family, text) = entry.value;
        final w = [
          for (final x in [400, 500, 600, 700]) _width(family, text, x),
        ];
        expect(w[0], lessThan(w[1]));
        expect(w[1], lessThan(w[2]));
        expect(w[2], lessThan(w[3]));
      });
    }

    test('Bengali digits are tabular at every weight (columns line up)', () {
      const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      for (final weight in [400, 500, 600, 700]) {
        final widths = [for (final d in digits) _width('Inter', d, weight)];
        final spread =
            (widths.reduce((a, b) => a > b ? a : b) -
                widths.reduce((a, b) => a < b ? a : b)) /
            widths.first;
        expect(spread, lessThan(0.01), reason: 'w$weight spread $spread');
      }
    });
  });
}
