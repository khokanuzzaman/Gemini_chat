import 'package:isar/isar.dart';

import '../../../../core/database/models/budget_plan_model.dart';
import '../../domain/entities/budget_plan_entity.dart';

class BudgetPlanLocalDataSource {
  const BudgetPlanLocalDataSource(this._isar);

  final Isar _isar;

  Future<BudgetPlanModel?> getLatestPlan() async {
    final plans = await _loadSortedModels();
    if (plans.isEmpty) {
      return null;
    }
    return plans.first;
  }

  Future<BudgetPlanEntity?> getActiveBudget() async {
    final plans = await _loadSortedModels();
    for (final plan in plans) {
      if (plan.isActive) {
        return plan.toEntity();
      }
    }
    return null;
  }

  Future<List<BudgetPlanEntity>> getAllBudgets() async {
    final plans = await _loadSortedModels();
    return plans.map((plan) => plan.toEntity()).toList(growable: false);
  }

  Future<void> saveBudget(BudgetPlanEntity entity) async {
    await _isar.writeTxn(() async {
      await _isar.budgetPlanModels.put(BudgetPlanModel.fromEntity(entity));
    });
  }

  Future<void> updateBudget(BudgetPlanEntity entity) async {
    await saveBudget(entity);
  }

  Future<void> deleteBudget(int id) async {
    await _isar.writeTxn(() async {
      await _isar.budgetPlanModels.delete(id);
    });
  }

  Future<void> setActiveBudget(int id) async {
    await _isar.writeTxn(() async {
      final now = DateTime.now();
      final plans = await _isar.budgetPlanModels.where().findAll();
      for (final plan in plans) {
        final shouldBeActive = plan.id == id;
        if (plan.isActive == shouldBeActive) {
          continue;
        }
        plan.isActive = shouldBeActive;
        plan.updatedAt = now;
        await _isar.budgetPlanModels.put(plan);
      }
    });
  }

  Future<void> deactivateAll() async {
    await _isar.writeTxn(() async {
      final plans = await _isar.budgetPlanModels.where().findAll();
      final now = DateTime.now();
      for (final plan in plans) {
        if (!plan.isActive) {
          continue;
        }
        plan.isActive = false;
        plan.updatedAt = now;
        await _isar.budgetPlanModels.put(plan);
      }
    });
  }

  Future<List<BudgetPlanModel>> _loadSortedModels() async {
    final plans = await _isar.budgetPlanModels.where().findAll();
    plans.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return plans;
  }
}
