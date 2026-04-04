import 'expense_entity.dart';

class DashboardData {
  const DashboardData({
    required this.thisMonthTotal,
    required this.lastMonthTotal,
    required this.thisWeekTotal,
    required this.transactionCount,
    required this.manualEntryCount,
    required this.categoryTotals,
    required this.todayExpenses,
    required this.recentExpenses,
  });

  final double thisMonthTotal;
  final double lastMonthTotal;
  final double thisWeekTotal;
  final int transactionCount;
  final int manualEntryCount;
  final Map<String, double> categoryTotals;
  final List<ExpenseEntity> todayExpenses;
  final List<ExpenseEntity> recentExpenses;
}
