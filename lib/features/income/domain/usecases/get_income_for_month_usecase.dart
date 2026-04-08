import '../entities/income_entity.dart';
import '../repositories/income_repository.dart';

class GetIncomeForMonthUseCase {
  const GetIncomeForMonthUseCase(this._repository);

  final IncomeRepository _repository;

  Future<List<IncomeEntity>> call(DateTime month) {
    return _repository.getIncomeForMonth(month);
  }
}
