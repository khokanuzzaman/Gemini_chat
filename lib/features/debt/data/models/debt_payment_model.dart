import 'package:isar_community/isar.dart';

import '../../domain/entities/debt_payment_entity.dart';

part 'debt_payment_model.g.dart';

@collection
class DebtPaymentModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int debtId;
  late double amount;
  int? walletId;
  String? note;
  @Index()
  late DateTime paidAt;
  bool isInstallment = false;
  int? installmentNumber;

  DebtPaymentEntity toEntity() {
    return DebtPaymentEntity(
      id: id,
      debtId: debtId,
      amount: amount,
      walletId: walletId,
      note: note,
      paidAt: paidAt,
      isInstallment: isInstallment,
      installmentNumber: installmentNumber,
    );
  }
}
