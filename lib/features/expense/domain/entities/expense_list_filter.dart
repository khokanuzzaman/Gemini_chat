class ExpenseListFilter {
  const ExpenseListFilter({
    this.category,
    this.walletId,
    this.startDate,
    this.endDate,
  });

  final String? category;
  final int? walletId;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasDateRange => startDate != null && endDate != null;

  ExpenseListFilter copyWith({
    String? category,
    int? walletId,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearWallet = false,
    bool clearDateRange = false,
  }) {
    return ExpenseListFilter(
      category: clearCategory ? null : (category ?? this.category),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}
