import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getAllExpenses();

  Future<List<ExpenseEntity>> getThisMonthExpenses();

  Future<List<ExpenseEntity>> getLastMonthExpenses();

  Future<List<ExpenseEntity>> getTodayExpenses();

  Future<List<ExpenseEntity>> getExpensesForMonth(DateTime month);

  Future<List<ExpenseEntity>> getExpensesByCategory(String category);

  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<ExpenseEntity> saveExpense(ExpenseEntity expense);

  Future<List<ExpenseEntity>> saveExpenses(List<ExpenseEntity> expenses);

  Future<void> deleteExpense(int id);

  Future<void> updateExpense(ExpenseEntity expense);

  Future<Map<DateTime, double>> getDailyTotals(int days);

  Future<Map<String, double>> getCategoryTotals(DateTime start, DateTime end);
}
