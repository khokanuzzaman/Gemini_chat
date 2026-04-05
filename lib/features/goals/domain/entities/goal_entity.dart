// Feature: Goals
// Layer: Domain

enum GoalStatus { active, achieved, cancelled }

class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.createdAt,
    required this.status,
  });

  final int id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final GoalStatus status;

  double get progressPercentage {
    if (targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - savedAmount).clamp(0, double.infinity);
  }

  int get daysRemaining {
    return targetDate.difference(DateTime.now()).inDays;
  }

  double get requiredMonthlySaving {
    if (daysRemaining <= 0) {
      return remainingAmount;
    }
    final monthsLeft = daysRemaining / 30;
    return monthsLeft <= 0 ? remainingAmount : remainingAmount / monthsLeft;
  }

  GoalEntity copyWith({
    int? id,
    String? title,
    String? emoji,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    DateTime? createdAt,
    GoalStatus? status,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
