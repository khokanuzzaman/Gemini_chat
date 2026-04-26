import '../entities/debt_entity.dart';
import '../entities/debt_payment_entity.dart';

abstract class DebtRepository {
  Future<List<DebtEntity>> getAllDebts();

  Future<DebtEntity?> getDebtById(int id);

  Future<List<DebtEntity>> getDebtsByStatus(DebtStatus status);

  Future<List<DebtEntity>> getDebtsByType(DebtType type);

  Future<List<DebtEntity>> getDebtsByPerson(String personName);

  Future<DebtEntity> saveDebt(DebtEntity debt);

  Future<void> updateDebt(DebtEntity debt);

  Future<void> deleteDebt(int id);

  Future<List<DebtPaymentEntity>> getPaymentsForDebt(int debtId);

  Future<DebtPaymentEntity> addPayment(DebtPaymentEntity payment);

  Future<void> recordInstallmentPaid(int debtId, {int? walletId});

  Future<void> deletePayment(int paymentId);

  Future<List<DebtEntity>> getActiveDebts();

  Future<List<DebtEntity>> getUpcomingInstallments({int daysAhead = 7});

  Future<double> getTotalOwedToMe();

  Future<double> getTotalIOwe();

  Future<void> updateOverdueStatuses();

  Future<void> settleDebt(int id);
}
