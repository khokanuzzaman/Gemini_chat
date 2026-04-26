import '../repositories/debt_repository.dart';

class SettleDebtUseCase {
  const SettleDebtUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> call(int id) => _repository.settleDebt(id);
}
