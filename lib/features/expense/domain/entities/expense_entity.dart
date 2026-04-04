class ExpenseEntity {
  const ExpenseEntity({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.isManual = false,
  });

  final int? id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final bool isManual;

  ExpenseEntity copyWith({
    int? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    bool? isManual,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isManual: isManual ?? this.isManual,
    );
  }
}
