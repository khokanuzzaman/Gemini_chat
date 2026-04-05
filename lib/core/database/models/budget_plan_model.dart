import 'package:isar/isar.dart';

import '../../../features/budget/domain/entities/budget_plan_entity.dart';

part 'budget_plan_model.g.dart';

@collection
class BudgetPlanModel {
  Id id = Isar.autoIncrement;

  late double monthlyIncome;
  late List<String> categoryNames;
  late List<double> categoryAmounts;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String aiSuggestion;

  BudgetPlanEntity toEntity() {
    final budgets = <String, double>{};
    final length = categoryNames.length < categoryAmounts.length
        ? categoryNames.length
        : categoryAmounts.length;
    for (var index = 0; index < length; index++) {
      budgets[categoryNames[index]] = categoryAmounts[index];
    }

    return BudgetPlanEntity(
      id: id,
      monthlyIncome: monthlyIncome,
      categoryBudgets: budgets,
      createdAt: createdAt,
      updatedAt: updatedAt,
      aiSuggestion: aiSuggestion,
    );
  }

  static BudgetPlanModel fromEntity(BudgetPlanEntity entity) {
    final entries = entity.categoryBudgets.entries.toList(growable: false);
    return BudgetPlanModel()
      ..id = entity.id > 0 ? entity.id : Isar.autoIncrement
      ..monthlyIncome = entity.monthlyIncome
      ..categoryNames = entries.map((entry) => entry.key).toList()
      ..categoryAmounts = entries.map((entry) => entry.value).toList()
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt
      ..aiSuggestion = entity.aiSuggestion;
  }
}
