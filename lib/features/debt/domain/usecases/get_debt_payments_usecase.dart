import '../entities/debt_payment_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebtPaymentsUseCase {
  const GetDebtPaymentsUseCase(this._repository);

  final DebtRepository _repository;

  Future<List<DebtPaymentEntity>> call(int debtId) {
    return _repository.getPaymentsForDebt(debtId);
  }
}
