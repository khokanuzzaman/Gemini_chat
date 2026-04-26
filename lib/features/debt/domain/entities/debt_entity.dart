import 'dart:math' as math;

enum DebtType { iOwe, theyOwe }

enum DebtStatus { active, settled, overdue, cancelled }

class DebtEntity {
  const DebtEntity({
    required this.id,
    required this.personName,
    this.personPhone,
    required this.type,
    required this.originalAmount,
    required this.remainingAmount,
    this.description,
    this.category,
    this.walletId,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.settledAt,
    this.note,
    this.reminderEnabled = false,
    this.isEMI = false,
    this.annualInterestRate = 0,
    this.totalInstallments = 0,
    this.paidInstallments = 0,
    this.emiAmount = 0,
    this.nextInstallmentDate,
    this.installmentDayOfMonth,
  });

  final int id;
  final String personName;
  final String? personPhone;
  final DebtType type;
  final double originalAmount;
  final double remainingAmount;
  final String? description;
  final String? category;
  final int? walletId;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? settledAt;
  final String? note;
  final bool reminderEnabled;
  final bool isEMI;
  final double annualInterestRate;
  final int totalInstallments;
  final int paidInstallments;
  final double emiAmount;
  final DateTime? nextInstallmentDate;
  final int? installmentDayOfMonth;

  double get totalPayable {
    if (!isEMI || totalInstallments <= 0 || emiAmount <= 0) {
      return originalAmount;
    }
    return emiAmount * totalInstallments;
  }

  double get totalInterest => math.max(0, totalPayable - originalAmount);

  double get paidAmount => math.max(0, totalPayable - remainingAmount);

  double get progressPercentage {
    if (isEMI) {
      if (totalInstallments <= 0) {
        return 0;
      }
      return (paidInstallments / totalInstallments) * 100;
    }
    return originalAmount <= 0 ? 0 : (paidAmount / originalAmount) * 100;
  }

  DateTime? get effectiveDueDate => isEMI ? nextInstallmentDate : dueDate;

  bool get isOverdue =>
      status == DebtStatus.active &&
      effectiveDueDate != null &&
      _stripTime(effectiveDueDate!).isBefore(_stripTime(DateTime.now()));

  String get displayType => type == DebtType.iOwe ? 'দেনা' : 'পাওনা';

  bool get isFullyPaid =>
      remainingAmount <= 0 ||
      (isEMI && totalInstallments > 0 && paidInstallments >= totalInstallments);

  bool get isInterestFreeEMI => isEMI && annualInterestRate <= 0;

  int get remainingInstallments =>
      math.max(0, totalInstallments - paidInstallments);

  double get nextInstallmentAmount {
    if (!isEMI) {
      return remainingAmount;
    }
    final scheduledAmount = emiAmount > 0 ? emiAmount : remainingAmount;
    return math.min(remainingAmount, scheduledAmount).toDouble();
  }

  DebtEntity copyWith({
    int? id,
    String? personName,
    Object? personPhone = _debtEntityUnset,
    DebtType? type,
    double? originalAmount,
    double? remainingAmount,
    Object? description = _debtEntityUnset,
    Object? category = _debtEntityUnset,
    Object? walletId = _debtEntityUnset,
    DebtStatus? status,
    DateTime? createdAt,
    Object? dueDate = _debtEntityUnset,
    Object? settledAt = _debtEntityUnset,
    Object? note = _debtEntityUnset,
    bool? reminderEnabled,
    bool? isEMI,
    double? annualInterestRate,
    int? totalInstallments,
    int? paidInstallments,
    double? emiAmount,
    Object? nextInstallmentDate = _debtEntityUnset,
    Object? installmentDayOfMonth = _debtEntityUnset,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      personPhone: personPhone == _debtEntityUnset
          ? this.personPhone
          : personPhone as String?,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      description: description == _debtEntityUnset
          ? this.description
          : description as String?,
      category: category == _debtEntityUnset
          ? this.category
          : category as String?,
      walletId: walletId == _debtEntityUnset ? this.walletId : walletId as int?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate == _debtEntityUnset
          ? this.dueDate
          : dueDate as DateTime?,
      settledAt: settledAt == _debtEntityUnset
          ? this.settledAt
          : settledAt as DateTime?,
      note: note == _debtEntityUnset ? this.note : note as String?,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isEMI: isEMI ?? this.isEMI,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      emiAmount: emiAmount ?? this.emiAmount,
      nextInstallmentDate: nextInstallmentDate == _debtEntityUnset
          ? this.nextInstallmentDate
          : nextInstallmentDate as DateTime?,
      installmentDayOfMonth: installmentDayOfMonth == _debtEntityUnset
          ? this.installmentDayOfMonth
          : installmentDayOfMonth as int?,
    );
  }
}

const _debtEntityUnset = Object();

DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);
