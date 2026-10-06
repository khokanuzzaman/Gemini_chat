import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/widgets/widgets.dart';

Widget _host(ThemeData theme, Widget child) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  );
}

/// "Is something painted with this solid fill?" — either a [Material] (how the
/// action button paints) or a [Container] with a [BoxDecoration] (the chip).
Finder _filledWith(Color color) {
  return find.byWidgetPredicate((widget) {
    if (widget is Material) {
      return widget.color == color;
    }
    if (widget is Container) {
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.color == color;
    }
    return false;
  });
}

/// The colour a [Text] with [label] is drawn in.
Color? _labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label)).style?.color;
}

void main() {
  group('ThemeData is built from the tokens', () {
    test('light and dark carry their own AppTokens extension', () {
      expect(AppTheme.lightTheme().extension<AppTokens>(), AppTokens.light);
      expect(AppTheme.darkTheme().extension<AppTokens>(), AppTokens.dark);
    });

    test('canvas, card and ink come from the tokens', () {
      final light = AppTheme.lightTheme();
      expect(light.scaffoldBackgroundColor, AppTokens.light.canvas);
      expect(light.cardColor, AppTokens.light.surface);
      expect(light.colorScheme.onSurface, AppTokens.light.ink);

      final dark = AppTheme.darkTheme();
      expect(dark.scaffoldBackgroundColor, AppTokens.dark.canvas);
      expect(dark.cardColor, AppTokens.dark.surface);
      expect(dark.colorScheme.onSurface, AppTokens.dark.ink);
    });

    test(
      'text/icon primary and the button FILL are different in dark mode',
      () {
        final dark = AppTheme.darkTheme();
        // Indigo for text/icons...
        expect(dark.colorScheme.primary, AppTokens.dark.primary);
        // ...but filled controls use the deeper fill that keeps a white label.
        expect(
          dark.floatingActionButtonTheme.backgroundColor,
          AppTokens.dark.primaryFill,
        );
        expect(
          dark.floatingActionButtonTheme.foregroundColor,
          AppTokens.dark.onFill,
        );
        expect(AppTokens.dark.primaryFill, isNot(AppTokens.dark.primary));
      },
    );

    test('text-field edges use inputOutline, not the decorative outline', () {
      for (final theme in [AppTheme.lightTheme(), AppTheme.darkTheme()]) {
        final tokens = theme.extension<AppTokens>()!;
        final border =
            theme.inputDecorationTheme.enabledBorder as OutlineInputBorder;
        expect(border.borderSide.color, tokens.inputOutline);
        expect(border.borderSide.color, isNot(tokens.outline));
      }
    });
  });

  group('context.tokens', () {
    testWidgets('follows the active theme', (tester) async {
      late AppTokens seen;
      await tester.pumpWidget(
        _host(
          AppTheme.darkTheme(),
          Builder(
            builder: (context) {
              seen = context.tokens;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppTokens.dark);
    });

    testWidgets('falls back by brightness under a bare MaterialApp', (
      tester,
    ) async {
      late AppTokens seen;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              seen = context.tokens;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, AppTokens.dark);
    });

    testWidgets('legacy accessors now read from the tokens', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        _host(
          AppTheme.lightTheme(),
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(captured.incomeColor, AppTokens.light.successText);
      expect(captured.expenseColor, AppTokens.light.expenseText);
      expect(captured.primaryGradient, AppTokens.light.heroGradient);
      expect(captured.mutedSurfaceColor, AppTokens.light.surface2);
    });
  });

  group('shared widgets paint with the fill tokens', () {
    for (final entry in {
      'light': AppTheme.lightTheme(),
      'dark': AppTheme.darkTheme(),
    }.entries) {
      final tokens = entry.value.extension<AppTokens>()!;

      testWidgets('${entry.key}: primary action button', (tester) async {
        await tester.pumpWidget(
          _host(
            entry.value,
            const AppActionButton(label: 'সেভ করুন', onPressed: _noop),
          ),
        );
        expect(_filledWith(tokens.primaryFill), findsOneWidget);
        // The accessibility guarantee: a white label on that fill (>= 4.5:1).
        expect(_labelColor(tester, 'সেভ করুন'), tokens.onFill);
      });

      testWidgets('${entry.key}: success and danger buttons', (tester) async {
        await tester.pumpWidget(
          _host(
            entry.value,
            const Column(
              children: [
                AppActionButton(
                  label: 'ok',
                  variant: AppActionButtonVariant.success,
                  onPressed: _noop,
                ),
                AppActionButton(
                  label: 'del',
                  variant: AppActionButtonVariant.danger,
                  onPressed: _noop,
                ),
              ],
            ),
          ),
        );
        expect(_filledWith(tokens.successFill), findsOneWidget);
        expect(_filledWith(tokens.dangerFill), findsOneWidget);
      });

      testWidgets('${entry.key}: selected chip uses primaryFill', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(entry.value, const AppChip(label: 'Cash', selected: true)),
        );
        expect(_filledWith(tokens.primaryFill), findsOneWidget);
      });
    }
  });
}

void _noop() {}
