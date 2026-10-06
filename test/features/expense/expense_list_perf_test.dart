// R3 (a): a heavy user (a year of SMS imports, thousands of rows). The list is
// lazy: only rows near the viewport are built, whatever the total, and grouping
// happens once per data change — not per frame.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:gemini_chat/features/expense/presentation/widgets/home/home_recent_card.dart';

import '../../helpers/app_fonts.dart';
import '../../helpers/list_harness.dart';

const _rowCount = 5000;

List<ExpenseEntity> _fiveThousand() {
  final base = DateTime(2026, 10, 1, 23, 0);
  return [
    for (var i = 0; i < _rowCount; i++)
      listExpense(
        id: i + 1,
        // ~14 rows/day over ~357 days, newest first by construction.
        date: base.subtract(Duration(minutes: i * 103)),
        amount: 50.0 + (i % 40) * 10,
        category: const ['Food', 'Transport', 'Shopping', 'Bills'][i % 4],
        description: i == _rowCount - 1
            ? 'সবচেয়ে পুরনো খরচ'
            : 'এসএমএস লেনদেন $i',
        walletId: 1 + i % 2,
      ),
  ];
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
  });

  testWidgets('5,000 rows: first frame builds only the visible rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = ListCalls();

    final watch = Stopwatch()..start();
    await tester.pumpWidget(
      listApp(
        overrides: listOverrides(expenses: _fiveThousand(), calls: calls),
        child: const ExpenseListBody(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    watch.stop();

    final built = find.byType(HomeActivityRow).evaluate().length;
    // ignore: avoid_print
    print(
      '5k rows: first frame ${watch.elapsedMilliseconds}ms, $built rows built',
    );
    expect(built, greaterThan(0));
    expect(built, lessThan(30), reason: 'lazy: not one widget per record');
    expect(
      watch.elapsedMilliseconds,
      lessThan(5000),
      reason: 'grouping + first frame for 5k rows must stay interactive',
    );
  });

  testWidgets(
    'scrolling 5,000 rows to the very end stays lazy and reaches it',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        listApp(
          overrides: listOverrides(
            expenses: _fiveThousand(),
            calls: ListCalls(),
          ),
          child: const ExpenseListBody(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      var maxBuilt = 0;
      // Walk down the list in 3,000px hops (about 45 rows each), like a long
      // fling, and track the most rows ever alive at once.
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          (position.pixels + 3000).clamp(0, position.maxScrollExtent),
        );
        await tester.pump();
        final built = find.byType(HomeActivityRow).evaluate().length;
        if (built > maxBuilt) maxBuilt = built;
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('সবচেয়ে পুরনো খরচ'),
        findsOneWidget,
        reason: 'the oldest of 5,000 rows is reachable',
      );
      expect(
        maxBuilt,
        lessThan(40),
        reason: 'never more than a screenful built',
      );
    },
  );

  testWidgets('searching 5,000 rows narrows the list correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey<ExpenseListBodyState>();
    await tester.pumpWidget(
      listApp(
        overrides: listOverrides(expenses: _fiveThousand(), calls: ListCalls()),
        child: ExpenseListBody(key: key),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    key.currentState!.toggleSearch();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'সবচেয়ে পুরনো');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeActivityRow), findsOneWidget);
    expect(find.text('সবচেয়ে পুরনো খরচ'), findsOneWidget);
  });
}
