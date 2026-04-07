import '../repositories/budget_repository.dart';

class DeleteBudgetUseCase {
  const DeleteBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteBudget(id);
  }
}
