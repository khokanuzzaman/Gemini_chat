// Feature: Budget
// Layer: Domain

class BudgetPlanEntity {
  const BudgetPlanEntity({
    required this.id,
    required this.monthlyIncome,
    required this.categoryBudgets,
    required this.createdAt,
    required this.updatedAt,
    required this.aiSuggestion,
  });

  final int id;
  final double monthlyIncome;
  final Map<String, double> categoryBudgets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String aiSuggestion;

  double get totalBudgeted {
    return categoryBudgets.values.fold<double>(0, (sum, value) => sum + value);
  }

  double get savingsAmount {
    final remaining = monthlyIncome - totalBudgeted;
    return remaining.isNegative ? 0 : remaining;
  }

  double get savingsPercentage {
    if (monthlyIncome <= 0) {
      return 0;
    }
    return (savingsAmount / monthlyIncome) * 100;
  }

  BudgetPlanEntity copyWith({
    int? id,
    double? monthlyIncome,
    Map<String, double>? categoryBudgets,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? aiSuggestion,
  }) {
    return BudgetPlanEntity(
      id: id ?? this.id,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
    );
  }
}
