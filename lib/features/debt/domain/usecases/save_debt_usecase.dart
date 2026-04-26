import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class SaveDebtUseCase {
  const SaveDebtUseCase(this._repository);

  final DebtRepository _repository;

  Future<DebtEntity> call(DebtEntity debt) => _repository.saveDebt(debt);
}
