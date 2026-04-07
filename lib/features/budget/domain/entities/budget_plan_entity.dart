// Feature: Budget
// Layer: Domain

import 'package:flutter/material.dart';

import '../../../expense/domain/entities/expense_entity.dart';

class BudgetPlanEntity {
  const BudgetPlanEntity({
    required this.id,
    required this.monthlyIncome,
    required this.categoryBudgets,
    required this.totalBudgeted,
    required this.savingsAmount,
    required this.savingsPercentage,
    required this.aiExplanation,
    required this.budgetRule,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  final int id;
  final double monthlyIncome;
  final Map<String, double> categoryBudgets;
  final double totalBudgeted;
  final double savingsAmount;
  final double savingsPercentage;
  final String aiExplanation;
  final BudgetRule budgetRule;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  double getBudgetForCategory(String category) {
    return categoryBudgets[category] ?? 0;
  }

  double getSpentForCategory(
    String category,
    List<ExpenseEntity> thisMonthExpenses,
  ) {
    return thisMonthExpenses
        .where((expense) => expense.category == category)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double getUsagePercentage(String category, List<ExpenseEntity> expenses) {
    final budget = getBudgetForCategory(category);
    if (budget == 0) {
      return 0;
    }
    final spent = getSpentForCategory(category, expenses);
    return (spent / budget * 100).clamp(0.0, 150.0);
  }

  BudgetStatus getCategoryStatus(
    String category,
    List<ExpenseEntity> expenses,
  ) {
    final pct = getUsagePercentage(category, expenses);
    if (pct >= 100) {
      return BudgetStatus.exceeded;
    }
    if (pct >= 80) {
      return BudgetStatus.warning;
    }
    return BudgetStatus.good;
  }

  BudgetPlanEntity copyWith({
    int? id,
    double? monthlyIncome,
    Map<String, double>? categoryBudgets,
    double? totalBudgeted,
    double? savingsAmount,
    double? savingsPercentage,
    String? aiExplanation,
    BudgetRule? budgetRule,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BudgetPlanEntity(
      id: id ?? this.id,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      totalBudgeted: totalBudgeted ?? this.totalBudgeted,
      savingsAmount: savingsAmount ?? this.savingsAmount,
      savingsPercentage: savingsPercentage ?? this.savingsPercentage,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      budgetRule: budgetRule ?? this.budgetRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum BudgetRule { fiftyThirtyTwenty, seventyTwentyTen, custom }

extension BudgetRuleExt on BudgetRule {
  String get label {
    return switch (this) {
      BudgetRule.fiftyThirtyTwenty => '50/30/20 নিয়ম',
      BudgetRule.seventyTwentyTen => '70/20/10 নিয়ম',
      BudgetRule.custom => 'Custom পরিকল্পনা',
    };
  }

  String get description {
    return switch (this) {
      BudgetRule.fiftyThirtyTwenty =>
        '50% প্রয়োজনীয়, 30% ইচ্ছামতো, 20% সঞ্চয়',
      BudgetRule.seventyTwentyTen => '70% খরচ, 20% সঞ্চয়, 10% বিনিয়োগ',
      BudgetRule.custom => 'আপনার খরচের ধরন অনুযায়ী তৈরি',
    };
  }
}

enum BudgetStatus { good, warning, exceeded }

extension BudgetStatusExt on BudgetStatus {
  Color get color {
    return switch (this) {
      BudgetStatus.good => Colors.green.shade600,
      BudgetStatus.warning => Colors.orange.shade600,
      BudgetStatus.exceeded => Colors.red.shade600,
    };
  }

  String get label {
    return switch (this) {
      BudgetStatus.good => 'ভালো',
      BudgetStatus.warning => 'সতর্কতা',
      BudgetStatus.exceeded => 'সীমা পেরিয়েছে',
    };
  }
}
