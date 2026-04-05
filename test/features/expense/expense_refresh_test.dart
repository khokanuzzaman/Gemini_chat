import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/repositories/expense_repository.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';

class _FakeExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> _expenses;
  int _nextId = 1;

  _FakeExpenseRepository(List<ExpenseEntity> seedExpenses)
    : _expenses = seedExpenses
          .map(
            (expense) => expense.copyWith(
              id: expense.id ?? seedExpenses.indexOf(expense) + 1,
            ),
          )
          .toList(growable: true) {
    if (_expenses.isNotEmpty) {
      _nextId =
          _expenses
              .map((expense) => expense.id ?? 0)
              .reduce((value, element) => value > element ? value : element) +
          1;
    }
  }

  @override
  Future<List<ExpenseEntity>> getAllExpenses() async {
    final expenses = [..._expenses]
      ..sort((first, second) => second.date.compareTo(first.date));
    return expenses;
  }

  @override
  Future<List<ExpenseEntity>> getThisMonthExpenses() async {
    final now = DateTime.now();
    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseEntity>> getLastMonthExpenses() async {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _expenses
        .where(
          (expense) =>
              expense.date.year == year && expense.date.month == lastMonth,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseEntity>> getTodayExpenses() async {
    final now = DateTime.now();
    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseEntity>> getExpensesForMonth(DateTime month) async {
    return _expenses
        .where(
          (expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String category) async {
    return _expenses
        .where((expense) => expense.category == category)
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseEntity>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return _expenses
        .where(
          (expense) =>
              !expense.date.isBefore(start) && !expense.date.isAfter(end),
        )
        .toList(growable: false);
  }

  @override
  Future<ExpenseEntity> saveExpense(ExpenseEntity expense) async {
    final saved = expense.copyWith(id: _nextId++);
    _expenses.add(saved);
    return saved;
  }

  @override
  Future<List<ExpenseEntity>> saveExpenses(List<ExpenseEntity> expenses) async {
    final saved = expenses
        .map((expense) => expense.copyWith(id: _nextId++))
        .toList(growable: false);
    _expenses.addAll(saved);
    return saved;
  }

  @override
  Future<void> deleteExpense(int id) async {
    _expenses.removeWhere((expense) => expense.id == id);
  }

  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
    }
  }

  @override
  Future<Map<DateTime, double>> getDailyTotals(int days) async => {};

  @override
  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async => {};
}

void main() {
  test(
    'chat-style expense save refreshes dashboard, expense list, and analytics providers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final seedExpense = ExpenseEntity(
        id: 1,
        amount: 120,
        category: 'Food',
        description: 'নাস্তা',
        date: DateTime(now.year, now.month, now.day, 9, 0),
      );
      final fakeRepository = _FakeExpenseRepository([seedExpense]);
      final container = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(fakeRepository),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final initialDashboard = await container.read(
        dashboardControllerProvider.future,
      );
      final initialList = await container.read(
        expenseListControllerProvider.future,
      );
      final initialAnalytics = await container.read(
        analyticsControllerProvider.future,
      );

      expect(initialDashboard.thisMonthTotal, 120);
      expect(initialList.expenses, hasLength(1));
      expect(initialAnalytics.data.totalSpent, 120);

      final error = await container
          .read(expenseMutationControllerProvider)
          .saveDetectedExpense(
            ExpenseData(
              amount: 60,
              category: 'Transport',
              description: 'রিকশা',
              date: DateTime(
                now.year,
                now.month,
                now.day,
              ).toIso8601String().split('T').first,
            ),
          );

      expect(error, isNull);

      final updatedDashboard = await container.read(
        dashboardControllerProvider.future,
      );
      final updatedList = await container.read(
        expenseListControllerProvider.future,
      );
      final updatedAnalytics = await container.read(
        analyticsControllerProvider.future,
      );

      expect(updatedDashboard.thisMonthTotal, 180);
      expect(updatedDashboard.todayExpenses, hasLength(2));
      expect(updatedList.expenses, hasLength(2));
      expect(updatedAnalytics.data.totalSpent, 180);
      expect(container.read(expenseRefreshTokenProvider), 1);
    },
  );
}
