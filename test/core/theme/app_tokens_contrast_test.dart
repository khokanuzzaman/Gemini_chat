import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final modes = <String, AppTokens>{
    'light': AppTokens.light,
    'dark': AppTokens.dark,
  };

  for (final entry in modes.entries) {
    final mode = entry.key;
    final t = entry.value;

    // Every surface a piece of body text can sit on.
    final surfaces = <String, Color>{
      'surface': t.surface,
      'canvas': t.canvas,
      'surface2': t.surface2,
      'primarySoft': t.primarySoft,
    };

    group('$mode — text tokens are >= 4.5:1 on every surface', () {
      final textTokens = <String, Color>{
        'ink': t.ink,
        'muted': t.muted,
        'hint': t.hint,
        'primary': t.primary,
        'successText': t.successText,
        'dangerText': t.dangerText,
        'warningText': t.warningText,
        'expenseText': t.expenseText,
      };
      for (final text in textTokens.entries) {
        for (final bg in surfaces.entries) {
          test('${text.key} on ${bg.key}', () {
            expect(
              contrast(text.value, bg.value),
              greaterThanOrEqualTo(4.5),
              reason: '${text.key} on ${bg.key} ($mode)',
            );
          });
        }
      }
    });

    group('$mode — tinted backgrounds', () {
      test('semantic text on its own soft tint', () {
        expect(
          contrast(t.successText, t.successSoft),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(t.dangerText, t.dangerSoft), greaterThanOrEqualTo(4.5));
        expect(
          contrast(t.warningText, t.warningSoft),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(t.expenseText, t.expenseSoft),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('ink and muted on the brass-soft card', () {
        expect(contrast(t.ink, t.brassSoft), greaterThanOrEqualTo(4.5));
        expect(contrast(t.muted, t.brassSoft), greaterThanOrEqualTo(4.5));
      });

      // onBrass is a dark ink for a brass FILL, so it only reads on the LIGHT
      // brass-soft card; the dark brass-soft card is itself dark (brass text).
      test('brass-soft card: accent text for this mode', () {
        if (mode == 'light') {
          expect(contrast(t.onBrass, t.brassSoft), greaterThanOrEqualTo(4.5));
        } else {
          expect(contrast(t.brass, t.brassSoft), greaterThanOrEqualTo(4.5));
        }
      });

      test('on-brass text on a brass fill', () {
        expect(contrast(t.onBrass, t.brass), greaterThanOrEqualTo(4.5));
      });
    });

    group('$mode — fills carry a white label', () {
      final fills = <String, Color>{
        'primaryFill': t.primaryFill,
        'successFill': t.successFill,
        'dangerFill': t.dangerFill,
      };
      for (final fill in fills.entries) {
        test('${fill.key}: onFill label >= 4.5:1', () {
          expect(
            contrast(t.onFill, fill.value),
            greaterThanOrEqualTo(4.5),
            reason: '${fill.key} ($mode)',
          );
        });
        test('${fill.key}: >= 3:1 against surface and canvas', () {
          expect(contrast(fill.value, t.surface), greaterThanOrEqualTo(3.0));
          expect(contrast(fill.value, t.canvas), greaterThanOrEqualTo(3.0));
        });
      }
    });

    group('$mode — non-text tones', () {
      test('success / danger / warning fill-icon tones >= 3:1', () {
        for (final tone in [t.success, t.danger, t.warning]) {
          expect(contrast(tone, t.surface), greaterThanOrEqualTo(3.0));
          expect(contrast(tone, t.canvas), greaterThanOrEqualTo(3.0));
        }
      });

      test('inputOutline >= 3:1 on every field background', () {
        for (final bg in [t.surface, t.canvas, t.surface2]) {
          expect(contrast(t.inputOutline, bg), greaterThanOrEqualTo(3.0));
        }
      });
    });

    test('$mode — hero gradient text is >= 4.5:1 on both stops', () {
      for (final stop in [t.heroStart, t.heroEnd]) {
        expect(contrast(t.onHero, stop), greaterThanOrEqualTo(4.5));
        expect(contrast(t.onHeroMuted, stop), greaterThanOrEqualTo(4.5));
      }
    });
  }

  test('brass is only allowed as TEXT/ICON on dark surfaces', () {
    // Dark: brass reads as text/icon (>= 4.5:1).
    expect(
      contrast(AppTokens.dark.brass, AppTokens.dark.surface),
      greaterThanOrEqualTo(4.5),
    );
    // Light: brass on white/canvas fails (the doc rule: fill or brassSoft only).
    expect(
      contrast(AppTokens.light.brass, AppTokens.light.surface),
      lessThan(3.0),
      reason: 'documents WHY light-mode brass must never be text/icon',
    );
  });

  test('static fill/icon constants stay >= 3:1 in BOTH modes', () {
    // These consts cannot follow dark mode, so they must be legible on both
    // palettes. (They are for fills/icons only — never text.)
    final constants = <String, Color>{
      'primaryMid': AppColors.primaryMid,
      'success': AppColors.success,
      'error': AppColors.error,
      'warning': AppColors.warning,
    };
    for (final c in constants.entries) {
      for (final t in [AppTokens.light, AppTokens.dark]) {
        for (final bg in [t.surface, t.canvas]) {
          expect(
            contrast(c.value, bg),
            greaterThanOrEqualTo(3.0),
            reason: '${c.key} on $bg',
          );
        }
      }
    }
  });

  test('hero gradient is identical in light and dark', () {
    expect(AppTokens.light.heroStart, AppTokens.dark.heroStart);
    expect(AppTokens.light.heroEnd, AppTokens.dark.heroEnd);
  });
}
