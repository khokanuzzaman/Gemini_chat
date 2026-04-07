import '../entities/budget_plan_entity.dart';
import '../repositories/budget_repository.dart';

class GetAllBudgetsUseCase {
  const GetAllBudgetsUseCase(this._repository);

  final BudgetRepository _repository;

  Future<List<BudgetPlanEntity>> call() {
    return _repository.getAllBudgets();
  }
}
