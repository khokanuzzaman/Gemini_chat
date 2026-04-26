import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/json_block_extractor.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/notifications/budget_settings.dart';
import '../../../../core/premium/premium_providers.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/usage/usage_limits.dart';
import '../../../../core/usage/usage_providers.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/datasources/budget_plan_local_datasource.dart';
import '../../data/datasources/budget_planner_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget_plan_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/deactivate_all_usecase.dart';
import '../../domain/usecases/get_active_budget_usecase.dart';
import '../../domain/usecases/get_all_budgets_usecase.dart';
import '../../domain/usecases/save_budget_usecase.dart';
import '../../domain/usecases/set_active_budget_usecase.dart';
import '../../domain/usecases/update_budget_usecase.dart';

final budgetPlanLocalDataSourceProvider = Provider<BudgetPlanLocalDataSource>((
  ref,
) {
  return BudgetPlanLocalDataSource(ref.watch(isarProvider));
});

final budgetPlannerDataSourceProvider = Provider<BudgetPlannerDataSource>((
  ref,
) {
  return BudgetPlannerDataSource(
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(
    localDataSource: ref.watch(budgetPlanLocalDataSourceProvider),
  );
});

final getActiveBudgetUseCaseProvider = Provider<GetActiveBudgetUseCase>((ref) {
  return GetActiveBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final getAllBudgetsUseCaseProvider = Provider<GetAllBudgetsUseCase>((ref) {
  return GetAllBudgetsUseCase(ref.watch(budgetRepositoryProvider));
});

final saveBudgetUseCaseProvider = Provider<SaveBudgetUseCase>((ref) {
  return SaveBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final updateBudgetUseCaseProvider = Provider<UpdateBudgetUseCase>((ref) {
  return UpdateBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final setActiveBudgetUseCaseProvider = Provider<SetActiveBudgetUseCase>((ref) {
  return SetActiveBudgetUseCase(ref.watch(budgetRepositoryProvider));
});

final deactivateAllUseCaseProvider = Provider<DeactivateAllUseCase>((ref) {
  return DeactivateAllUseCase(ref.watch(budgetRepositoryProvider));
});

final effectiveBudgetLimitsProvider = Provider<Map<String, double>>((ref) {
  final activeBudget = ref.watch(budgetProvider).activeBudget;
  if (activeBudget != null) {
    return activeBudget.categoryBudgets;
  }
  return ref.watch(budgetSettingsProvider).categoryBudgets;
});

final budgetHealthReportProvider = FutureProvider<BudgetHealthReport>((
  ref,
) async {
  final budgetState = ref.watch(budgetProvider);
  final liveCategoryNames = ref
      .watch(categoryProvider)
      .map((category) => _normalizedCategoryKey(category.name))
      .toSet();

  final activeBudgetOrphans = _findOrphanedCategoryNames(
    budgetState.activeBudget?.categoryBudgets.keys ?? const <String>[],
    liveCategoryNames,
  );

  var historicalPlansWithOrphans = 0;
  final historicalOrphans = <String>{};
  for (final plan in budgetState.allBudgets) {
    final orphaned = _findOrphanedCategoryNames(
      plan.categoryBudgets.keys,
      liveCategoryNames,
    );
    if (orphaned.isEmpty) {
      continue;
    }
    historicalPlansWithOrphans++;
    historicalOrphans.addAll(orphaned);
  }

  List<ExpenseEntity> expenses = const [];
  try {
    expenses = await ref.watch(expenseRepositoryProvider).getAllExpenses();
  } catch (_) {
    expenses = const [];
  }
  final expenseHistoryOrphans = <String>{};
  for (final expense in expenses) {
    if (liveCategoryNames.contains(_normalizedCategoryKey(expense.category))) {
      continue;
    }
    expenseHistoryOrphans.add(expense.category);
  }

  final sortedHistoricalOrphans = historicalOrphans.toList(growable: false)
    ..sort();
  final sortedExpenseOrphans = expenseHistoryOrphans.toList(growable: false)
    ..sort();

  return BudgetHealthReport(
    activeBudgetOrphans: activeBudgetOrphans,
    historicalPlansWithOrphans: historicalPlansWithOrphans,
    historicalOrphans: sortedHistoricalOrphans,
    expenseHistoryOrphans: sortedExpenseOrphans,
  );
});

class BudgetHealthReport {
  const BudgetHealthReport({
    this.activeBudgetOrphans = const [],
    this.historicalPlansWithOrphans = 0,
    this.historicalOrphans = const [],
    this.expenseHistoryOrphans = const [],
  });

  final List<String> activeBudgetOrphans;
  final int historicalPlansWithOrphans;
  final List<String> historicalOrphans;
  final List<String> expenseHistoryOrphans;

  bool get hasIssues =>
      activeBudgetOrphans.isNotEmpty ||
      historicalPlansWithOrphans > 0 ||
      expenseHistoryOrphans.isNotEmpty;
}

class BudgetState {
  const BudgetState({
    this.activeBudget,
    this.allBudgets = const [],
    this.isLoading = false,
    this.isGenerating = false,
    this.streamingText = '',
    this.error,
    this.incomeInput,
    this.selectedRule = BudgetRule.fiftyThirtyTwenty,
  });

  final BudgetPlanEntity? activeBudget;
  final List<BudgetPlanEntity> allBudgets;
  final bool isLoading;
  final bool isGenerating;
  final String streamingText;
  final String? error;
  final double? incomeInput;
  final BudgetRule selectedRule;

  BudgetState copyWith({
    BudgetPlanEntity? activeBudget,
    bool clearActiveBudget = false,
    List<BudgetPlanEntity>? allBudgets,
    bool? isLoading,
    bool? isGenerating,
    String? streamingText,
    String? error,
    bool clearError = false,
    double? incomeInput,
    bool clearIncomeInput = false,
    BudgetRule? selectedRule,
  }) {
    return BudgetState(
      activeBudget: clearActiveBudget
          ? null
          : activeBudget ?? this.activeBudget,
      allBudgets: allBudgets ?? this.allBudgets,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : error ?? this.error,
      incomeInput: clearIncomeInput ? null : incomeInput ?? this.incomeInput,
      selectedRule: selectedRule ?? this.selectedRule,
    );
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);

class BudgetNotifier extends Notifier<BudgetState> {
  bool _loadScheduled = false;

  @override
  BudgetState build() {
    if (!_loadScheduled) {
      _loadScheduled = true;
      Future<void>.microtask(_initialize);
    }
    return const BudgetState();
  }

  Future<void> refresh() => _loadActiveBudget();

  void setIncome(double? income) {
    state = state.copyWith(incomeInput: income, clearError: true);
  }

  void setRule(BudgetRule rule) {
    state = state.copyWith(selectedRule: rule, clearError: true);
  }

  Future<void> generateBudget() async {
    final income = state.incomeInput;
    if (income == null || income <= 0) {
      state = state.copyWith(error: 'আয়ের পরিমাণ দিন');
      return;
    }

    if (state.isGenerating) {
      return;
    }

    final isConnected = await ref
        .read(connectivityServiceProvider)
        .isConnected();
    if (!isConnected) {
      state = state.copyWith(
        error: 'ইন্টারনেট নেই — budget generate করা যাচ্ছে না',
      );
      return;
    }

    if (!await _consumeAiBudgetUsage()) {
      return;
    }

    state = state.copyWith(
      isGenerating: true,
      streamingText: '',
      clearError: true,
    );

    try {
      final avgByCategory = await _getAvgMonthlySpending();
      final categories = ref
          .read(categoryProvider)
          .map((category) => category.name)
          .toList(growable: false);

      var fullResponse = '';
      await for (final chunk
          in ref
              .read(budgetPlannerDataSourceProvider)
              .generateBudget(
                monthlyIncome: income,
                avgMonthlyByCategory: avgByCategory,
                availableCategories: categories,
                preferredRule: state.selectedRule,
              )) {
        fullResponse += chunk;
        state = state.copyWith(streamingText: fullResponse);
      }

      final plan = _parseResponse(
        response: fullResponse,
        income: income,
        availableCategories: categories,
        avgByCategory: avgByCategory,
      );

      await ref.read(deactivateAllUseCaseProvider).call();
      await ref.read(saveBudgetUseCaseProvider).call(plan);
      await _updateNotificationBudgets(plan);
      await _loadActiveBudget();

      state = state.copyWith(
        isGenerating: false,
        streamingText: '',
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Budget তৈরি করতে সমস্যা হয়েছে',
      );
    }
  }

  Future<void> restoreBudget(int id, {Set<String>? liveCategoryNames}) async {
    final budget = state.allBudgets.where((item) => item.id == id).firstOrNull;
    if (budget != null && liveCategoryNames != null) {
      final sanitizedBudgets = _filterLiveCategoryBudgets(
        budget.categoryBudgets,
        liveCategoryNames,
      );
      if (!_mapsEqual(sanitizedBudgets, budget.categoryBudgets)) {
        await ref
            .read(updateBudgetUseCaseProvider)
            .call(_copyWithCategoryBudgets(budget, sanitizedBudgets));
      }
    }

    await ref.read(setActiveBudgetUseCaseProvider).call(id);
    final refreshedBudget = state.allBudgets
        .where((item) => item.id == id)
        .firstOrNull;
    if (refreshedBudget != null) {
      await _updateNotificationBudgets(
        refreshedBudget.copyWith(isActive: true, updatedAt: DateTime.now()),
      );
    }
    await _loadActiveBudget();
  }

  Future<void> updateCategoryBudget(String category, double amount) async {
    final currentBudget = state.activeBudget;
    if (currentBudget == null) {
      return;
    }

    final liveNames = ref.read(categoryProvider).map((c) => c.name).toSet();
    if (!liveNames.contains(category)) {
      return;
    }

    final sanitizedAmount = amount.isNaN || amount.isNegative ? 0.0 : amount;
    final orderedLiveCategories = ref
        .read(categoryProvider)
        .map((item) => item.name)
        .toList(growable: false);
    final updatedBudgets = _normalizeCategoryBudgetsForLiveCategories(
      orderedLiveCategories: orderedLiveCategories,
      incomingBudgets: {
        ...currentBudget.categoryBudgets,
        category: sanitizedAmount,
      },
      fallbackBudgets: currentBudget.categoryBudgets,
    );
    await _saveActiveBudgetWithCategoryBudgets(updatedBudgets);
  }

  Future<void> saveCategoryBudgets(Map<String, double> budgets) async {
    final currentBudget = state.activeBudget;
    if (currentBudget == null) {
      return;
    }

    final orderedLiveCategories = ref
        .read(categoryProvider)
        .map((item) => item.name)
        .toList(growable: false);
    final updatedBudgets = _normalizeCategoryBudgetsForLiveCategories(
      orderedLiveCategories: orderedLiveCategories,
      incomingBudgets: budgets,
      fallbackBudgets: currentBudget.categoryBudgets,
    );
    await _saveActiveBudgetWithCategoryBudgets(updatedBudgets);
  }

  Future<bool> remapCategoryInBudget(String oldName, String newName) async {
    try {
      await ref
          .read(budgetPlanLocalDataSourceProvider)
          .migrateCategory(oldName, newName);
      await _loadActiveBudget();
      return true;
    } catch (error) {
      debugPrint('[BudgetNotifier] Failed to remap category in budget: $error');
      return false;
    }
  }

  Future<bool> removeCategoryFromBudget(String categoryName) async {
    try {
      await ref
          .read(budgetPlanLocalDataSourceProvider)
          .removeCategoryFromAllPlans(categoryName);
      await _loadActiveBudget();
      return true;
    } catch (error) {
      debugPrint(
        '[BudgetNotifier] Failed to remove category from budget: $error',
      );
      return false;
    }
  }

  Future<void> _loadActiveBudget() async {
    state = state.copyWith(isLoading: true);
    try {
      final activeBudget = await ref
          .read(getActiveBudgetUseCaseProvider)
          .call();
      final allBudgets = await ref.read(getAllBudgetsUseCaseProvider).call();
      state = state.copyWith(
        activeBudget: activeBudget,
        allBudgets: allBudgets,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        clearActiveBudget: true,
        allBudgets: const [],
        isLoading: false,
        clearError: true,
      );
    }
  }

  Future<void> _initialize() async {
    await _removeLegacyCategoryBudgetsKey();
    await _loadActiveBudget();
  }

  BudgetPlanEntity? _getActiveBudget() {
    return state.activeBudget;
  }

  Future<void> _saveActiveBudgetWithCategoryBudgets(
    Map<String, double> categoryBudgets,
  ) async {
    final currentBudget = _getActiveBudget();
    if (currentBudget == null) {
      return;
    }

    final updated = _copyWithCategoryBudgets(currentBudget, categoryBudgets);
    await ref.read(updateBudgetUseCaseProvider).call(updated);
    await _updateNotificationBudgets(updated);
    await _loadActiveBudget();
  }

  BudgetPlanEntity _copyWithCategoryBudgets(
    BudgetPlanEntity budget,
    Map<String, double> categoryBudgets,
  ) {
    final totalBudgeted = categoryBudgets.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final savingsAmount = (budget.monthlyIncome - totalBudgeted)
        .clamp(0.0, budget.monthlyIncome)
        .toDouble();
    final savingsPercentage = budget.monthlyIncome <= 0
        ? 0.0
        : (savingsAmount / budget.monthlyIncome) * 100;

    return budget.copyWith(
      categoryBudgets: categoryBudgets,
      totalBudgeted: totalBudgeted,
      savingsAmount: savingsAmount,
      savingsPercentage: savingsPercentage,
      updatedAt: DateTime.now(),
    );
  }

  Future<Map<String, double>> _getAvgMonthlySpending() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 3, 1);
    final expenses = await ref
        .read(expenseRepositoryProvider)
        .getExpensesByDateRange(start, now);
    final byCategory = <String, double>{};
    for (final expense in expenses) {
      byCategory.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return byCategory.map((key, value) => MapEntry(key, value / 3));
  }

  Future<bool> _consumeAiBudgetUsage() async {
    if (await _isPremiumUser()) {
      return true;
    }

    try {
      final gate = await ref
          .read(usageTrackerServiceProvider)
          .checkAndConsume(UsageLimits.aiBudget);
      if (!gate.isAllowed) {
        state = state.copyWith(
          isGenerating: false,
          streamingText: '',
          error:
              'এই মাসের AI বাজেট সীমা শেষ (${gate.status.used}/${gate.status.limit} ব্যবহার হয়েছে). প্রিমিয়াম এ আপগ্রেড করুন।',
        );
        return false;
      }

      ref.read(usageRefreshTokenProvider.notifier).state++;
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _isPremiumUser() async {
    if (ref.read(isPremiumProvider)) {
      return true;
    }

    try {
      return await ref.read(premiumServiceProvider).isPremium();
    } catch (_) {
      return false;
    }
  }

  BudgetPlanEntity _parseResponse({
    required String response,
    required double income,
    required List<String> availableCategories,
    required Map<String, double> avgByCategory,
  }) {
    final jsonBlock = JsonBlockExtractor.extractFirstObject(response);
    final explanation = JsonBlockExtractor.removeFirstBlock(
      response,
      jsonBlock,
    );

    var parsedRule = state.selectedRule;
    var totalBudgeted = 0.0;
    var savingsAmount = 0.0;
    var savingsPercentage = 0.0;
    var categoryBudgets = <String, double>{};

    if (jsonBlock != null) {
      try {
        final decoded = jsonDecode(jsonBlock);
        if (decoded is Map<String, dynamic>) {
          final ruleName = decoded['rule']?.toString();
          if (ruleName != null) {
            parsedRule = BudgetRule.values.firstWhere(
              (rule) => rule.name == ruleName,
              orElse: () => state.selectedRule,
            );
          }
          totalBudgeted = (decoded['totalBudgeted'] as num?)?.toDouble() ?? 0;
          savingsAmount = (decoded['savingsAmount'] as num?)?.toDouble() ?? 0;
          savingsPercentage =
              (decoded['savingsPercentage'] as num?)?.toDouble() ?? 0;
          final rawBudgets = decoded['categoryBudgets'];
          if (rawBudgets is Map) {
            for (final entry in rawBudgets.entries) {
              if (!availableCategories.contains(entry.key.toString())) {
                continue;
              }
              final value = entry.value;
              if (value is num && value >= 0) {
                categoryBudgets[entry.key.toString()] = value.toDouble();
              }
            }
          }
        }
      } catch (_) {}
    }

    if (categoryBudgets.isEmpty) {
      categoryBudgets = _buildFallbackBudgets(
        income: income,
        availableCategories: availableCategories,
        avgByCategory: avgByCategory,
        rule: parsedRule,
      );
    }

    for (final category in availableCategories) {
      categoryBudgets.putIfAbsent(category, () => 0.0);
    }

    totalBudgeted = categoryBudgets.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final minimumSavings = income * 0.1;
    if (income > 0 && totalBudgeted > income - minimumSavings) {
      final targetBudgeted = (income - minimumSavings)
          .clamp(0.0, income)
          .toDouble();
      final scale = totalBudgeted <= 0 ? 0.0 : targetBudgeted / totalBudgeted;
      categoryBudgets = categoryBudgets.map(
        (key, value) => MapEntry(key, value * scale),
      );
      totalBudgeted = categoryBudgets.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
    }

    savingsAmount = (income - totalBudgeted).clamp(0.0, income).toDouble();
    savingsPercentage = income <= 0 ? 0.0 : (savingsAmount / income) * 100;
    final effectiveExplanation = explanation.isEmpty
        ? 'আপনার আয়, বর্তমান খরচের ধরন এবং নির্বাচিত নিয়ম দেখে এই বাজেটটি সাজানো হয়েছে।'
        : explanation;

    final now = DateTime.now();
    return BudgetPlanEntity(
      id: 0,
      monthlyIncome: income,
      categoryBudgets: categoryBudgets,
      totalBudgeted: totalBudgeted,
      savingsAmount: savingsAmount,
      savingsPercentage: savingsPercentage,
      aiExplanation: effectiveExplanation,
      budgetRule: parsedRule,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  Map<String, double> _buildFallbackBudgets({
    required double income,
    required List<String> availableCategories,
    required Map<String, double> avgByCategory,
    required BudgetRule rule,
  }) {
    final expensesShare = switch (rule) {
      BudgetRule.fiftyThirtyTwenty => 0.8,
      BudgetRule.seventyTwentyTen => 0.7,
      BudgetRule.custom => 0.82,
    };
    final targetBudgeted = income * expensesShare;
    final totalHistorical = avgByCategory.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final defaultWeights = <String, double>{
      'Food': 0.24,
      'Transport': 0.12,
      'Bill': 0.14,
      'Healthcare': 0.08,
      'Shopping': 0.12,
      'Entertainment': 0.08,
      'Other': 0.08,
    };

    final weights = <String, double>{};
    if (totalHistorical > 0) {
      for (final category in availableCategories) {
        final historical = avgByCategory[category] ?? 0;
        weights[category] = historical > 0
            ? historical / totalHistorical
            : (defaultWeights[category] ?? (1 / availableCategories.length));
      }
    } else {
      for (final category in availableCategories) {
        weights[category] =
            defaultWeights[category] ?? (1 / availableCategories.length);
      }
    }

    final totalWeight = weights.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    return weights.map(
      (key, value) => MapEntry(key, targetBudgeted * (value / totalWeight)),
    );
  }

  Future<void> _updateNotificationBudgets(BudgetPlanEntity _) async {
    await _removeLegacyCategoryBudgetsKey();
  }

  Future<void> _removeLegacyCategoryBudgetsKey() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.containsKey('category_budgets')) {
        await prefs.remove('category_budgets');
      }
    } catch (_) {}
  }
}

Map<String, double> _normalizeCategoryBudgetsForLiveCategories({
  required List<String> orderedLiveCategories,
  required Map<String, double> incomingBudgets,
  Map<String, double>? fallbackBudgets,
}) {
  final normalized = <String, double>{};
  for (final category in orderedLiveCategories) {
    final rawValue = incomingBudgets.containsKey(category)
        ? incomingBudgets[category]
        : fallbackBudgets?[category];
    final value = rawValue ?? 0.0;
    normalized[category] = value.isNaN || value.isNegative ? 0.0 : value;
  }
  return normalized;
}

Map<String, double> _filterLiveCategoryBudgets(
  Map<String, double> budgets,
  Set<String> liveCategoryNames,
) {
  final filtered = <String, double>{};
  for (final entry in budgets.entries) {
    if (!liveCategoryNames.contains(_normalizedCategoryKey(entry.key))) {
      continue;
    }
    filtered[entry.key] = entry.value.isNaN || entry.value.isNegative
        ? 0.0
        : entry.value;
  }
  return filtered;
}

List<String> _findOrphanedCategoryNames(
  Iterable<String> categoryNames,
  Set<String> liveCategoryNames,
) {
  final orphaned = <String>{};
  for (final categoryName in categoryNames) {
    if (liveCategoryNames.contains(_normalizedCategoryKey(categoryName))) {
      continue;
    }
    orphaned.add(categoryName);
  }
  final sorted = orphaned.toList(growable: false)..sort();
  return sorted;
}

String _normalizedCategoryKey(String name) => name.trim().toLowerCase();

bool _mapsEqual(Map<String, double> first, Map<String, double> second) {
  if (first.length != second.length) {
    return false;
  }
  for (final entry in first.entries) {
    if (!second.containsKey(entry.key) || second[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
