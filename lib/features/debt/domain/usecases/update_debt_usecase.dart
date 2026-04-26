import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class UpdateDebtUseCase {
  const UpdateDebtUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> call(DebtEntity debt) => _repository.updateDebt(debt);
}
