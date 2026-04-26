import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../domain/entities/debt_entity.dart';
import '../../domain/utils/emi_calculator.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

class DebtLocalDataSource {
  const DebtLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<DebtModel>> getAllDebts() {
    return _loadAllSortedDebts();
  }

  Future<DebtModel?> getDebtById(int id) {
    return _isar.debtModels.get(id);
  }

  Future<List<DebtModel>> getDebtsByStatus(DebtStatus status) async {
    final debts = await _loadAllSortedDebts();
    return debts.where((debt) => debt.status == status).toList(growable: false);
  }

  Future<List<DebtModel>> getDebtsByType(DebtType type) async {
    final debts = await _loadAllSortedDebts();
    return debts.where((debt) => debt.type == type).toList(growable: false);
  }

  Future<List<DebtModel>> getDebtsByPerson(String personName) async {
    final query = personName.trim();
    final debts = await _loadAllSortedDebts();
    if (query.isEmpty) {
      return debts;
    }

    final normalizedQuery = query.toLowerCase();
    return debts
        .where(
          (debt) => debt.personName.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
  }

  Future<DebtModel> saveDebt(DebtModel debt) async {
    final normalizedDebt = _normalizeDebtForSave(debt);
    await _isar.writeTxn(() async {
      await _isar.debtModels.put(normalizedDebt);
    });
    return normalizedDebt;
  }

  Future<bool> updateDebt(DebtModel debt) async {
    final existingDebt = await _isar.debtModels.get(debt.id);
    if (existingDebt == null) {
      return false;
    }

    final normalizedDebt = _normalizeDebtForSave(debt);
    await _isar.writeTxn(() async {
      await _isar.debtModels.put(normalizedDebt);
    });
    return true;
  }

  Future<bool> deleteDebt(int id) async {
    bool deleted = false;
    await _isar.writeTxn(() async {
      deleted = await _isar.debtModels.delete(id);
      if (deleted) {
        await _isar.debtPaymentModels.filter().debtIdEqualTo(id).deleteAll();
      }
    });
    return deleted;
  }

  Future<List<DebtPaymentModel>> getPaymentsForDebt(int debtId) async {
    final payments = await _isar.debtPaymentModels
        .filter()
        .debtIdEqualTo(debtId)
        .findAll();
    payments.sort((first, second) => second.paidAt.compareTo(first.paidAt));
    return payments;
  }

  Future<DebtPaymentModel?> addPayment(DebtPaymentModel payment) async {
    DebtPaymentModel? savedPayment;

    await _isar.writeTxn(() async {
      final debt = await _isar.debtModels.get(payment.debtId);
      if (debt == null) {
        return;
      }

      payment.amount = math.max(0.0, payment.amount).toDouble();
      _applyPaymentToDebt(debt, payment);

      await _isar.debtPaymentModels.put(payment);
      await _isar.debtModels.put(debt);
      savedPayment = payment;
    });

    return savedPayment;
  }

  Future<void> recordInstallmentPaid(int debtId, {int? walletId}) async {
    await _isar.writeTxn(() async {
      final debt = await _isar.debtModels.get(debtId);
      if (debt == null || !debt.isEMI) {
        return;
      }

      if (debt.status == DebtStatus.settled ||
          debt.status == DebtStatus.cancelled) {
        return;
      }

      final installmentNumber = math.min(
        debt.totalInstallments,
        debt.paidInstallments + 1,
      );
      final payment = DebtPaymentModel()
        ..debtId = debtId
        ..amount = math
            .min(
              math.max(0.0, debt.emiAmount),
              math.max(0.0, debt.remainingAmount),
            )
            .toDouble()
        ..walletId = walletId
        ..paidAt = DateTime.now()
        ..isInstallment = true
        ..installmentNumber = installmentNumber;

      _applyPaymentToDebt(debt, payment);
      await _isar.debtPaymentModels.put(payment);
      await _isar.debtModels.put(debt);
    });
  }

  Future<bool> deletePayment(int paymentId) async {
    bool deleted = false;

    await _isar.writeTxn(() async {
      final payment = await _isar.debtPaymentModels.get(paymentId);
      if (payment == null) {
        deleted = false;
        return;
      }

      final debt = await _isar.debtModels.get(payment.debtId);
      if (debt != null) {
        debt.remainingAmount = math
            .min(_maxPayableAmount(debt), debt.remainingAmount + payment.amount)
            .toDouble();

        if (debt.isEMI && payment.isInstallment) {
          debt.paidInstallments = math.max(0, debt.paidInstallments - 1);
          final day = debt.installmentDayOfMonth;
          final nextDate =
              debt.nextInstallmentDate ??
              (day == null
                  ? null
                  : _nextInstallmentFromReference(DateTime.now(), day));
          if (day != null && nextDate != null) {
            debt.nextInstallmentDate = _subtractMonthKeepingDay(nextDate, day);
          }
        }

        if (debt.remainingAmount <= 0) {
          debt.remainingAmount = 0;
          debt.status = DebtStatus.settled;
          debt.settledAt ??= DateTime.now();
          debt.nextInstallmentDate = null;
        } else if (debt.status != DebtStatus.cancelled) {
          debt.status = _resolveOpenStatus(debt);
          debt.settledAt = null;
          if (debt.isEMI &&
              debt.nextInstallmentDate == null &&
              debt.installmentDayOfMonth != null &&
              debt.paidInstallments < debt.totalInstallments) {
            debt.nextInstallmentDate = _nextInstallmentFromReference(
              DateTime.now(),
              debt.installmentDayOfMonth!,
            );
          }
        }

        await _isar.debtModels.put(debt);
      }

      deleted = await _isar.debtPaymentModels.delete(paymentId);
    });

    return deleted;
  }

  Future<List<DebtModel>> getActiveDebts() async {
    final debts = await _loadAllSortedDebts();
    return debts
        .where(
          (debt) =>
              debt.status == DebtStatus.active ||
              debt.status == DebtStatus.overdue,
        )
        .toList(growable: false);
  }

  Future<List<DebtEntity>> getUpcomingInstallments({int daysAhead = 7}) async {
    final now = _stripTime(DateTime.now());
    final end = now.add(Duration(days: daysAhead));
    final debts = await _loadAllSortedDebts();
    return debts
        .where(
          (debt) =>
              debt.isEMI &&
              debt.status == DebtStatus.active &&
              debt.nextInstallmentDate != null &&
              !_stripTime(debt.nextInstallmentDate!).isBefore(now) &&
              !_stripTime(debt.nextInstallmentDate!).isAfter(end),
        )
        .map((debt) => debt.toEntity())
        .toList(growable: false);
  }

  Future<double> getTotalOwedToMe() async {
    final debts = await _loadAllSortedDebts();
    return debts
        .where(
          (debt) =>
              debt.type == DebtType.theyOwe && debt.status == DebtStatus.active,
        )
        .fold<double>(
          0,
          (sum, debt) => sum + math.max(0.0, debt.remainingAmount),
        );
  }

  Future<double> getTotalIOwe() async {
    final debts = await _loadAllSortedDebts();
    return debts
        .where(
          (debt) =>
              debt.type == DebtType.iOwe && debt.status == DebtStatus.active,
        )
        .fold<double>(
          0,
          (sum, debt) => sum + math.max(0.0, debt.remainingAmount),
        );
  }

  Future<void> updateOverdueStatuses() async {
    final today = _stripTime(DateTime.now());
    final debts = await _loadAllSortedDebts();
    final openDebts = debts
        .where(
          (debt) =>
              debt.status == DebtStatus.active ||
              debt.status == DebtStatus.overdue,
        )
        .toList(growable: false);

    final dirtyDebts = <DebtModel>[];
    for (final debt in openDebts) {
      final dueDate = _effectiveDueDate(debt);
      final shouldBeOverdue =
          dueDate != null && _stripTime(dueDate).isBefore(today);
      final nextStatus = shouldBeOverdue
          ? DebtStatus.overdue
          : DebtStatus.active;
      if (debt.status != nextStatus) {
        debt.status = nextStatus;
        dirtyDebts.add(debt);
      }
    }

    if (dirtyDebts.isEmpty) {
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.debtModels.putAll(dirtyDebts);
    });
  }

  Future<bool> settleDebt(int id) async {
    final debt = await _isar.debtModels.get(id);
    if (debt == null) {
      return false;
    }

    await _isar.writeTxn(() async {
      debt.remainingAmount = 0;
      debt.status = DebtStatus.settled;
      debt.settledAt = DateTime.now();
      if (debt.isEMI) {
        debt.paidInstallments = debt.totalInstallments;
        debt.nextInstallmentDate = null;
      }
      await _isar.debtModels.put(debt);
    });

    return true;
  }

  Future<List<DebtModel>> _loadAllSortedDebts() async {
    final debts = await _isar.debtModels.where().findAll();
    debts.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return debts;
  }

  DebtModel _normalizeDebtForSave(DebtModel debt) {
    debt.originalAmount = math.max(0.0, debt.originalAmount).toDouble();
    if (debt.isEMI) {
      debt.annualInterestRate = math
          .max(0.0, debt.annualInterestRate)
          .toDouble();
      debt.totalInstallments = math.max(0, debt.totalInstallments);
      debt.paidInstallments = debt.paidInstallments.clamp(
        0,
        math.max(0, debt.totalInstallments),
      );
      if (debt.emiAmount <= 0 && debt.totalInstallments > 0) {
        debt.emiAmount = EmiCalculator.calculateEMI(
          principal: debt.originalAmount,
          annualRate: debt.annualInterestRate,
          months: debt.totalInstallments,
        );
      } else {
        debt.emiAmount = math.max(0.0, debt.emiAmount).toDouble();
      }
      if (debt.installmentDayOfMonth != null) {
        debt.installmentDayOfMonth = debt.installmentDayOfMonth!.clamp(1, 31);
      }
    } else {
      debt.annualInterestRate = 0;
      debt.totalInstallments = 0;
      debt.paidInstallments = 0;
      debt.emiAmount = 0;
      debt.nextInstallmentDate = null;
      debt.installmentDayOfMonth = null;
    }

    debt.remainingAmount = debt.remainingAmount
        .clamp(0.0, _maxPayableAmount(debt))
        .toDouble();

    if (debt.remainingAmount <= 0) {
      debt.remainingAmount = 0;
      debt.status = DebtStatus.settled;
      debt.settledAt ??= DateTime.now();
      debt.nextInstallmentDate = null;
    } else if (debt.status == DebtStatus.settled) {
      debt.status = _resolveOpenStatus(debt);
      debt.settledAt = null;
    }

    if (debt.isEMI &&
        debt.nextInstallmentDate == null &&
        debt.installmentDayOfMonth != null &&
        debt.paidInstallments < debt.totalInstallments) {
      debt.nextInstallmentDate = _nextInstallmentFromReference(
        DateTime.now(),
        debt.installmentDayOfMonth!,
      );
    }

    return debt;
  }

  DebtStatus _resolveOpenStatus(DebtModel debt) {
    final dueDate = _effectiveDueDate(debt);
    if (dueDate != null &&
        _stripTime(dueDate).isBefore(_stripTime(DateTime.now()))) {
      return DebtStatus.overdue;
    }
    return DebtStatus.active;
  }

  void _applyPaymentToDebt(DebtModel debt, DebtPaymentModel payment) {
    debt.remainingAmount = (debt.remainingAmount - payment.amount)
        .clamp(0.0, double.infinity)
        .toDouble();

    if (debt.isEMI && payment.isInstallment) {
      debt.paidInstallments = math.min(
        debt.totalInstallments,
        debt.paidInstallments + 1,
      );
      if (debt.paidInstallments >= debt.totalInstallments) {
        debt.nextInstallmentDate = null;
      } else {
        final day = debt.installmentDayOfMonth;
        final currentDue =
            debt.nextInstallmentDate ??
            (day == null
                ? null
                : _nextInstallmentFromReference(DateTime.now(), day));
        if (day != null && currentDue != null) {
          debt.nextInstallmentDate = _addMonthKeepingDay(currentDue, day);
        }
      }
    }

    if (debt.remainingAmount <= 0 ||
        (debt.isEMI && debt.paidInstallments >= debt.totalInstallments)) {
      debt.remainingAmount = 0;
      debt.status = DebtStatus.settled;
      debt.settledAt = DateTime.now();
      debt.nextInstallmentDate = null;
      if (debt.isEMI) {
        debt.paidInstallments = debt.totalInstallments;
      }
      return;
    }

    debt.status = _resolveOpenStatus(debt);
    debt.settledAt = null;
  }

  double _maxPayableAmount(DebtModel debt) {
    if (!debt.isEMI || debt.totalInstallments <= 0 || debt.emiAmount <= 0) {
      return debt.originalAmount;
    }
    return debt.emiAmount * debt.totalInstallments;
  }

  DateTime? _effectiveDueDate(DebtModel debt) {
    return debt.isEMI ? debt.nextInstallmentDate : debt.dueDate;
  }

  DateTime _nextInstallmentFromReference(DateTime reference, int dayOfMonth) {
    final today = _stripTime(reference);
    var candidate = _safeInstallmentDate(today.year, today.month, dayOfMonth);
    if (candidate.isBefore(today)) {
      candidate = _safeInstallmentDate(today.year, today.month + 1, dayOfMonth);
    }
    return candidate;
  }

  DateTime _addMonthKeepingDay(DateTime date, int? dayOfMonth) {
    final day = dayOfMonth ?? date.day;
    return _safeInstallmentDate(date.year, date.month + 1, day);
  }

  DateTime _subtractMonthKeepingDay(DateTime date, int? dayOfMonth) {
    final day = dayOfMonth ?? date.day;
    return _safeInstallmentDate(date.year, date.month - 1, day);
  }

  DateTime _safeInstallmentDate(int year, int month, int dayOfMonth) {
    final normalizedYear = year + ((month - 1) ~/ 12);
    final normalizedMonth = ((month - 1) % 12 + 12) % 12 + 1;
    final maxDay = DateTime(normalizedYear, normalizedMonth + 1, 0).day;
    final safeDay = dayOfMonth.clamp(1, maxDay);
    return DateTime(normalizedYear, normalizedMonth, safeDay);
  }

  DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
