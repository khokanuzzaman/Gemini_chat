class ExpenseEntity {
  const ExpenseEntity({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.walletId,
    this.isManual = false,
  });

  final int? id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final int? walletId;
  final bool isManual;

  ExpenseEntity copyWith({
    int? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    int? walletId,
    bool? isManual,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      isManual: isManual ?? this.isManual,
    );
  }
}
