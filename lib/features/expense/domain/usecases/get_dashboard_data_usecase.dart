import '../entities/dashboard_data.dart';
import '../entities/expense_source_filters.dart';
import '../repositories/expense_repository.dart';

class GetDashboardDataUseCase {
  const GetDashboardDataUseCase(this._repository);

  final ExpenseRepository _repository;

  Future<DashboardData> call() async {
    final thisMonthExpenses = await _repository.getThisMonthExpenses();
    final lastMonthExpenses = await _repository.getLastMonthExpenses();
    final todayExpenses = await _repository.getTodayExpenses();
    final allExpenses = await _repository.getAllExpenses();
    final sortedRecentExpenses = [...allExpenses]
      ..sort((first, second) => second.date.compareTo(first.date));
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisWeekExpenses = await _repository.getExpensesByDateRange(
      startOfWeek,
      now,
    );

    // Totals/category/count are spending surfaces; the recent/today LISTS show
    // every money movement (debtPayment appears there as an EMI line).
    final thisMonthSpending = thisMonthExpenses.inSpendingTotals.toList(
      growable: false,
    );
    final thisMonthTotal = thisMonthSpending.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final lastMonthTotal = lastMonthExpenses.inSpendingTotals.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categoryTotals = <String, double>{};
    for (final expense in thisMonthSpending) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return DashboardData(
      thisMonthTotal: thisMonthTotal,
      lastMonthTotal: lastMonthTotal,
      thisWeekTotal: thisWeekExpenses.inSpendingTotals.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      ),
      transactionCount: thisMonthSpending.length,
      manualEntryCount: thisMonthExpenses
          .where((expense) => expense.isManual)
          .length,
      categoryTotals: categoryTotals,
      todayExpenses: todayExpenses,
      recentExpenses: sortedRecentExpenses.take(10).toList(growable: false),
    );
  }
}
