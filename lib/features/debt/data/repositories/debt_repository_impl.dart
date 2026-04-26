import '../../../../core/errors/failures.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_datasource.dart';
import '../mappers/debt_mapper.dart';

class DebtRepositoryImpl implements DebtRepository {
  const DebtRepositoryImpl({required DebtLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final DebtLocalDataSource _localDataSource;

  @override
  Future<List<DebtEntity>> getAllDebts() async {
    try {
      final debts = await _localDataSource.getAllDebts();
      return debts.map((debt) => debt.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<DebtEntity?> getDebtById(int id) async {
    try {
      final debt = await _localDataSource.getDebtById(id);
      return debt?.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtEntity>> getDebtsByStatus(DebtStatus status) async {
    try {
      final debts = await _localDataSource.getDebtsByStatus(status);
      return debts.map((debt) => debt.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtEntity>> getDebtsByType(DebtType type) async {
    try {
      final debts = await _localDataSource.getDebtsByType(type);
      return debts.map((debt) => debt.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtEntity>> getDebtsByPerson(String personName) async {
    try {
      final debts = await _localDataSource.getDebtsByPerson(personName);
      return debts.map((debt) => debt.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<DebtEntity> saveDebt(DebtEntity debt) async {
    try {
      final savedDebt = await _localDataSource.saveDebt(debt.toModel());
      return savedDebt.toEntity();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> updateDebt(DebtEntity debt) async {
    try {
      final updated = await _localDataSource.updateDebt(debt.toModel());
      if (!updated) {
        throw const StorageFailure('দেনা/পাওনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<void> deleteDebt(int id) async {
    try {
      final deleted = await _localDataSource.deleteDebt(id);
      if (!deleted) {
        throw const StorageFailure('দেনা/পাওনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtPaymentEntity>> getPaymentsForDebt(int debtId) async {
    try {
      final payments = await _localDataSource.getPaymentsForDebt(debtId);
      return payments
          .map((payment) => payment.toEntity())
          .toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<DebtPaymentEntity> addPayment(DebtPaymentEntity payment) async {
    try {
      final savedPayment = await _localDataSource.addPayment(payment.toModel());
      if (savedPayment == null) {
        throw const StorageFailure('দেনা/পাওনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }
      return savedPayment.toEntity();
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<void> recordInstallmentPaid(int debtId, {int? walletId}) async {
    try {
      await _localDataSource.recordInstallmentPaid(debtId, walletId: walletId);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> deletePayment(int paymentId) async {
    try {
      final deleted = await _localDataSource.deletePayment(paymentId);
      if (!deleted) {
        throw const StorageFailure('পেমেন্টের রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtEntity>> getActiveDebts() async {
    try {
      final debts = await _localDataSource.getActiveDebts();
      return debts.map((debt) => debt.toEntity()).toList(growable: false);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<List<DebtEntity>> getUpcomingInstallments({int daysAhead = 7}) async {
    try {
      return _localDataSource.getUpcomingInstallments(daysAhead: daysAhead);
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<double> getTotalOwedToMe() async {
    try {
      return _localDataSource.getTotalOwedToMe();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<double> getTotalIOwe() async {
    try {
      return _localDataSource.getTotalIOwe();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> updateOverdueStatuses() async {
    try {
      await _localDataSource.updateOverdueStatuses();
    } catch (_) {
      throw const StorageFailure();
    }
  }

  @override
  Future<void> settleDebt(int id) async {
    try {
      final settled = await _localDataSource.settleDebt(id);
      if (!settled) {
        throw const StorageFailure('দেনা/পাওনার রেকর্ডটি খুঁজে পাওয়া যায়নি');
      }
    } catch (error) {
      if (error is Failure) {
        rethrow;
      }
      throw const StorageFailure();
    }
  }
}
