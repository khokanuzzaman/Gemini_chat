// R3 (a) overflow matrix: widths 320/360/411 × heights 568/640/850 × text scale
// 1.0/1.3 × light/dark, over the list states that stress layout: long Bengali
// titles, a crore-scale amount, a long wallet name, an EMI row, search open, and
// both empty states.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/income/presentation/screens/income_list_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

DateTime _day(int ago) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 14).subtract(Duration(days: ago));
}

const _long =
    'ঢাকা থেকে চট্টগ্রাম যাওয়ার বাস ভাড়া এবং হোটেলের অগ্রিম বুকিং বাবদ মোট খরচ';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  final expenses = [
    listExpense(id: 1, date: _day(0), amount: 12345678, description: _long),
    listExpense(
      id: 2,
      date: _day(0),
      amount: 5,
      description: 'চা',
      walletId: 2,
    ),
    listExpense(
      id: 3,
      date: _day(1),
      amount: 99999,
      category: 'EMI',
      description: 'মোটরসাইকেল ঋণের মাসিক কিস্তি — ডাচ-বাংলা ব্যাংক',
      source: ExpenseSource.debtPayment,
    ),
    listExpense(id: 4, date: _day(40), amount: 450, description: ''),
  ];
  final incomes = [
    listIncome(id: 1, date: _day(0), amount: 98765432, description: _long),
    listIncome(id: 2, date: _day(2), amount: 700, source: 'Freelance'),
  ];

  for (final width in [320.0, 360.0, 411.0]) {
    for (final height in [568.0, 640.0, 850.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final brightness in Brightness.values) {
          final tag =
              '${width.toInt()}x${height.toInt()} ×$scale ${brightness.name}';

          Future<void> pump(
            WidgetTester tester,
            Widget child,
            List<Override> overrides,
          ) async {
            tester.view.physicalSize = Size(width, height);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              listApp(
                overrides: overrides,
                brightness: brightness,
                textScale: scale,
                child: child,
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          }

          testWidgets('expenses populated, $tag', (tester) async {
            await pump(
              tester,
              const ExpenseListBody(),
              listOverrides(expenses: expenses, calls: ListCalls()),
            );
            expect(tester.takeException(), isNull);
          });

          testWidgets('expenses search open, $tag', (tester) async {
            final key = GlobalKey<ExpenseListBodyState>();
            await pump(
              tester,
              ExpenseListBody(key: key),
              listOverrides(expenses: expenses, calls: ListCalls()),
            );
            key.currentState!.toggleSearch();
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull);
          });

          testWidgets('expenses empty (first run), $tag', (tester) async {
            await pump(
              tester,
              const ExpenseListBody(),
              listOverrides(calls: ListCalls()),
            );
            expect(tester.takeException(), isNull);
          });

          testWidgets('expenses empty (no match), $tag', (tester) async {
            final key = GlobalKey<ExpenseListBodyState>();
            await pump(
              tester,
              ExpenseListBody(key: key),
              listOverrides(expenses: expenses, calls: ListCalls()),
            );
            key.currentState!.toggleSearch();
            await tester.pump(const Duration(milliseconds: 300));
            await tester.enterText(find.byType(TextField), 'zzzz');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.text('কিছু পাওয়া যায়নি'), findsOneWidget);
            expect(tester.takeException(), isNull);
          });

          testWidgets('income source filter sheet + selected chip, $tag', (
            tester,
          ) async {
            final key = GlobalKey<IncomeListBodyState>();
            await pump(
              tester,
              IncomeListBody(key: key),
              listOverrides(incomes: incomes, calls: ListCalls()),
            );
            key.currentState!.openFilter();
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            await tester.tap(
              find.descendant(
                of: find.byType(Wrap),
                matching: find.text('ফ্রিল্যান্স'),
              ),
            );
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
          });

          testWidgets('income populated, $tag', (tester) async {
            await pump(
              tester,
              const IncomeListBody(),
              listOverrides(incomes: incomes, calls: ListCalls()),
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
