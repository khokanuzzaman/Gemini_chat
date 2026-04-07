import '../entities/budget_plan_entity.dart';
import '../repositories/budget_repository.dart';

class GetActiveBudgetUseCase {
  const GetActiveBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<BudgetPlanEntity?> call() {
    return _repository.getActiveBudget();
  }
}
