import '../repositories/debt_repository.dart';

class DeleteDebtUseCase {
  const DeleteDebtUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> call(int id) => _repository.deleteDebt(id);
}
