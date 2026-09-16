import 'expense_source.dart';

class ExpenseEntity {
  const ExpenseEntity({
    this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.walletId,
    this.isManual = false,
    this.sourceType = ExpenseSource.expense,
    this.sourceId,
  });

  final int? id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final int? walletId;
  final bool isManual;

  /// Origin/kind of this record (see [ExpenseSource]). Defaults to an ordinary
  /// consumption expense so existing call sites are unchanged.
  final ExpenseSource sourceType;

  /// Back-link to the originating debt-payment / goal-saving row, when applicable.
  final int? sourceId;

  ExpenseEntity copyWith({
    int? id,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    int? walletId,
    bool? isManual,
    ExpenseSource? sourceType,
    int? sourceId,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      isManual: isManual ?? this.isManual,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}
