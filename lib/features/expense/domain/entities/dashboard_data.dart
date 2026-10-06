import 'expense_entity.dart';

class DashboardData {
  const DashboardData({
    required this.thisMonthTotal,
    required this.lastMonthTotal,
    required this.thisMonthToDateTotal,
    required this.lastMonthSamePeriodTotal,
    required this.thisWeekTotal,
    required this.transactionCount,
    required this.manualEntryCount,
    required this.categoryTotals,
    required this.todayExpenses,
    required this.recentExpenses,
  });

  final double thisMonthTotal;
  final double lastMonthTotal;

  /// Like-with-like pair for the "vs last month" chip: this month from day 1 to
  /// today, and last month's day 1..N (N clamped to its length).
  final double thisMonthToDateTotal;
  final double lastMonthSamePeriodTotal;
  final double thisWeekTotal;
  final int transactionCount;
  final int manualEntryCount;
  final Map<String, double> categoryTotals;
  final List<ExpenseEntity> todayExpenses;
  final List<ExpenseEntity> recentExpenses;
}
