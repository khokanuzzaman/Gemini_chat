import '../entities/analytics_data.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

class GetAnalyticsUseCase {
  const GetAnalyticsUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<AnalyticsData> call(DateTime month) async {
    final currentMonthExpenses = await _repository.getExpensesForMonth(month);
    final previousMonth = month.month == 1
        ? DateTime(month.year - 1, 12, 1)
        : DateTime(month.year, month.month - 1, 1);
    final lastMonthExpenses = await _repository.getExpensesForMonth(
      previousMonth,
    );

    final thisMonthByCategory = _categoryTotals(currentMonthExpenses);
    final lastMonthByCategory = _categoryTotals(lastMonthExpenses);
    final expensesByDay = _groupExpensesByDay(currentMonthExpenses);
    final dailyTotals = _buildLastSevenDays(expensesByDay, month);
    final topSpendingDays = _buildTopSpendingDays(expensesByDay);
    final totalSpent = currentMonthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final highestCategory = thisMonthByCategory.entries.isEmpty
        ? 'কোনো তথ্য নেই'
        : (thisMonthByCategory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    return AnalyticsData(
      dailyTotals: dailyTotals,
      thisMonthByCategory: thisMonthByCategory,
      lastMonthByCategory: lastMonthByCategory,
      topSpendingDays: topSpendingDays,
      totalSpent: totalSpent,
      highestCategory: highestCategory,
      transactionCount: currentMonthExpenses.length,
      expensesByDay: expensesByDay,
    );
  }

  Map<String, double> _categoryTotals(List<ExpenseEntity> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  Map<DateTime, List<ExpenseEntity>> _groupExpensesByDay(
    List<ExpenseEntity> expenses,
  ) {
    final grouped = <DateTime, List<ExpenseEntity>>{};
    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(expense);
    }
    return grouped;
  }

  Map<DateTime, double> _buildLastSevenDays(
    Map<DateTime, List<ExpenseEntity>> expensesByDay,
    DateTime month,
  ) {
    final now = DateTime.now();
    final lastDay = (now.year == month.year && now.month == month.month)
        ? DateTime(now.year, now.month, now.day)
        : DateTime(month.year, month.month + 1, 0);
    final startDay = lastDay.subtract(const Duration(days: 6));
    final totals = <DateTime, double>{};

    for (var index = 0; index < 7; index++) {
      final day = DateTime(startDay.year, startDay.month, startDay.day + index);
      final expenses = expensesByDay[day] ?? const <ExpenseEntity>[];
      totals[day] = expenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );
    }

    return totals;
  }

  List<ExpenseEntity> _buildTopSpendingDays(
    Map<DateTime, List<ExpenseEntity>> expensesByDay,
  ) {
    final daySummaries = expensesByDay.entries.map((entry) {
      final total = entry.value.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );
      final categoryTotals = <String, double>{};
      for (final expense in entry.value) {
        categoryTotals.update(
          expense.category,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
      final topCategory =
          (categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

      return ExpenseEntity(
        amount: total,
        category: topCategory,
        description: topCategory,
        date: entry.key,
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return daySummaries.take(3).toList(growable: false);
  }
}
