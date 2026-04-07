import '../repositories/budget_repository.dart';

class DeactivateAllUseCase {
  const DeactivateAllUseCase(this._repository);

  final BudgetRepository _repository;

  Future<void> call() {
    return _repository.deactivateAll();
  }
}
