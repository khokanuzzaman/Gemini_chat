// R3 (a): the খরচ / আয় lists — day-grouped lazy rows with a daily subtotal, the
// shared Home row, two empty states, the app-bar search, EMI rows read-only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/home/home_recent_card.dart';
import 'package:gemini_chat/features/income/presentation/screens/income_list_screen.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

DateTime _noon(int daysAgo) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, 12).subtract(Duration(days: daysAgo));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpExpenses(
  WidgetTester tester,
  ListCalls calls, {
  required List<Override> overrides,
  GlobalKey<ExpenseListBodyState>? key,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    listApp(
      overrides: overrides,
      child: ExpenseListBody(key: key),
    ),
  );
  await _settle(tester);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  group('খরচ list', () {
    final calls = ListCalls();
    final rows = [
      listExpense(id: 1, date: _noon(0), amount: 100, description: 'ডাল-ভাত'),
      listExpense(
        id: 2,
        date: _noon(0).subtract(const Duration(hours: 1)),
        amount: 250,
        category: 'Transport',
        description: 'রিকশা',
        walletId: 2,
      ),
      listExpense(
        id: 3,
        date: _noon(1),
        amount: 3200,
        category: 'EMI',
        description: 'মোটরসাইকেল কিস্তি',
        source: ExpenseSource.debtPayment,
      ),
      listExpense(id: 4, date: _noon(5), amount: 80, description: 'চা'),
    ];

    testWidgets('day headers carry the daily subtotal; EMI counts', (
      tester,
    ) async {
      await _pumpExpenses(
        tester,
        calls,
        overrides: listOverrides(expenses: rows, calls: calls),
      );

      expect(find.textContaining('আজকে', findRichText: true), findsOneWidget);
      expect(find.textContaining('গতকাল', findRichText: true), findsOneWidget);
      // 100 + 250 today; the EMI row is the whole of yesterday's total.
      expect(find.text(BanglaFormatters.currency(350)), findsOneWidget);
      expect(
        find.text(BanglaFormatters.currency(3200)),
        findsOneWidget,
      ); // header
      expect(
        find.text('-${BanglaFormatters.currency(3200)}'),
        findsOneWidget,
      ); // row
      expect(find.byType(HomeActivityRow), findsNWidgets(4));
    });

    testWidgets('rows use the shared row: category · wallet, time, amount', (
      tester,
    ) async {
      await _pumpExpenses(
        tester,
        calls,
        overrides: listOverrides(expenses: rows, calls: calls),
      );
      expect(find.textContaining('💵 নগদ টাকা'), findsWidgets);
      expect(find.textContaining('📱 বিকাশ'), findsOneWidget);
      expect(find.text('-${BanglaFormatters.currency(100)}'), findsOneWidget);
      expect(find.text(BanglaFormatters.time(_noon(0))), findsWidgets);
    });

    testWidgets('EMI row is locked; tap opens the read-only sheet', (
      tester,
    ) async {
      final c = ListCalls();
      await _pumpExpenses(
        tester,
        c,
        overrides: listOverrides(expenses: rows, calls: c),
      );
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      await tester.tap(find.text('মোটরসাইকেল কিস্তি'));
      await _settle(tester);
      expect(find.text('দেনা-পাওনার পরিশোধ'), findsOneWidget);
      expect(find.text('দেনা-পাওনা থেকে পরিবর্তন করুন'), findsOneWidget);
      expect(c.deletedExpenses, isEmpty);
    });

    testWidgets('EMI row cannot be swiped away or confirm-deleted', (
      tester,
    ) async {
      final c = ListCalls();
      await _pumpExpenses(
        tester,
        c,
        overrides: listOverrides(expenses: rows, calls: c),
      );
      await tester.drag(find.text('মোটরসাইকেল কিস্তি'), const Offset(-300, 0));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.deletedExpenses, isEmpty);
      expect(find.text('মোটরসাইকেল কিস্তি'), findsOneWidget);
    });

    testWidgets('long-press asks first; confirming calls the controller', (
      tester,
    ) async {
      final c = ListCalls();
      await _pumpExpenses(
        tester,
        c,
        overrides: listOverrides(expenses: rows, calls: c),
      );
      await tester.longPress(find.text('ডাল-ভাত'));
      await _settle(tester);
      expect(find.text('খরচ মুছে ফেলবেন?'), findsOneWidget);
      expect(c.deletedExpenses, isEmpty); // nothing yet

      await tester.tap(find.text('বাতিল'));
      await _settle(tester);
      expect(c.deletedExpenses, isEmpty);

      await tester.longPress(find.text('ডাল-ভাত'));
      await _settle(tester);
      await tester.tap(find.text('মুছুন'));
      await _settle(tester);
      expect(c.deletedExpenses.map((e) => e.id), [1]);
    });

    testWidgets('swipe asks first and the row stays until the list refreshes', (
      tester,
    ) async {
      final c = ListCalls();
      await _pumpExpenses(
        tester,
        c,
        overrides: listOverrides(expenses: rows, calls: c),
      );
      await tester.drag(find.text('চা'), const Offset(-300, 0));
      await _settle(tester);
      expect(find.text('খরচ মুছে ফেলবেন?'), findsOneWidget);
      await tester.tap(find.text('বাতিল'));
      await _settle(tester);
      expect(find.text('চা'), findsOneWidget);
      expect(c.deletedExpenses, isEmpty);
    });

    testWidgets(
      'search icon reveals the field; no match -> empty state that clears',
      (tester) async {
        final key = GlobalKey<ExpenseListBodyState>();
        await _pumpExpenses(
          tester,
          calls,
          key: key,
          overrides: listOverrides(expenses: rows, calls: calls),
        );
        expect(find.byType(TextField), findsNothing);

        key.currentState!.toggleSearch();
        await _settle(tester);
        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'zzz-নেই');
        await tester.pump(const Duration(milliseconds: 400)); // debounce
        await _settle(tester);
        expect(find.text('কিছু পাওয়া যায়নি'), findsOneWidget);
        expect(find.byType(HomeActivityRow), findsNothing);

        await tester.tap(find.text('ফিল্টার মুছুন'));
        await _settle(tester);
        expect(find.byType(HomeActivityRow), findsNWidgets(4));

        // Hiding the field also clears the query.
        key.currentState!.toggleSearch();
        await _settle(tester);
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets('search matches the description', (tester) async {
      final key = GlobalKey<ExpenseListBodyState>();
      await _pumpExpenses(
        tester,
        calls,
        key: key,
        overrides: listOverrides(expenses: rows, calls: calls),
      );
      key.currentState!.toggleSearch();
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'রিকশা');
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(find.byType(HomeActivityRow), findsOneWidget);
      expect(find.text('রিকশা'), findsWidgets);
    });

    testWidgets('no expenses at all -> first-run empty state with add action', (
      tester,
    ) async {
      await _pumpExpenses(
        tester,
        calls,
        overrides: listOverrides(expenses: const [], calls: calls),
      );
      expect(find.text('এখনো কোনো খরচ নেই'), findsOneWidget);
      expect(find.text('খরচ যোগ করুন'), findsOneWidget);
      expect(find.text('কিছু পাওয়া যায়নি'), findsNothing);
    });

    testWidgets('empty description falls back to the category name', (
      tester,
    ) async {
      await _pumpExpenses(
        tester,
        calls,
        overrides: listOverrides(
          expenses: [listExpense(id: 9, date: _noon(0), description: '  ')],
          calls: calls,
        ),
      );
      expect(find.byType(HomeActivityRow), findsOneWidget);
      expect(find.text('খাবার'), findsWidgets);
    });
  });

  group('আয় list', () {
    final incomes = [
      listIncome(
        id: 1,
        date: _noon(0),
        amount: 5000,
        description: 'অক্টোবরের বেতন',
      ),
      listIncome(id: 2, date: _noon(0), amount: 700, source: 'Freelance'),
      listIncome(id: 3, date: _noon(3), amount: 1200, description: 'ভাড়া'),
    ];

    Future<void> pumpIncome(
      WidgetTester tester,
      ListCalls c, {
      GlobalKey<IncomeListBodyState>? key,
      List<dynamic>? rows,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        listApp(
          overrides: listOverrides(
            incomes: rows == null ? incomes : rows.cast(),
            calls: c,
          ),
          child: IncomeListBody(key: key),
        ),
      );
      await _settle(tester);
    }

    testWidgets('grouped by day with a + subtotal', (tester) async {
      await pumpIncome(tester, ListCalls());
      expect(find.byType(HomeActivityRow), findsNWidgets(3));
      expect(find.text('+${BanglaFormatters.currency(5700)}'), findsOneWidget);
      expect(find.text('+${BanglaFormatters.currency(5000)}'), findsOneWidget);
    });

    testWidgets('long-press confirm deletes through the controller', (
      tester,
    ) async {
      final c = ListCalls();
      await pumpIncome(tester, c);
      await tester.longPress(find.text('ভাড়া'));
      await _settle(tester);
      expect(find.text('আয় মুছে ফেলবেন?'), findsOneWidget);
      await tester.tap(find.text('মুছুন'));
      await _settle(tester);
      expect(c.deletedIncomes.map((e) => e.id), [3]);
    });

    testWidgets('search + empty states', (tester) async {
      final key = GlobalKey<IncomeListBodyState>();
      await pumpIncome(tester, ListCalls(), key: key);
      key.currentState!.toggleSearch();
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'ভাড়া');
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(find.byType(HomeActivityRow), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'নেই-নেই');
      await tester.pump(const Duration(milliseconds: 400));
      await _settle(tester);
      expect(find.text('কিছু পাওয়া যায়নি'), findsOneWidget);
    });

    testWidgets('first-run empty state', (tester) async {
      await pumpIncome(tester, ListCalls(), rows: const []);
      expect(find.text('এখনো কোনো আয় নেই'), findsOneWidget);
    });
  });
}
