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

/// This month's spending vs last month's, as a percentage — or `null` (chip
/// hidden) when there is no last month to compare with.
///
/// `thisMonth` / `lastMonth` are the existing `DashboardData` spending totals
/// (`inSpendingTotals`); this only does the arithmetic. A change that rounds to 0%
/// is [SpendingTrend.same].
///
/// NOTE: early in a month this compares a partial month with a full one, so it
/// reads "less" until spending catches up. That is the spec'd behaviour; it is not
/// pro-rated here on purpose (that would be a new calculation).
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
