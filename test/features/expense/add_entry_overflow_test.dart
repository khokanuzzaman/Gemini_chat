import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_type.dart';

import '../../helpers/add_entry_harness.dart';
import '../../helpers/app_fonts.dart';

/// R2: the add sheet on the smallest phones. Widths 320/360/411, heights 568/640/850,
/// normal and ×1.3 text, light + dark, খরচ and আয়, keyboard closed and open (note
/// focused, 280dp keyboard). The save button must ALWAYS be on screen — never pushed
/// off by the keypad, the chips or the keyboard — and nothing may overflow.
void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  const screens = <(double, double)>[(320, 568), (360, 640), (411, 850)];

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final (width, height) in screens) {
      for (final scale in [1.0, 1.3]) {
        for (final type in EntryType.values) {
          for (final keyboard in [false, true]) {
            final name =
                '${type.name}, ${width.toInt()}×${height.toInt()}, ×$scale, '
                '${brightness.name}${keyboard ? ', keyboard open' : ''}';
            testWidgets(name, (tester) async {
              final env = await newAddEntryEnv();
              tester.view.physicalSize = Size(width, height);
              tester.view.devicePixelRatio = 1;
              addTearDown(() {
                tester.view.reset();
                tester.view.resetViewInsets();
              });

              await tester.pumpWidget(
                addEntryApp(
                  env,
                  initialType: type,
                  brightness: brightness,
                  textScale: scale,
                ),
              );
              await tester.tap(find.text('open'));
              await tester.pumpAndSettle();

              var visibleBottom = height;
              if (keyboard) {
                // Real order: the user taps the note (focus -> the keypad steps
                // aside), THEN the system keyboard slides up.
                await tester.ensureVisible(find.byType(TextField));
                await tester.tap(find.byType(TextField));
                await tester.pumpAndSettle();
                tester.view.viewInsets = const FakeViewPadding(bottom: 280);
                visibleBottom = height - 280;
                await tester.pumpAndSettle();
                expect(find.text('৫'), findsNothing);
              } else {
                // Every keypad key is on screen.
                for (final key in ['১', '৫', '৯', '০', '০০']) {
                  final rect = tester.getRect(find.text(key));
                  expect(
                    rect.bottom,
                    lessThanOrEqualTo(visibleBottom),
                    reason: key,
                  );
                  expect(rect.top, greaterThanOrEqualTo(0), reason: key);
                }
              }

              expect(tester.takeException(), isNull);

              // The save button is never pushed off screen.
              final save = tester.getRect(find.text('সেভ করুন'));
              expect(save.bottom, lessThanOrEqualTo(visibleBottom));
              expect(save.top, greaterThanOrEqualTo(0));
              expect(save.left, greaterThanOrEqualTo(0));
              expect(save.right, lessThanOrEqualTo(width));

              // The amount is visible at the top without scrolling.
              final amount = tester.getRect(find.textContaining('৳'));
              expect(amount.top, greaterThanOrEqualTo(0));
              expect(amount.bottom, lessThanOrEqualTo(visibleBottom));
            });
          }
        }
      }
    }
  }
}
