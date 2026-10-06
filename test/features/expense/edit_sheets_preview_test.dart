import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/add_entry/entry_form_parts.dart';
import 'package:gemini_chat/features/income/presentation/screens/income_list_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

/// Review aid, not an assertion: `R3_PREVIEW=1 flutter test <this file>` renders
/// both edit sheets to build/r3_preview/*.png (git-ignored) with the real fonts.
/// The host has no emoji font (wallet emojis show as boxes here only) and does not
/// draw the system keyboard.
void main() {
  final enabled = Platform.environment['R3_PREVIEW'] == '1';

  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  DateTime at(int hour, int minute) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, hour, minute);
  }

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    bool income = false,
    bool keypad = false,
    Brightness brightness = Brightness.light,
  }) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final expense = listExpense(
      id: 1,
      date: at(13, 30),
      amount: 1250,
      description: 'দুপুরের খাবার',
      walletId: 2,
    );
    final salary = listIncome(
      id: 1,
      date: at(10, 0),
      amount: 65000,
      description: 'অক্টোবরের বেতন',
    ).copyWith(note: 'বোনাস সহ', isRecurring: true);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: listApp(
          brightness: brightness,
          overrides: listOverrides(
            expenses: income ? const [] : [expense],
            incomes: income ? [salary] : const [],
            calls: ListCalls(),
          ),
          child: income ? const IncomeListBody() : const ExpenseListBody(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text(income ? 'অক্টোবরের বেতন' : 'দুপুরের খাবার'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    if (keypad) {
      await tester.tap(find.byType(EntryAmountDisplay));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
    }
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('build/r3_preview')..createSync(recursive: true);
      File(
        '${dir.path}/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  group(
    'R3 edit-sheet preview PNGs',
    skip: enabled ? false : 'set R3_PREVIEW=1',
    () {
      testWidgets('expense edit', (t) => shoot(t, 'edit_expense'));
      testWidgets(
        'expense edit, keypad open',
        (t) => shoot(t, 'edit_expense_keypad', keypad: true),
      );
      testWidgets(
        'expense edit, dark',
        (t) => shoot(t, 'edit_expense_dark', brightness: Brightness.dark),
      );
      testWidgets('income edit', (t) => shoot(t, 'edit_income', income: true));
      testWidgets(
        'income edit, keypad open',
        (t) => shoot(t, 'edit_income_keypad', income: true, keypad: true),
      );
      testWidgets(
        'income edit, dark',
        (t) => shoot(
          t,
          'edit_income_dark',
          income: true,
          brightness: Brightness.dark,
        ),
      );
    },
  );
}
