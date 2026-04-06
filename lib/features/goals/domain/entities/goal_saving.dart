// Feature: Goals
// Layer: Domain

class GoalSaving {
  const GoalSaving({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  final int id;
  final int goalId;
  final double amount;
  final DateTime date;
  final String? note;

  GoalSaving copyWith({
    int? id,
    int? goalId,
    double? amount,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return GoalSaving(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
    );
  }
}
