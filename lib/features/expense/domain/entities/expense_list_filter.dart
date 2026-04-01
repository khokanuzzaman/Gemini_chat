class ExpenseListFilter {
  const ExpenseListFilter({this.category, this.startDate, this.endDate});

  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasDateRange => startDate != null && endDate != null;

  ExpenseListFilter copyWith({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool clearCategory = false,
    bool clearDateRange = false,
  }) {
    return ExpenseListFilter(
      category: clearCategory ? null : (category ?? this.category),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}
