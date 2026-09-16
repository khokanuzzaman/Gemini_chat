// Feature: Goals
// Layer: Domain

class GoalSaving {
  const GoalSaving({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.walletId,
  });

  final int id;
  final int goalId;
  final double amount;
  final DateTime date;
  final String? note;

  /// Source wallet this deposit was debited from. Null for legacy savings
  /// (recorded before deposits debited the wallet) — those are never refunded.
  final int? walletId;

  GoalSaving copyWith({
    int? id,
    int? goalId,
    double? amount,
    DateTime? date,
    String? note,
    bool clearNote = false,
    int? walletId,
  }) {
    return GoalSaving(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      walletId: walletId ?? this.walletId,
    );
  }
}
