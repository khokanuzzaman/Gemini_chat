import '../repositories/budget_repository.dart';

class SetActiveBudgetUseCase {
  const SetActiveBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<void> call(int id) {
    return _repository.setActiveBudget(id);
  }
}
