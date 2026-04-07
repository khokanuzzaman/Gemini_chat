import '../entities/budget_plan_entity.dart';
import '../repositories/budget_repository.dart';

class SaveBudgetUseCase {
  const SaveBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<void> call(BudgetPlanEntity plan) {
    return _repository.saveBudget(plan);
  }
}
