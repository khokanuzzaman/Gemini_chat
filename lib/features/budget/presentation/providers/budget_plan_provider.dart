import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/json_block_extractor.dart';
import '../../../../core/database/models/budget_plan_model.dart';
import '../../../../core/notifications/budget_settings.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/datasources/budget_plan_local_datasource.dart';
import '../../data/datasources/budget_planner_datasource.dart';
import '../../domain/entities/budget_plan_entity.dart';

final budgetPlanLocalDataSourceProvider = Provider<BudgetPlanLocalDataSource>((
  ref,
) {
  return BudgetPlanLocalDataSource(ref.watch(isarProvider));
});

final budgetPlannerDataSourceProvider = Provider<BudgetPlannerDataSource>((
  ref,
) {
  return BudgetPlannerDataSourceImpl();
});

final budgetPlanProvider =
    AsyncNotifierProvider<BudgetPlanNotifier, BudgetPlanEntity?>(
      BudgetPlanNotifier.new,
    );

class BudgetPlanNotifier extends AsyncNotifier<BudgetPlanEntity?> {
  @override
  Future<BudgetPlanEntity?> build() async {
    final model = await ref
        .read(budgetPlanLocalDataSourceProvider)
        .getLatestPlan();
    return model?.toEntity();
  }

  Future<BudgetPlanEntity?> generatePlan({
    required double monthlyIncome,
  }) async {
    final categories = ref.read(categoryProvider);
    final expenses = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final last3MonthsExpenses = expenses
        .where((expense) => expense.date.isAfter(threeMonthsAgo))
        .toList(growable: false);

    String latestResponse = '';
    await for (final chunk
        in ref
            .read(budgetPlannerDataSourceProvider)
            .generateBudgetPlan(
              monthlyIncome: monthlyIncome,
              last3MonthsExpenses: last3MonthsExpenses,
              categories: categories,
            )) {
      latestResponse = chunk;
    }

    return parsePlanResponse(
      response: latestResponse,
      monthlyIncome: monthlyIncome,
    );
  }

  BudgetPlanEntity? parsePlanResponse({
    required String response,
    required double monthlyIncome,
  }) {
    final jsonBlock = JsonBlockExtractor.extractFirstObject(response);
    if (jsonBlock == null) {
      return null;
    }

    final explanation = JsonBlockExtractor.removeFirstBlock(
      response,
      jsonBlock,
    );

    try {
      final decoded = jsonDecode(jsonBlock);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rawBudgets = decoded['categoryBudgets'];
      if (rawBudgets is! Map) {
        return null;
      }

      final categoryBudgets = <String, double>{};
      for (final entry in rawBudgets.entries) {
        final value = entry.value;
        if (value is num) {
          categoryBudgets[entry.key.toString()] = value.toDouble();
        }
      }

      if (categoryBudgets.isEmpty) {
        return null;
      }

      final now = DateTime.now();
      return BudgetPlanEntity(
        id: 0,
        monthlyIncome: monthlyIncome,
        categoryBudgets: categoryBudgets,
        createdAt: now,
        updatedAt: now,
        aiSuggestion: explanation.isEmpty ? response.trim() : explanation,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlan(
    BudgetPlanEntity plan, {
    bool applyBudgets = true,
  }) async {
    final normalizedPlan = plan.copyWith(updatedAt: DateTime.now());
    await ref
        .read(budgetPlanLocalDataSourceProvider)
        .savePlan(BudgetPlanModel.fromEntity(normalizedPlan));
    if (applyBudgets) {
      await ref
          .read(budgetProvider.notifier)
          .saveBudgets(normalizedPlan.categoryBudgets);
    }
    state = AsyncData(normalizedPlan);
  }
}
