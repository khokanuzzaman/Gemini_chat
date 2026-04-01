import 'expense_entity.dart';

class AnalyticsData {
  const AnalyticsData({
    required this.dailyTotals,
    required this.thisMonthByCategory,
    required this.lastMonthByCategory,
    required this.topSpendingDays,
    required this.totalSpent,
    required this.highestCategory,
    required this.transactionCount,
    required this.expensesByDay,
  });

  final Map<DateTime, double> dailyTotals;
  final Map<String, double> thisMonthByCategory;
  final Map<String, double> lastMonthByCategory;
  final List<ExpenseEntity> topSpendingDays;
  final double totalSpent;
  final String highestCategory;
  final int transactionCount;
  final Map<DateTime, List<ExpenseEntity>> expensesByDay;
}
