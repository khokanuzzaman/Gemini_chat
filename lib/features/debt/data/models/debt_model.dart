import 'package:isar_community/isar.dart';

import '../../domain/entities/debt_entity.dart';

part 'debt_model.g.dart';

@collection
class DebtModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String personName;
  String? personPhone;
  @enumerated
  late DebtType type;
  late double originalAmount;
  late double remainingAmount;
  String? description;
  String? category;
  int? walletId;
  @enumerated
  late DebtStatus status;
  @Index()
  late DateTime createdAt;
  DateTime? dueDate;
  DateTime? settledAt;
  String? note;
  bool reminderEnabled = false;
  bool isEMI = false;
  double annualInterestRate = 0;
  int totalInstallments = 0;
  int paidInstallments = 0;
  double emiAmount = 0;
  @Index()
  DateTime? nextInstallmentDate;
  int? installmentDayOfMonth;

  DebtEntity toEntity() {
    return DebtEntity(
      id: id,
      personName: personName,
      personPhone: personPhone,
      type: type,
      originalAmount: originalAmount,
      remainingAmount: remainingAmount,
      description: description,
      category: category,
      walletId: walletId,
      status: status,
      createdAt: createdAt,
      dueDate: dueDate,
      settledAt: settledAt,
      note: note,
      reminderEnabled: reminderEnabled,
      isEMI: isEMI,
      annualInterestRate: annualInterestRate,
      totalInstallments: totalInstallments,
      paidInstallments: paidInstallments,
      emiAmount: emiAmount,
      nextInstallmentDate: nextInstallmentDate,
      installmentDayOfMonth: installmentDayOfMonth,
    );
  }
}
