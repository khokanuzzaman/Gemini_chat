// Locks the per-surface filter helper that every aggregation site now applies.
// The policy matrix itself is locked by expense_source_migration_test; this
// verifies the Iterable extension routes each source to the right surfaces.

import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source_filters.dart';

void main() {
  ExpenseEntity row(ExpenseSource source) => ExpenseEntity(
        amount: 100,
        category: source == ExpenseSource.debtPayment ? 'EMI' : 'Food',
        description: source.name,
        date: DateTime(2026, 7, 10),
        sourceType: source,
      );

  final expense = row(ExpenseSource.expense);
  final debt = row(ExpenseSource.debtPayment);
  final goal = row(ExpenseSource.goalDeposit);
  final all = [expense, debt, goal];

  List<ExpenseSource> sourcesOf(Iterable<ExpenseEntity> it) =>
      it.map((e) => e.sourceType).toList();

  test('inSpendingTotals: expense + debtPayment (goalDeposit excluded)', () {
    expect(sourcesOf(all.inSpendingTotals),
        [ExpenseSource.expense, ExpenseSource.debtPayment]);
  });

  test('inCategoryBudget: expense + debtPayment', () {
    expect(sourcesOf(all.inCategoryBudget),
        [ExpenseSource.expense, ExpenseSource.debtPayment]);
  });

  test('inPrediction: expense + debtPayment', () {
    expect(sourcesOf(all.inPrediction),
        [ExpenseSource.expense, ExpenseSource.debtPayment]);
  });

  test('inAnomaly: expense only (debtPayment + goalDeposit excluded)', () {
    expect(sourcesOf(all.inAnomaly), [ExpenseSource.expense]);
  });

  test('inCashFlow: all three (debt as repayment, goal as savings)', () {
    expect(sourcesOf(all.inCashFlow), [
      ExpenseSource.expense,
      ExpenseSource.debtPayment,
      ExpenseSource.goalDeposit,
    ]);
  });

  test('forRecurringDetection: ordinary expense only', () {
    expect(sourcesOf(all.forRecurringDetection), [ExpenseSource.expense]);
  });
}
