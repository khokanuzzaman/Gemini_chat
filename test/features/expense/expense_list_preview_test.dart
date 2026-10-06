import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/screens/expenses_tab_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

/// Review aid, not an assertion: `R3_PREVIEW=1 flutter test <this file>` renders
/// the খরচ tab to build/r3_preview/*.png (git-ignored) with the real fonts. The
/// host has no emoji font, so wallet emojis show as boxes here only.
void main() {
  final enabled = Platform.environment['R3_PREVIEW'] == '1';

  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  DateTime at(int daysAgo, int hour) {
    final n = DateTime.now();
    return DateTime(
      n.year,
      n.month,
      n.day,
      hour,
    ).subtract(Duration(days: daysAgo));
  }

  final expenses = [
    listExpense(
      id: 1,
      date: at(0, 13),
      amount: 180,
      description: 'দুপুরের খাবার',
    ),
    listExpense(
      id: 2,
      date: at(0, 9),
      amount: 60,
      category: 'Transport',
      description: 'রিকশা ভাড়া',
      walletId: 2,
    ),
    listExpense(id: 3, date: at(0, 8), amount: 40, description: 'চা-নাস্তা'),
    listExpense(
      id: 4,
      date: at(1, 20),
      amount: 3200,
      category: 'EMI',
      description: 'মোটরসাইকেল কিস্তি',
      source: ExpenseSource.debtPayment,
    ),
    listExpense(
      id: 5,
      date: at(1, 12),
      amount: 950,
      category: 'Shopping',
      description: 'বাজার',
    ),
    listExpense(
      id: 6,
      date: at(4, 18),
      amount: 1450,
      category: 'Bills',
      description: 'বিদ্যুৎ বিল',
      walletId: 2,
    ),
    listExpense(
      id: 7,
      date: at(4, 10),
      amount: 120,
      description: 'সকালের নাস্তা',
    ),
  ];
  final incomes = [
    listIncome(
      id: 1,
      date: at(0, 10),
      amount: 65000,
      description: 'অক্টোবরের বেতন',
    ),
    listIncome(
      id: 2,
      date: at(3, 15),
      amount: 8500,
      source: 'Freelance',
      description: 'ডিজাইন কাজ',
    ),
  ];

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    bool income = false,
    bool empty = false,
    bool search = false,
    String? query,
    Brightness brightness = Brightness.light,
  }) async {
    final key = GlobalKey();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = ListCalls();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: listApp(
          scaffold: false,
          brightness: brightness,
          overrides: listOverrides(
            expenses: empty ? const [] : expenses,
            incomes: empty ? const [] : incomes,
            calls: calls,
          ),
          child: const ExpensesTabScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    if (income) {
      await tester.tap(find.text('আয়'));
      // Two frames: the segment style animation starts on the first.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
    }
    if (search) {
      await tester.tap(find.byTooltip('খুঁজুন'));
      await tester.pump(const Duration(milliseconds: 600));
      if (query != null) {
        await tester.enterText(find.byType(TextField), query);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 600));
      }
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

  group('R3 list preview PNGs', skip: enabled ? false : 'set R3_PREVIEW=1', () {
    testWidgets(
      'expenses, populated',
      (t) => shoot(t, 'list_expense_populated'),
    );
    testWidgets(
      'expenses, dark',
      (t) => shoot(t, 'list_expense_dark', brightness: Brightness.dark),
    );
    testWidgets(
      'expenses, empty',
      (t) => shoot(t, 'list_expense_empty', empty: true),
    );
    testWidgets(
      'expenses, search no match',
      (t) => shoot(t, 'list_expense_search_empty', search: true, query: 'zzz'),
    );
    testWidgets(
      'expenses, search match',
      (t) => shoot(t, 'list_expense_search', search: true, query: 'বি'),
    );
    testWidgets(
      'income, populated',
      (t) => shoot(t, 'list_income_populated', income: true),
    );
    testWidgets(
      'income, empty',
      (t) => shoot(t, 'list_income_empty', income: true, empty: true),
    );
  });
}
