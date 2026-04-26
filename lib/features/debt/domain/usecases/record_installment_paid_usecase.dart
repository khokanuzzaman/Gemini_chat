import '../repositories/debt_repository.dart';

class RecordInstallmentPaidUseCase {
  const RecordInstallmentPaidUseCase(this._repository);

  final DebtRepository _repository;

  Future<void> call(int debtId, {int? walletId}) {
    return _repository.recordInstallmentPaid(debtId, walletId: walletId);
  }
}
