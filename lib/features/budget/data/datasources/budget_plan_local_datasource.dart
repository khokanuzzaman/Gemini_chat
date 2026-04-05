import 'package:isar/isar.dart';

import '../../../../core/database/models/budget_plan_model.dart';

class BudgetPlanLocalDataSource {
  const BudgetPlanLocalDataSource(this._isar);

  final Isar _isar;

  Future<BudgetPlanModel?> getLatestPlan() async {
    final plans = await _isar.budgetPlanModels.where().findAll();
    if (plans.isEmpty) {
      return null;
    }
    plans.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return plans.first;
  }

  Future<void> savePlan(BudgetPlanModel model) async {
    await _isar.writeTxn(() async {
      await _isar.budgetPlanModels.put(model);
    });
  }
}
