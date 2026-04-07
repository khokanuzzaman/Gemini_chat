import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../features/budget/domain/entities/budget_plan_entity.dart';

part 'budget_plan_model.g.dart';

@collection
class BudgetPlanModel {
  Id id = Isar.autoIncrement;

  late double monthlyIncome;
  late String categoryBudgetsJson;
  late double totalBudgeted;
  late double savingsAmount;
  late double savingsPercentage;
  late String aiExplanation;
  late String budgetRule;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isActive;

  BudgetPlanEntity toEntity() {
    final budgets = <String, double>{};
    final decoded = jsonDecode(categoryBudgetsJson);
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is num) {
          budgets[entry.key.toString()] = value.toDouble();
        }
      }
    }

    return BudgetPlanEntity(
      id: id,
      monthlyIncome: monthlyIncome,
      categoryBudgets: budgets,
      totalBudgeted: totalBudgeted,
      savingsAmount: savingsAmount,
      savingsPercentage: savingsPercentage,
      aiExplanation: aiExplanation,
      budgetRule: BudgetRule.values.firstWhere(
        (value) => value.name == budgetRule,
        orElse: () => BudgetRule.fiftyThirtyTwenty,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  static BudgetPlanModel fromEntity(BudgetPlanEntity entity) {
    final model = BudgetPlanModel()
      ..monthlyIncome = entity.monthlyIncome
      ..categoryBudgetsJson = jsonEncode(entity.categoryBudgets)
      ..totalBudgeted = entity.totalBudgeted
      ..savingsAmount = entity.savingsAmount
      ..savingsPercentage = entity.savingsPercentage
      ..aiExplanation = entity.aiExplanation
      ..budgetRule = entity.budgetRule.name
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..isActive = entity.isActive;
    if (entity.id > 0) {
      model.id = entity.id;
    }
    return model;
  }
}
