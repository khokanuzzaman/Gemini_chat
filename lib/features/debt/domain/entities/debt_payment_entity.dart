class DebtPaymentEntity {
  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.amount,
    this.walletId,
    this.note,
    required this.paidAt,
    this.isInstallment = false,
    this.installmentNumber,
  });

  final int id;
  final int debtId;
  final double amount;
  final int? walletId;
  final String? note;
  final DateTime paidAt;
  final bool isInstallment;
  final int? installmentNumber;

  DebtPaymentEntity copyWith({
    int? id,
    int? debtId,
    double? amount,
    Object? walletId = _debtPaymentEntityUnset,
    Object? note = _debtPaymentEntityUnset,
    DateTime? paidAt,
    bool? isInstallment,
    Object? installmentNumber = _debtPaymentEntityUnset,
  }) {
    return DebtPaymentEntity(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      walletId: walletId == _debtPaymentEntityUnset
          ? this.walletId
          : walletId as int?,
      note: note == _debtPaymentEntityUnset ? this.note : note as String?,
      paidAt: paidAt ?? this.paidAt,
      isInstallment: isInstallment ?? this.isInstallment,
      installmentNumber: installmentNumber == _debtPaymentEntityUnset
          ? this.installmentNumber
          : installmentNumber as int?,
    );
  }
}

const _debtPaymentEntityUnset = Object();
