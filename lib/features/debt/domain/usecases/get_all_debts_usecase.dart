import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetAllDebtsUseCase {
  const GetAllDebtsUseCase(this._repository);

  final DebtRepository _repository;

  Future<List<DebtEntity>> call() => _repository.getAllDebts();
}
