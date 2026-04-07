import '../../domain/entities/budget_plan_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_plan_local_datasource.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl({
    required BudgetPlanLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final BudgetPlanLocalDataSource _localDataSource;

  @override
  Future<BudgetPlanEntity?> getActiveBudget() {
    return _localDataSource.getActiveBudget();
  }

  @override
  Future<List<BudgetPlanEntity>> getAllBudgets() {
    return _localDataSource.getAllBudgets();
  }

  @override
  Future<void> saveBudget(BudgetPlanEntity plan) {
    return _localDataSource.saveBudget(plan);
  }

  @override
  Future<void> updateBudget(BudgetPlanEntity plan) {
    return _localDataSource.updateBudget(plan);
  }

  @override
  Future<void> deleteBudget(int id) {
    return _localDataSource.deleteBudget(id);
  }

  @override
  Future<void> setActiveBudget(int id) {
    return _localDataSource.setActiveBudget(id);
  }

  @override
  Future<void> deactivateAll() {
    return _localDataSource.deactivateAll();
  }
}
