class IncomeEntity {
  const IncomeEntity({
    this.id,
    required this.amount,
    required this.source,
    required this.description,
    required this.date,
    this.walletId,
    this.isRecurring = false,
    this.isManual = false,
    this.note,
    required this.createdAt,
  });

  final int? id;
  final double amount;
  final String source;
  final String description;
  final DateTime date;
  final int? walletId;
  final bool isRecurring;
  final bool isManual;
  final String? note;
  final DateTime createdAt;

  IncomeEntity copyWith({
    int? id,
    double? amount,
    String? source,
    String? description,
    DateTime? date,
    int? walletId,
    bool? isRecurring,
    bool? isManual,
    String? note,
    DateTime? createdAt,
  }) {
    return IncomeEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      description: description ?? this.description,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      isRecurring: isRecurring ?? this.isRecurring,
      isManual: isManual ?? this.isManual,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
