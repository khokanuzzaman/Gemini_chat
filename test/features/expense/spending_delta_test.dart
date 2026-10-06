import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/domain/spending_delta.dart';

void main() {
  group('spendingDelta', () {
    test(
      'hidden when last month is zero (never a "0 last month" comparison)',
      () {
        expect(spendingDelta(thisMonth: 5000, lastMonth: 0), isNull);
        expect(spendingDelta(thisMonth: 0, lastMonth: 0), isNull);
      },
    );

    test('less: down, rounded to a whole percent', () {
      expect(
        spendingDelta(thisMonth: 41890, lastMonth: 52300),
        const SpendingDelta(trend: SpendingTrend.less, percent: 20),
      );
      expect(
        spendingDelta(thisMonth: 0, lastMonth: 1000),
        const SpendingDelta(trend: SpendingTrend.less, percent: 100),
      );
    });

    test('more: up', () {
      expect(
        spendingDelta(thisMonth: 60000, lastMonth: 50000),
        const SpendingDelta(trend: SpendingTrend.more, percent: 20),
      );
      expect(
        spendingDelta(thisMonth: 125000, lastMonth: 50000),
        const SpendingDelta(trend: SpendingTrend.more, percent: 150),
      );
    });

    test('a change that rounds to 0% is "same", not "0% less"', () {
      expect(
        spendingDelta(thisMonth: 50100, lastMonth: 50000),
        const SpendingDelta(trend: SpendingTrend.same, percent: 0),
      );
      expect(
        spendingDelta(thisMonth: 49900, lastMonth: 50000)!.trend,
        SpendingTrend.same,
      );
      expect(
        spendingDelta(thisMonth: 50000, lastMonth: 50000)!.trend,
        SpendingTrend.same,
      );
    });

    test('rounding boundary: 0.5% rounds away from zero to 1%', () {
      expect(spendingDelta(thisMonth: 50250, lastMonth: 50000)!.percent, 1);
    });

    test('a tiny base can not print an absurd number (capped at 999)', () {
      final delta = spendingDelta(thisMonth: 1000000, lastMonth: 10)!;
      expect(delta.trend, SpendingTrend.more);
      expect(delta.percent, greaterThan(999));
      expect(delta.displayPercent, 999);
      expect(delta.isCapped, isTrue);
      expect(spendingDelta(thisMonth: 200, lastMonth: 100)!.isCapped, isFalse);
    });

    test('a negative total (bad data) is not compared', () {
      expect(spendingDelta(thisMonth: -5, lastMonth: 100), isNull);
    });
  });

  group('lastMonthSamePeriodWindow (day 1..N, N clamped)', () {
    test('an ordinary day: today\'s day number, last month', () {
      final w = lastMonthSamePeriodWindow(DateTime(2026, 10, 6, 15));
      expect(w.start, DateTime(2026, 9, 1));
      expect(w.days, 6);
      expect(w.end, DateTime(2026, 9, 6, 23, 59, 59, 999));
    });

    test('day 1 compares day 1 only', () {
      final w = lastMonthSamePeriodWindow(DateTime(2026, 10, 1));
      expect(w.days, 1);
      expect(w.end, DateTime(2026, 9, 1, 23, 59, 59, 999));
    });

    test(
      '31 March vs February: the whole of Feb (28, or 29 in a leap year)',
      () {
        expect(lastMonthSamePeriodWindow(DateTime(2026, 3, 31)).days, 28);
        expect(
          lastMonthSamePeriodWindow(DateTime(2026, 3, 31)).end,
          DateTime(2026, 2, 28, 23, 59, 59, 999),
        );
        expect(lastMonthSamePeriodWindow(DateTime(2028, 3, 31)).days, 29);
        expect(lastMonthSamePeriodWindow(DateTime(2026, 3, 29)).days, 28);
        expect(lastMonthSamePeriodWindow(DateTime(2026, 3, 28)).days, 28);
      },
    );

    test('31 October vs a 30-day September', () {
      expect(lastMonthSamePeriodWindow(DateTime(2026, 10, 31)).days, 30);
    });

    test('January looks back to December of the previous year', () {
      final w = lastMonthSamePeriodWindow(DateTime(2026, 1, 15));
      expect(w.start, DateTime(2025, 12, 1));
      expect(w.end, DateTime(2025, 12, 15, 23, 59, 59, 999));
    });
  });

  group('compareMonthToDate', () {
    ExpenseEntity e(
      DateTime date,
      double amount, {
      ExpenseSource source = ExpenseSource.expense,
    }) {
      return ExpenseEntity(
        amount: amount,
        category: 'Food',
        description: 'x',
        date: date,
        sourceType: source,
      );
    }

    test('this month so far vs last month\'s same days (6 Oct)', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 6, 15),
        thisMonth: [
          e(DateTime(2026, 10, 1), 100),
          e(DateTime(2026, 10, 6, 23, 30), 50), // later today still counts
        ],
        lastMonth: [
          e(DateTime(2026, 9, 1), 400),
          e(DateTime(2026, 9, 6, 23, 59), 100), // last day of the window
          e(DateTime(2026, 9, 7), 9999), // outside the window
          e(DateTime(2026, 9, 28), 9999),
        ],
      );
      expect(result.thisMonthToDate, 150);
      expect(result.lastMonthSamePeriod, 500);
    });

    test('day 1: only day 1 on both sides', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 1, 8),
        thisMonth: [e(DateTime(2026, 10, 1), 70)],
        lastMonth: [e(DateTime(2026, 9, 1), 80), e(DateTime(2026, 9, 2), 999)],
      );
      expect(result.thisMonthToDate, 70);
      expect(result.lastMonthSamePeriod, 80);
    });

    test('31 March vs February counts all of February, 28th included', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 3, 31),
        thisMonth: [e(DateTime(2026, 3, 30), 10)],
        lastMonth: [
          e(DateTime(2026, 2, 1), 100),
          e(DateTime(2026, 2, 28, 23, 59), 200),
        ],
      );
      expect(result.lastMonthSamePeriod, 300);
    });

    test('future-dated entries this month are not "so far"', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 6),
        thisMonth: [
          e(DateTime(2026, 10, 5), 10),
          e(DateTime(2026, 10, 20), 5000),
        ],
        lastMonth: const [],
      );
      expect(result.thisMonthToDate, 10);
    });

    test('uses the spending predicate: EMI counts, goal deposits do not', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 6),
        thisMonth: [
          e(DateTime(2026, 10, 2), 100),
          e(DateTime(2026, 10, 3), 5000, source: ExpenseSource.debtPayment),
          e(DateTime(2026, 10, 4), 777, source: ExpenseSource.goalDeposit),
        ],
        lastMonth: const [],
      );
      expect(result.thisMonthToDate, 5100);
    });

    test('rows from other months are ignored even if mixed into the lists', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 6),
        thisMonth: [e(DateTime(2026, 10, 2), 10), e(DateTime(2026, 9, 2), 999)],
        lastMonth: [e(DateTime(2026, 9, 2), 20), e(DateTime(2026, 8, 2), 999)],
      );
      expect(result.thisMonthToDate, 10);
      expect(result.lastMonthSamePeriod, 20);
    });

    test('last month empty (or empty in those days) -> the chip is hidden', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 6),
        thisMonth: [e(DateTime(2026, 10, 2), 3000)],
        lastMonth: [
          e(DateTime(2026, 9, 25), 60000),
        ], // spent later in the month
      );
      expect(result.lastMonthSamePeriod, 0);
      expect(
        spendingDelta(
          thisMonth: result.thisMonthToDate,
          lastMonth: result.lastMonthSamePeriod,
        ),
        isNull,
      );
    });

    test('the false-reassurance case: month start, full last month is big', () {
      final result = compareMonthToDate(
        now: DateTime(2026, 10, 3),
        thisMonth: [
          e(DateTime(2026, 10, 1), 2000),
          e(DateTime(2026, 10, 2), 1000),
        ],
        lastMonth: [
          e(DateTime(2026, 9, 1), 2000),
          e(DateTime(2026, 9, 2), 1000),
          e(DateTime(2026, 9, 15), 57000),
        ],
      );
      final delta = spendingDelta(
        thisMonth: result.thisMonthToDate,
        lastMonth: result.lastMonthSamePeriod,
      )!;
      expect(delta.trend, SpendingTrend.same, reason: 'not a 95% "drop"');
    });
  });
}
