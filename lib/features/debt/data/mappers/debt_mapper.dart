import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

extension DebtEntityMapper on DebtEntity {
  DebtModel toModel() {
    final model = DebtModel()
      ..personName = personName
      ..personPhone = personPhone
      ..type = type
      ..originalAmount = originalAmount
      ..remainingAmount = remainingAmount
      ..description = description
      ..category = category
      ..walletId = walletId
      ..status = status
      ..createdAt = createdAt
      ..dueDate = dueDate
      ..settledAt = settledAt
      ..note = note
      ..reminderEnabled = reminderEnabled
      ..isEMI = isEMI
      ..annualInterestRate = annualInterestRate
      ..totalInstallments = totalInstallments
      ..paidInstallments = paidInstallments
      ..emiAmount = emiAmount
      ..nextInstallmentDate = nextInstallmentDate
      ..installmentDayOfMonth = installmentDayOfMonth;
    if (id > 0) {
      model.id = id;
    }
    return model;
  }
}

extension DebtPaymentEntityMapper on DebtPaymentEntity {
  DebtPaymentModel toModel() {
    final model = DebtPaymentModel()
      ..debtId = debtId
      ..amount = amount
      ..walletId = walletId
      ..note = note
      ..paidAt = paidAt
      ..isInstallment = isInstallment
      ..installmentNumber = installmentNumber;
    if (id > 0) {
      model.id = id;
    }
    return model;
  }
}
