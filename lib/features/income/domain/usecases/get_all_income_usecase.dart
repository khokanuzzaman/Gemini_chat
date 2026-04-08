import '../entities/income_entity.dart';
import '../repositories/income_repository.dart';

class GetAllIncomeUseCase {
  const GetAllIncomeUseCase(this._repository);

  final IncomeRepository _repository;

  Future<List<IncomeEntity>> call() {
    return _repository.getAllIncome();
  }
}
