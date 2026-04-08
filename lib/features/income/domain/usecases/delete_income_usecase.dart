import '../repositories/income_repository.dart';

class DeleteIncomeUseCase {
  const DeleteIncomeUseCase(this._repository);

  final IncomeRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteIncome(id);
  }
}
