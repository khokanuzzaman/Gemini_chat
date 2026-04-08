import '../repositories/income_repository.dart';

class GetIncomeTotalsUseCase {
  const GetIncomeTotalsUseCase(this._repository);

  final IncomeRepository _repository;

  Future<double> forRange(DateTime start, DateTime end) {
    return _repository.getTotalIncomeForRange(start, end);
  }

  Future<Map<String, double>> bySourceForRange(
    DateTime start,
    DateTime end,
  ) {
    return _repository.getIncomeBySourceTotals(start, end);
  }
}
