import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/features/budget/domain/budget_suggestions.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';

ExpenseEntity _e(
  String category,
  double amount,
  DateTime date, {
  ExpenseSource source = ExpenseSource.expense,
}) => ExpenseEntity(
  amount: amount,
  category: category,
  description: '',
  date: date,
  sourceType: source,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  group('roundBudgetLimit', () {
    test('৳100 steps under ৳10,000', () {
      expect(roundBudgetLimit(1237), 1200);
      expect(roundBudgetLimit(1250), 1300);
      expect(roundBudgetLimit(9949), 9900);
      expect(roundBudgetLimit(9960), 10000);
    });

    test('৳500 steps from ৳10,000', () {
      expect(roundBudgetLimit(10100), 10000);
      expect(roundBudgetLimit(10250), 10500);
      expect(roundBudgetLimit(23740), 23500);
    });

    test('non-positive and non-finite give 0', () {
      expect(roundBudgetLimit(0), 0);
      expect(roundBudgetLimit(-5), 0);
      expect(roundBudgetLimit(double.nan), 0);
      expect(roundBudgetLimit(double.infinity), 0);
    });

    test('floor never goes above the input', () {
      expect(floorBudgetLimit(1299), 1200);
      expect(floorBudgetLimit(10499), 10000);
      expect(floorBudgetLimit(40), 0);
    });
  });

  group('averageMonthlySpendByCategory', () {
    final now = DateTime(2026, 10, 8);

    test('averages the 3 FULL months before this one, ignoring this month', () {
      final avg = averageMonthlySpendByCategory([
        _e('Food', 3000, DateTime(2026, 7, 10)),
        _e('Food', 3000, DateTime(2026, 8, 10)),
        _e('Food', 3000, DateTime(2026, 9, 10)),
        _e('Food', 90000, DateTime(2026, 10, 2)), // this month: left out
        _e('Bill', 600, DateTime(2026, 9, 1)),
        _e('Food', 90000, DateTime(2026, 6, 30)), // too old: left out
      ], now: now);
      expect(avg['Food'], 3000);
      expect(avg['Bill'], 200);
    });

    test('with only one month of history it divides by 1, not 3', () {
      final avg = averageMonthlySpendByCategory([
        _e('Food', 3000, DateTime(2026, 9, 10)),
      ], now: now);
      expect(avg['Food'], 3000);
    });

    test(
      'goal deposits stay out (policy: they are transfers, EMI still counts)',
      () {
        final avg = averageMonthlySpendByCategory([
          _e('Food', 1000, DateTime(2026, 9, 10)),
          _e(
            'Saving',
            5000,
            DateTime(2026, 9, 10),
            source: ExpenseSource.goalDeposit,
          ),
          _e(
            'EMI',
            2000,
            DateTime(2026, 9, 10),
            source: ExpenseSource.debtPayment,
          ),
        ], now: now);
        expect(avg.containsKey('Saving'), isFalse);
        expect(avg['EMI'], 2000);
      },
    );

    test('no history gives an empty map', () {
      expect(averageMonthlySpendByCategory(const [], now: now), isEmpty);
    });
  });

  group('suggestCategoryLimits', () {
    const live = {'Food', 'Bill', 'Other'};

    test('rounds the average and explains it in one Bengali line', () {
      final s = suggestCategoryLimits(
        averageByCategory: {'Food': 3237},
        currentLimits: const {},
        liveCategoryNames: live,
        months: 3,
      );
      expect(s, hasLength(1));
      expect(s.single.suggestedLimit, 3200);
      expect(s.single.isNew, isTrue);
      expect(s.single.reason, 'গত ৩ মাসে গড়ে ৳ ৩,২৩৭ খরচ হয়েছে');
      expect(s.single.reason, isNot(contains(RegExp('[0-9]'))));
    });

    test('a category you do spend on never suggests ৳0', () {
      final s = suggestCategoryLimits(
        averageByCategory: {'Bill': 30},
        currentLimits: const {},
        liveCategoryNames: live,
        months: 1,
      );
      expect(s.single.suggestedLimit, 100);
    });

    test('skips unchanged limits, zero averages and deleted categories', () {
      final s = suggestCategoryLimits(
        averageByCategory: {'Food': 3000, 'Bill': 0, 'Gone': 999},
        currentLimits: const {'Food': 3000},
        liveCategoryNames: live,
        months: 3,
      );
      expect(s, isEmpty);
    });

    test('biggest change first, at most five', () {
      final s = suggestCategoryLimits(
        averageByCategory: {
          for (var i = 0; i < 8; i++) 'C$i': 1000.0 * (i + 1),
        },
        currentLimits: const {},
        liveCategoryNames: {for (var i = 0; i < 8; i++) 'C$i'},
        months: 3,
      );
      expect(s, hasLength(maxSuggestions));
      expect(s.first.category, 'C7');
    });
  });

  group('usagePercent / limitLevel', () {
    test('percent is real, not clamped', () {
      expect(usagePercent(130, 100), 130);
      expect(usagePercent(0, 100), 0);
      expect(usagePercent(50, 0), 0);
    });

    test('primary < 80%, warning 80–100%, danger only over 100%', () {
      expect(limitLevel(79, 100), LimitLevel.onTrack);
      expect(limitLevel(80, 100), LimitLevel.nearLimit);
      expect(limitLevel(100, 100), LimitLevel.nearLimit);
      expect(limitLevel(100.5, 100), LimitLevel.over);
      expect(limitLevel(10, 0), LimitLevel.onTrack);
    });
  });
}
