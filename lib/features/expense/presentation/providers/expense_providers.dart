import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/ledger/wallet_ledger_service.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/ai/expense_result.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../data/mappers/expense_record_mapper.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_source_filters.dart';
import '../../domain/entities/expense_list_filter.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_analytics_usecase.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import '../../domain/usecases/get_expense_list_usecase.dart';
import '../../domain/usecases/save_expense_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import 'expense_refresh_provider.dart';

export 'expense_refresh_provider.dart';

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

class CashFlowData {
  const CashFlowData({
    required this.income,
    required this.expense,
    required this.lastMonthIncome,
    required this.lastMonthExpense,
    this.savings = 0,
  });

  final double income;
  final double expense;
  final double lastMonthIncome;
  final double lastMonthExpense;

  /// Goal deposits this month (wallet→goal transfers). Not consumption, so it is
  /// separate from [expense]: the wallet change for the month is
  /// `netFlow - savings` (income − expense − savings).
  final double savings;

  double get netFlow => income - expense;
  double get lastMonthNetFlow => lastMonthIncome - lastMonthExpense;

  double get savingsRate {
    if (income <= 0) {
      return 0;
    }
    return (netFlow / income) * 100;
  }

  bool get isPositive => netFlow >= 0;

  double get netFlowChangePercent {
    if (lastMonthNetFlow == 0) {
      return 0;
    }
    return ((netFlow - lastMonthNetFlow) / lastMonthNetFlow.abs()) * 100;
  }
}

final dashboardLastRefreshedAtProvider = StateProvider<DateTime?>((ref) => null);

final cashFlowProvider = FutureProvider<CashFlowData>((ref) async {
  ref.watch(expenseRefreshTokenProvider);
  ref.watch(incomeRefreshTokenProvider);

  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final thisMonthEnd = DateTime(
    now.year,
    now.month + 1,
    1,
  ).subtract(const Duration(milliseconds: 1));
  final lastMonthStart = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = thisMonthStart.subtract(const Duration(milliseconds: 1));

  final expenseRepo = ref.read(expenseRepositoryProvider);
  final incomeUseCase = ref.read(getIncomeTotalsUseCaseProvider);

  final thisMonthExpenses = await expenseRepo.getExpensesByDateRange(
    thisMonthStart,
    thisMonthEnd,
  );
  final lastMonthExpenses = await expenseRepo.getExpensesByDateRange(
    lastMonthStart,
    lastMonthEnd,
  );
  final thisMonthIncome = await incomeUseCase.forRange(
    thisMonthStart,
    thisMonthEnd,
  );
  final lastMonthIncome = await incomeUseCase.forRange(
    lastMonthStart,
    lastMonthEnd,
  );
  // Savings = goal deposits this month, read straight from GoalSaving rows
  // (goal deposits are transfers, not expenses — they carry no expense record).
  final thisMonthSavings = await ref
      .read(goalLocalDataSourceProvider)
      .getTotalSavingsForRange(thisMonthStart, thisMonthEnd);

  return CashFlowData(
    income: thisMonthIncome,
    expense: thisMonthExpenses.inCashFlow.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    ),
    savings: thisMonthSavings,
    lastMonthIncome: lastMonthIncome,
    lastMonthExpense: lastMonthExpenses.inCashFlow.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    ),
  );
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
      walletId: _filter.walletId,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
    );
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> setWallet(int? walletId) async {
    _filter = ExpenseListFilter(
      category: _filter.category,
      walletId: walletId,
      startDate: _filter.startDate,
      endDate: _filter.endDate,
    );
    state = const AsyncLoading();
    state = AsyncData(await _loadState());
  }

  Future<void> setDateRange(DateTime start, DateTime end) async {
    _filter = ExpenseListFilter(
      category: _filter.category,
      walletId: _filter.walletId,
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

      // Delete the record and refund the wallet atomically (reverse of the
      // original outflow -amount => +amount refund).
      await ref.read(walletLedgerServiceProvider).reverse(
        entry: WalletLedgerEntry(
          walletId: expense.walletId,
          appliedDelta: -expense.amount,
          recordIds: LedgerRecordIds(expenseRecordId: expense.id),
        ),
        deleteRecords: (txn) async {
          final deleted = await ref
              .read(expenseLocalDataSourceProvider)
              .deleteExpenseInTxn(txn, expense.id!);
          if (!deleted) {
            throw const StorageFailure('খরচটি খুঁজে পাওয়া যায়নি');
          }
        },
      );
      ref.invalidate(walletProvider);
      await ref.read(anomalyProvider.notifier).reDetect();
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(analyticsControllerProvider);
      state = AsyncData(await _loadState());
      _notifyExpenseChanged();
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
      final previousExpense =
          _findExpenseInState(currentState?.expenses, expense.id!) ??
          await _findExpenseById(expense.id!);
      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            expenses: _applyUpdatedExpense(currentState.expenses, expense),
          ),
        );
      }

      // Record update + wallet move in one atomic ledger op. The expense
      // outflow that was applied for the old version (-previous.amount) is
      // undone and the new outflow (-updated.amount) applied — same wallet nets
      // to one delta, cross-wallet refunds old and charges new.
      await ref.read(walletLedgerServiceProvider).amend(
        updateRecords: (txn) async {
          final ok = await ref
              .read(expenseLocalDataSourceProvider)
              .updateExpenseInTxn(txn, expense.toModel());
          if (!ok) {
            throw const StorageFailure('খরচটি খুঁজে পাওয়া যায়নি');
          }
          return LedgerRecordIds(expenseRecordId: expense.id);
        },
        oldWalletId: previousExpense?.walletId,
        oldAppliedDelta: -(previousExpense?.amount ?? 0),
        newWalletId: expense.walletId,
        newAppliedDelta: -expense.amount,
      );
      ref.invalidate(walletProvider);
      await ref.read(anomalyProvider.notifier).reDetect();
      await _checkBudgetAlertsAfterUpdate(
        previousExpense: previousExpense,
        updatedExpense: expense,
      );
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(analyticsControllerProvider);
      state = AsyncData(await _loadState());
      _notifyExpenseChanged();
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
    ref.read(predictionRefreshTokenProvider.notifier).state++;
  }

  ExpenseEntity? _findExpenseInState(List<ExpenseEntity>? expenses, int id) {
    if (expenses == null) {
      return null;
    }

    for (final expense in expenses) {
      if (expense.id == id) {
        return expense;
      }
    }

    return null;
  }

  Future<ExpenseEntity?> _findExpenseById(int id) async {
    final expenses = await ref.read(expenseRepositoryProvider).getAllExpenses();
    for (final expense in expenses) {
      if (expense.id == id) {
        return expense;
      }
    }
    return null;
  }

  Future<void> _checkBudgetAlertsAfterUpdate({
    required ExpenseEntity? previousExpense,
    required ExpenseEntity updatedExpense,
  }) async {
    try {
      await ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(updatedExpense.category);
    } catch (_) {}

    final previousCategory = previousExpense?.category;
    if (previousCategory == null ||
        previousCategory == updatedExpense.category) {
      return;
    }

    try {
      await ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(previousCategory);
    } catch (_) {}
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

    if (_filter.walletId != null && expense.walletId != _filter.walletId) {
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

  Future<DetectedExpenseSaveResult> saveDetectedExpenseDetailed(
    ExpenseData expenseData, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return const DetectedExpenseSaveResult(
          error: 'কোনো ওয়ালেট পাওয়া যায়নি',
        );
      }

      final expense = ExpenseEntity(
        amount: expenseData.amount,
        category: expenseData.category,
        description: expenseData.description.trim().isEmpty
            ? AppStrings.expenseLabel
            : expenseData.description.trim(),
        date: expenseData.parsedDate,
        walletId: resolvedWalletId,
      );
      if (await _isDuplicateExpense(expense)) {
        return const DetectedExpenseSaveResult(
          error: 'একই খরচ আগেই যোগ করা আছে',
        );
      }
      final entry = await _ref.read(walletLedgerServiceProvider).execute(
        walletId: resolvedWalletId,
        delta: -expense.amount,
        writeRecords: (txn) async {
          final id = await _ref
              .read(expenseLocalDataSourceProvider)
              .putExpenseInTxn(txn, expense.toModel());
          return LedgerRecordIds(expenseRecordId: id);
        },
      );
      _ref.invalidate(walletProvider);
      final savedExpense = expense.copyWith(
        id: entry.recordIds.expenseRecordId,
      );
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyExpenseChanged(addedCount: 1);
      await _ref
          .read(notificationProvider.notifier)
          .checkBudgetAlert(expense.category);
      return DetectedExpenseSaveResult(expense: savedExpense);
    } on Failure catch (failure) {
      return DetectedExpenseSaveResult(error: failure.message);
    } catch (error) {
      return DetectedExpenseSaveResult(error: '$error');
    }
  }

  Future<String?> saveDetectedExpense(
    ExpenseData expenseData, {
    int? walletId,
  }) async {
    final result = await saveDetectedExpenseDetailed(
      expenseData,
      walletId: walletId,
    );
    return result.error;
  }

  Future<String?> saveDetectedExpenses(
    List<ExpenseData> expenses, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

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
              walletId: resolvedWalletId,
            ),
          )
          .toList(growable: false);

      if (validExpenses.isEmpty) {
        return AppStrings.noExpenseToSave;
      }

      final dedupedExpenses = <ExpenseEntity>[];
      var skippedDuplicates = 0;
      for (final expense in validExpenses) {
        final alreadyQueued = dedupedExpenses.any(
          (existing) => _isSameExpense(existing, expense),
        );
        if (alreadyQueued || await _isDuplicateExpense(expense)) {
          skippedDuplicates++;
          continue;
        }
        dedupedExpenses.add(expense);
      }

      if (dedupedExpenses.isEmpty) {
        return 'একই খরচ আগেই যোগ করা আছে';
      }

      // One atomic ledger op for the whole batch: all N records + a single
      // summed wallet delta commit together (deliberate C1 fix — no partial
      // application; replaces the old per-row swallowed adjust loop).
      final batchTotal = dedupedExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );
      await _ref.read(walletLedgerServiceProvider).execute(
        walletId: resolvedWalletId,
        delta: -batchTotal,
        writeRecords: (txn) async {
          await _ref.read(expenseLocalDataSourceProvider).putExpensesInTxn(
            txn,
            dedupedExpenses
                .map((expense) => expense.toModel())
                .toList(growable: false),
          );
          return const LedgerRecordIds();
        },
      );
      _ref.invalidate(walletProvider);
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyExpenseChanged(addedCount: dedupedExpenses.length);
      final categories = dedupedExpenses
          .map((expense) => expense.category)
          .toSet()
          .toList(growable: false);
      for (final category in categories) {
        await _ref
            .read(notificationProvider.notifier)
            .checkBudgetAlert(category);
      }
      if (skippedDuplicates > 0) {
        return '${BanglaFormatters.count(dedupedExpenses.length)}'
            'টি নতুন খরচ সংরক্ষণ হয়েছে, '
            '${BanglaFormatters.count(skippedDuplicates)}'
            'টি duplicate বাদ গেছে';
      }
      return null;
    } on Failure catch (failure) {
      return failure.message;
    } catch (error) {
      return '$error';
    }
  }

  Future<String?> saveReceiptExpense(
    Map<String, dynamic> receiptData, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(walletId);
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

      final total = receiptData['total'];
      final dateValue = receiptData['date'] as String? ?? '';
      final merchant = receiptData['merchant'] as String? ?? 'Receipt';
      final summary = receiptData['summary'] as String? ?? '';
      final expense = ExpenseEntity(
        amount: total is num ? total.toDouble() : 0,
        category: receiptData['category'] as String? ?? 'Other',
        description: summary.trim().isEmpty ? merchant : summary.trim(),
        date: ExpenseData.parseDateValue(dateValue),
        walletId: resolvedWalletId,
      );
      if (await _isDuplicateExpense(expense)) {
        return 'একই খরচ আগেই যোগ করা আছে';
      }
      await _ref.read(walletLedgerServiceProvider).execute(
        walletId: resolvedWalletId,
        delta: -expense.amount,
        writeRecords: (txn) async {
          final id = await _ref
              .read(expenseLocalDataSourceProvider)
              .putExpenseInTxn(txn, expense.toModel());
          return LedgerRecordIds(expenseRecordId: id);
        },
      );
      _ref.invalidate(walletProvider);
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyExpenseChanged(addedCount: 1);
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

  Future<String?> saveManualExpense(
    ExpenseEntity expense, {
    int? walletId,
  }) async {
    try {
      final resolvedWalletId = await _resolveWalletId(
        walletId ?? expense.walletId,
      );
      if (resolvedWalletId == null) {
        return 'কোনো ওয়ালেট পাওয়া যায়নি';
      }

      final normalizedDescription = expense.description.trim().isEmpty
          ? AppStrings.expenseLabel
          : expense.description.trim();
      final normalizedExpense = expense.copyWith(
        description: normalizedDescription,
        walletId: resolvedWalletId,
        isManual: true,
      );
      await _ref.read(walletLedgerServiceProvider).execute(
        walletId: resolvedWalletId,
        delta: -normalizedExpense.amount,
        writeRecords: (txn) async {
          final id = await _ref
              .read(expenseLocalDataSourceProvider)
              .putExpenseInTxn(txn, normalizedExpense.toModel());
          return LedgerRecordIds(expenseRecordId: id);
        },
      );
      _ref.invalidate(walletProvider);
      await _rememberActiveWallet(resolvedWalletId);
      await _notifyExpenseChanged(addedCount: 1);
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

  Future<void> _notifyExpenseChanged({int addedCount = 0}) async {
    _ref.read(expenseRefreshTokenProvider.notifier).state++;
    _ref.read(predictionRefreshTokenProvider.notifier).state++;
    _ref.invalidate(dashboardControllerProvider);
    _ref.invalidate(expenseListControllerProvider);
    _ref.invalidate(analyticsControllerProvider);
    await _ref.read(anomalyProvider.notifier).reDetect();
    if (addedCount > 0) {
      await _ref
          .read(predictionProvider.notifier)
          .registerExpenseSaves(addedCount);
    }
  }

  Future<int?> _resolveWalletId(int? explicitWalletId) async {
    if (explicitWalletId != null) {
      return explicitWalletId;
    }

    final activeWallet = _ref.read(activeWalletProvider);
    if (activeWallet != null) {
      return activeWallet.id;
    }

    final savedWalletId = await AppPreferences.activeWalletId();
    final wallets = await _ref.read(walletProvider.future);
    if (wallets.isEmpty) {
      return null;
    }

    if (savedWalletId != null) {
      for (final wallet in wallets) {
        if (wallet.id == savedWalletId) {
          return wallet.id;
        }
      }
    }

    for (final wallet in wallets) {
      if (wallet.type == WalletType.cash) {
        return wallet.id;
      }
    }

    return wallets.first.id;
  }

  Future<void> _rememberActiveWallet(int walletId) async {
    _ref.read(activeWalletIdProvider.notifier).state = walletId;
    await AppPreferences.setActiveWalletId(walletId);
  }

  Future<bool> _isDuplicateExpense(ExpenseEntity candidate) async {
    final sameDayExpenses = await _ref
        .read(expenseRepositoryProvider)
        .getExpensesByDateRange(candidate.date, candidate.date);
    for (final existing in sameDayExpenses) {
      if (_isSameExpense(existing, candidate)) {
        return true;
      }
    }
    return false;
  }

  bool _isSameExpense(ExpenseEntity first, ExpenseEntity second) {
    return first.walletId == second.walletId &&
        first.amount == second.amount &&
        first.category == second.category &&
        _normalizeText(first.description) ==
            _normalizeText(second.description) &&
        first.date.year == second.date.year &&
        first.date.month == second.date.month &&
        first.date.day == second.date.day;
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class DetectedExpenseSaveResult {
  const DetectedExpenseSaveResult({this.expense, this.error});

  final ExpenseEntity? expense;
  final String? error;

  bool get isSuccess => expense != null && error == null;
}
