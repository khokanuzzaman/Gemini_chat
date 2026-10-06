import 'package:flutter_test/flutter_test.dart';

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
}
