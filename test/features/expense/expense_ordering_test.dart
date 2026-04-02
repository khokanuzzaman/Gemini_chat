import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/repositories/expense_repository.dart';
import 'package:gemini_chat/features/expense/domain/usecases/get_analytics_usecase.dart';
import 'package:gemini_chat/features/expense/domain/usecases/get_dashboard_data_usecase.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository({
    required List<ExpenseEntity> allExpenses,
    required List<ExpenseEntity> monthExpenses,
  }) : _allExpenses = allExpenses,
       _monthExpenses = monthExpenses;

  final List<ExpenseEntity> _allExpenses;
  final List<ExpenseEntity> _monthExpenses;

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async => _allExpenses;

  @override
  Future<List<ExpenseEntity>> getThisMonthExpenses() async => _monthExpenses;

  @override
  Future<List<ExpenseEntity>> getLastMonthExpenses() async => const [];

  @override
  Future<List<ExpenseEntity>> getTodayExpenses() async => _monthExpenses
      .where(
        (expense) =>
            expense.date.year == DateTime.now().year &&
            expense.date.month == DateTime.now().month &&
            expense.date.day == DateTime.now().day,
      )
      .toList(growable: false);

  @override
  Future<List<ExpenseEntity>> getExpensesForMonth(DateTime month) async =>
      _monthExpenses;

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async =>
      _monthExpenses
          .where((expense) => expense.category == category)
          .toList(growable: false);

  @override
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _monthExpenses
        .where(
          (expense) =>
              !expense.date.isBefore(start) && !expense.date.isAfter(end),
        )
        .toList(growable: false);
  }

  @override
  Future<ExpenseEntity> saveExpense(ExpenseEntity expense) async => expense;

  @override
  Future<List<ExpenseEntity>> saveExpenses(List<ExpenseEntity> expenses) async =>
      expenses;

  @override
  Future<void> deleteExpense(int id) async {}

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {}

  @override
  Future<Map<DateTime, double>> getDailyTotals(int days) async => {};

  @override
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async => {};
}

void main() {
  test('dashboard recent expenses are returned newest first', () async {
    final now = DateTime.now();
    final older = ExpenseEntity(
      id: 1,
      amount: 100,
      category: 'Food',
      description: 'Older',
      date: DateTime(now.year, now.month, now.day, 9),
    );
    final newest = ExpenseEntity(
      id: 2,
      amount: 200,
      category: 'Bill',
      description: 'Newest',
      date: DateTime(now.year, now.month, now.day, 22),
    );

    final repository = _FakeExpenseRepository(
      allExpenses: [older, newest],
      monthExpenses: [older, newest],
    );

    final data = await GetDashboardDataUseCase(repository).call();

    expect(data.recentExpenses.map((expense) => expense.description), [
      'Newest',
      'Older',
    ]);
  });

  test('analytics selected day expenses stay newest first', () async {
    final now = DateTime.now();
    final first = ExpenseEntity(
      id: 1,
      amount: 100,
      category: 'Food',
      description: 'Morning',
      date: DateTime(now.year, now.month, now.day, 8, 0),
    );
    final second = ExpenseEntity(
      id: 2,
      amount: 150,
      category: 'Transport',
      description: 'Evening',
      date: DateTime(now.year, now.month, now.day, 20, 0),
    );

    final repository = _FakeExpenseRepository(
      allExpenses: [first, second],
      monthExpenses: [first, second],
    );

    final data = await GetAnalyticsUseCase(repository).call(
      DateTime(now.year, now.month, 1),
    );
    final dayKey = DateTime(now.year, now.month, now.day);

    expect(data.expensesByDay[dayKey]!.map((expense) => expense.description), [
      'Evening',
      'Morning',
    ]);
  });
}
