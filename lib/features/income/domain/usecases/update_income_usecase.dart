import '../entities/income_entity.dart';
import '../repositories/income_repository.dart';

class UpdateIncomeUseCase {
  const UpdateIncomeUseCase(this._repository);

  final IncomeRepository _repository;

  Future<void> call(IncomeEntity income) {
    return _repository.updateIncome(income);
  }
}
