import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/ai/expense_result.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_list_filter.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_analytics_usecase.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import '../../domain/usecases/get_expense_list_usecase.dart';
import '../../domain/usecases/save_expense_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';

final expenseRefreshTokenProvider = StateProvider<int>((ref) => 0);

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    localDataSource: ref.watch(expenseLocalDataSourceProvider),
  );
});

final getDashboardDataUseCaseProvider = Provider<GetDashboardDataUseCase>((
  ref,
) {
  return GetDashboardDataUseCase(ref.watch(expenseRepositoryProvider));
});

final getExpenseListUseCaseProvider = Provider<GetExpenseListUseCase>((ref) {
  return GetExpenseListUseCase(ref.watch(expenseRepositoryProvider));
});

final getAnalyticsUseCaseProvider = Provider<GetAnalyticsUseCase>((ref) {
  return GetAnalyticsUseCase(ref.watch(expenseRepositoryProvider));
});

final deleteExpenseUseCaseProvider = Provider<DeleteExpenseUseCase>((ref) {
  return DeleteExpenseUseCase(ref.watch(expenseRepositoryProvider));
});

final updateExpenseUseCaseProvider = Provider<UpdateExpenseUseCase>((ref) {
  return UpdateExpenseUseCase(ref.watch(expenseRepositoryProvider));
});

final saveExpenseUseCaseProvider = Provider<SaveExpenseUseCase>((ref) {
  return SaveExpenseUseCase(ref.watch(expenseRepositoryProvider));
});

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
      DashboardController.new,
    );

final expenseListControllerProvider =
    AsyncNotifierProvider<ExpenseListController, ExpenseListState>(
      ExpenseListController.new,
    );

final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsState>(
      AnalyticsController.new,
    );

final expenseMutationControllerProvider = Provider<ExpenseMutationController>((
  ref,
) {
  return ExpenseMutationController(ref);
});

class DashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    ref.watch(expenseRefreshTokenProvider);
    return ref.read(getDashboardDataUseCaseProvider).call();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(getDashboardDataUseCaseProvider).call());
  }
}

class ExpenseListState {
  const ExpenseListState({required this.expenses, required this.filter});

  final List<ExpenseEntity> expenses;
  final ExpenseListFilter filter;

  ExpenseListState copyWith({
    List<ExpenseEntity>? expenses,
    ExpenseListFilter? filter,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      filter: filter ?? this.filter,
    );
  }
}

class ExpenseListController extends AsyncNotifier<ExpenseListState> {
  ExpenseListFilter _filter = const ExpenseListFilter();

  @override
  Future<ExpenseListState> build() async {
    ref.watch(expenseRefreshTokenProvider);
    return _loadState();
  }

  Future<void> setCategory(String? category) async {
    _filter = ExpenseListFilter(
      category: category,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
    );
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    _filter = ExpenseListFilter(
      category: _filter.category,
      startDate: start,
      endDate: end,
    );
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> clearDateRange() async {
    _filter = _filter.copyWith(clearDateRange: true);
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> clearFilters() async {
    _filter = const ExpenseListFilter();
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<String?> deleteExpense(ExpenseEntity expense) async {
    if (expense.id == null) {
      return 'এই খরচটি মুছা যাচ্ছে না';
    }

    try {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedExpenses = currentState.expenses
            .where((item) => item.id != expense.id)
            .toList(growable: false);
        state = AsyncData(currentState.copyWith(expenses: updatedExpenses));
      }

      await ref.read(deleteExpenseUseCaseProvider).call(expense.id!);
      _notifyExpenseChanged();
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(analyticsControllerProvider);
      state = AsyncData(await _loadState());
      return null;
    } on Failure catch (failure) {
      state = AsyncData(await _loadState());
      return failure.message;
    } catch (error) {
      state = AsyncData(await _loadState());
      return '$error';
    }
  }

  Future<String?> updateExpense(ExpenseEntity expense) async {
    if (expense.id == null) {
      return 'এই খরচটি আপডেট করা যাচ্ছে না';
    }

    try {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            expenses: _applyUpdatedExpense(currentState.expenses, expense),
          ),
        );
      }

      await ref.read(updateExpenseUseCaseProvider).call(expense);
      _notifyExpenseChanged();
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(analyticsControllerProvider);
      state = AsyncData(await _loadState());
      return null;
    } on Failure catch (failure) {
      state = AsyncData(await _loadState());
      return failure.message;
    } catch (error) {
      state = AsyncData(await _loadState());
      return '$error';
    }
  }

  Future<ExpenseListState> _loadState() async {
    final expenses = await ref
        .read(getExpenseListUseCaseProvider)
        .call(_filter);
    return ExpenseListState(expenses: expenses, filter: _filter);
  }

  void _notifyExpenseChanged() {
    ref.read(expenseRefreshTokenProvider.notifier).state++;
  }

  List<ExpenseEntity> _applyUpdatedExpense(
    List<ExpenseEntity> expenses,
    ExpenseEntity updatedExpense,
  ) {
    final updatedExpenses = <ExpenseEntity>[];

    for (final expense in expenses) {
      if (expense.id != updatedExpense.id) {
        updatedExpenses.add(expense);
        continue;
      }

      if (_matchesFilter(updatedExpense)) {
        updatedExpenses.add(updatedExpense);
      }
    }

    updatedExpenses.sort((first, second) => second.date.compareTo(first.date));
    return updatedExpenses;
  }

  bool _matchesFilter(ExpenseEntity expense) {
    if (_filter.category != null && expense.category != _filter.category) {
      return false;
    }

    if (!_filter.hasDateRange) {
      return true;
    }

    final expenseDate = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    final startDate = DateTime(
      _filter.startDate!.year,
      _filter.startDate!.month,
      _filter.startDate!.day,
    );
    final endDate = DateTime(
      _filter.endDate!.year,
      _filter.endDate!.month,
      _filter.endDate!.day,
    );

    return !expenseDate.isBefore(startDate) && !expenseDate.isAfter(endDate);
  }
}

class AnalyticsState {
  const AnalyticsState({
    required this.selectedMonth,
    required this.data,
    this.selectedDay,
  });

  final DateTime selectedMonth;
  final AnalyticsData data;
  final DateTime? selectedDay;

  AnalyticsState copyWith({
    DateTime? selectedMonth,
    AnalyticsData? data,
    DateTime? selectedDay,
    bool clearSelectedDay = false,
  }) {
    return AnalyticsState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      data: data ?? this.data,
      selectedDay: clearSelectedDay ? null : (selectedDay ?? this.selectedDay),
    );
  }
}

class AnalyticsController extends AsyncNotifier<AnalyticsState> {
  DateTime? _selectedMonth;

  @override
  Future<AnalyticsState> build() async {
    ref.watch(expenseRefreshTokenProvider);
    _selectedMonth ??= DateTime(DateTime.now().year, DateTime.now().month, 1);
    final data = await ref
        .read(getAnalyticsUseCaseProvider)
        .call(_selectedMonth!);
    return AnalyticsState(selectedMonth: _selectedMonth!, data: data);
  }

  Future<void> previousMonth() async {
    final currentMonth = _selectedMonth ?? DateTime.now();
    _selectedMonth = currentMonth.month == 1
        ? DateTime(currentMonth.year - 1, 12, 1)
        : DateTime(currentMonth.year, currentMonth.month - 1, 1);
    await _reload();
  }

  Future<void> nextMonth() async {
    final currentMonth = _selectedMonth ?? DateTime.now();
    _selectedMonth = currentMonth.month == 12
        ? DateTime(currentMonth.year + 1, 1, 1)
        : DateTime(currentMonth.year, currentMonth.month + 1, 1);
    await _reload();
  }

  void selectDay(DateTime? day) {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      return;
    }

    state = AsyncData(currentState.copyWith(selectedDay: day));
  }

  Future<void> refresh() async {
    await _reload();
  }

  Future<void> _reload() async {
    final currentSelectedDay = state.valueOrNull?.selectedDay;
    state = const AsyncLoading();
    final selectedMonth = _selectedMonth ?? DateTime.now();
    final data = await ref
        .read(getAnalyticsUseCaseProvider)
        .call(selectedMonth);
    state = AsyncData(
      AnalyticsState(
        selectedMonth: selectedMonth,
        data: data,
        selectedDay: currentSelectedDay,
      ),
    );
  }
}

class ExpenseMutationController {
  const ExpenseMutationController(this._ref);

  final Ref _ref;

  Future<String?> saveDetectedExpense(ExpenseData expenseData) async {
    try {
      final expense = ExpenseEntity(
        amount: expenseData.amount,
        category: expenseData.category,
        description: expenseData.description.trim().isEmpty
            ? AppStrings.expenseLabel
            : expenseData.description.trim(),
        date: expenseData.parsedDate,
      );
      await _ref.read(saveExpenseUseCaseProvider).call(expense);
      _notifyExpenseChanged();
      await _ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(expense.category);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveDetectedExpenses(List<ExpenseData> expenses) async {
    try {
      final validExpenses = expenses
          .where((expense) => expense.isValid)
          .map(
            (expense) => ExpenseEntity(
              amount: expense.amount,
              category: expense.category,
              description: expense.description.trim().isEmpty
                  ? AppStrings.expenseLabel
                  : expense.description.trim(),
              date: expense.parsedDate,
            ),
          )
          .toList(growable: false);

      if (validExpenses.isEmpty) {
        return AppStrings.noExpenseToSave;
      }

      await _ref.read(saveExpenseUseCaseProvider).saveMany(validExpenses);
      _notifyExpenseChanged();
      final categories = validExpenses
          .map((expense) => expense.category)
          .toSet()
          .toList(growable: false);
      for (final category in categories) {
        await _ref
            .read(notificationProvider.notifier)
            .checkBudgetAlert(category);
      }
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveReceiptExpense(Map<String, dynamic> receiptData) async {
    try {
      final total = receiptData['total'];
      final dateValue = receiptData['date'] as String? ?? '';
      final merchant = receiptData['merchant'] as String? ?? 'Receipt';
      final summary = receiptData['summary'] as String? ?? '';
      final expense = ExpenseEntity(
        amount: total is num ? total.toDouble() : 0,
        category: receiptData['category'] as String? ?? 'Other',
        description: summary.trim().isEmpty ? merchant : summary.trim(),
        date: ExpenseData.parseDateValue(dateValue),
      );
      await _ref.read(saveExpenseUseCaseProvider).call(expense);
      _notifyExpenseChanged();
      await _ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(expense.category);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveManualExpense(ExpenseEntity expense) async {
    try {
      final normalizedDescription = expense.description.trim().isEmpty
          ? AppStrings.expenseLabel
          : expense.description.trim();
      final normalizedExpense = expense.copyWith(
        description: normalizedDescription,
        isManual: true,
      );
      await _ref.read(saveExpenseUseCaseProvider).call(normalizedExpense);
      _notifyExpenseChanged();
      await _ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(normalizedExpense.category);
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  void _notifyExpenseChanged() {
    _ref.read(expenseRefreshTokenProvider.notifier).state++;
    _ref.invalidate(dashboardControllerProvider);
    _ref.invalidate(expenseListControllerProvider);
    _ref.invalidate(analyticsControllerProvider);
  }
}
