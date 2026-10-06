import 'entities/expense_entity.dart';
import 'entities/expense_source_filters.dart';

enum SpendingTrend { less, more, same }

/// "গত মাসের চেয়ে X% কম/বেশি".
class SpendingDelta {
  const SpendingDelta({required this.trend, required this.percent});

  final SpendingTrend trend;

  /// Whole percent, >= 0 (0 only for [SpendingTrend.same]).
  final int percent;

  /// What the chip prints: capped so a tiny base can't produce an absurd number.
  int get displayPercent =>
      percent > maxDisplayPercent ? maxDisplayPercent : percent;
  bool get isCapped => percent > maxDisplayPercent;

  static const maxDisplayPercent = 999;

  @override
  bool operator ==(Object other) =>
      other is SpendingDelta &&
      other.trend == trend &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(trend, percent);

  @override
  String toString() => 'SpendingDelta($trend, $percent%)';
}

/// Month-to-date spending vs the SAME PERIOD of last month, as a percentage — or
/// `null` (chip hidden) when last month's comparable period had no spending.
///
/// Pass the two totals from [compareMonthToDate]. Comparing a partial month with
/// a full one would read "less" every month start (false reassurance), so the
/// caller must never pass last month's full total here. A change that rounds to
/// 0% is [SpendingTrend.same].
SpendingDelta? spendingDelta({
  required double thisMonth,
  required double lastMonth,
}) {
  if (lastMonth <= 0 || thisMonth < 0) {
    return null;
  }
  final change = (thisMonth - lastMonth) / lastMonth * 100;
  final percent = change.abs().round();
  if (percent == 0) {
    return const SpendingDelta(trend: SpendingTrend.same, percent: 0);
  }
  return SpendingDelta(
    trend: change < 0 ? SpendingTrend.less : SpendingTrend.more,
    percent: percent,
  );
}

/// Last month's "day 1..N": the same stretch of the month we are in, where N is
/// today's day clamped to last month's length (31 Mar -> all of Feb).
({DateTime start, DateTime end, int days}) lastMonthSamePeriodWindow(
  DateTime now,
) {
  final start = DateTime(now.year, now.month - 1, 1); // month 0 -> December
  final lengthOfLastMonth = DateTime(now.year, now.month, 0).day;
  final days = now.day < lengthOfLastMonth ? now.day : lengthOfLastMonth;
  final end = DateTime(start.year, start.month, days, 23, 59, 59, 999);
  return (start: start, end: end, days: days);
}

class MonthToDateComparison {
  const MonthToDateComparison({
    required this.thisMonthToDate,
    required this.lastMonthSamePeriod,
  });

  /// Spending from day 1 through today (future-dated entries this month excluded).
  final double thisMonthToDate;

  /// Spending in last month's day 1..N.
  final double lastMonthSamePeriod;
}

/// Month-to-date vs same period last month, using the SAME spending predicate
/// as every other "how much did I spend" figure (`inSpendingTotals`).
///
/// [thisMonth] / [lastMonth] are the month's expenses as the dashboard already
/// loads them; entries outside the intended month are ignored, so a mixed list
/// can't skew the result.
MonthToDateComparison compareMonthToDate({
  required DateTime now,
  required Iterable<ExpenseEntity> thisMonth,
  required Iterable<ExpenseEntity> lastMonth,
}) {
  final window = lastMonthSamePeriodWindow(now);
  final today = DateTime(now.year, now.month, now.day);

  double sum(Iterable<ExpenseEntity> expenses) =>
      expenses.inSpendingTotals.fold<double>(0, (total, e) => total + e.amount);

  final thisToDate = thisMonth.where((e) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    return day.year == now.year &&
        day.month == now.month &&
        !day.isAfter(today);
  });
  final lastSame = lastMonth.where((e) {
    return e.date.year == window.start.year &&
        e.date.month == window.start.month &&
        e.date.day <= window.days;
  });
  return MonthToDateComparison(
    thisMonthToDate: sum(thisToDate),
    lastMonthSamePeriod: sum(lastSame),
  );
}
