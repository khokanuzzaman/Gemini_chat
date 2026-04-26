import '../entities/debt_payment_entity.dart';
import '../repositories/debt_repository.dart';

class AddDebtPaymentUseCase {
  const AddDebtPaymentUseCase(this._repository);

  final DebtRepository _repository;

  Future<DebtPaymentEntity> call({
    required int debtId,
    required double amount,
    int? walletId,
    String? note,
  }) {
    return _repository.addPayment(
      DebtPaymentEntity(
        id: 0,
        debtId: debtId,
        amount: amount,
        walletId: walletId,
        note: note,
        paidAt: DateTime.now(),
      ),
    );
  }
}
