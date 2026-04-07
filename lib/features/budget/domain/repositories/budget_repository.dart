import '../entities/budget_plan_entity.dart';

abstract class BudgetRepository {
  Future<BudgetPlanEntity?> getActiveBudget();

  Future<List<BudgetPlanEntity>> getAllBudgets();

  Future<void> saveBudget(BudgetPlanEntity plan);

  Future<void> updateBudget(BudgetPlanEntity plan);

  Future<void> deleteBudget(int id);

  Future<void> setActiveBudget(int id);

  Future<void> deactivateAll();
}
