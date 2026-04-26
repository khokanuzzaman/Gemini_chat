import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtByIdUseCase {
  const GetDebtByIdUseCase(this._repository);

  final DebtRepository _repository;

  Future<DebtEntity?> call(int id) => _repository.getDebtById(id);
}
