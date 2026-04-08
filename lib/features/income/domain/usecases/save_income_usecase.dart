import '../entities/income_entity.dart';
import '../repositories/income_repository.dart';

class SaveIncomeUseCase {
  const SaveIncomeUseCase(this._repository);

  final IncomeRepository _repository;

  Future<IncomeEntity> call(IncomeEntity income) {
    return _repository.saveIncome(income);
  }

  Future<List<IncomeEntity>> saveMany(List<IncomeEntity> incomes) {
    return _repository.saveIncomeBatch(incomes);
  }
}
