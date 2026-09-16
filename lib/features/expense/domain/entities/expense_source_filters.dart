// Feature: Expense
// Layer: Domain
//
// Per-surface spending filters. Every total / chart / forecast / alert applies
// the predicate for ITS surface, so debtPayment (task 4) and goalDeposit
// (task 5) participate exactly per the approved policy matrix — applied
// explicitly at each site, never relying on absence-of-filter.
//
// Today (before any debtPayment/goalDeposit rows exist) these are all no-ops:
// every stored row is ExpenseSource.expense, which counts in every surface.

import 'expense_entity.dart';
import 'expense_source.dart';

extension ExpenseSourceFilters on Iterable<ExpenseEntity> {
  /// Spending totals / analytics ("how much did I spend").
  Iterable<ExpenseEntity> get inSpendingTotals =>
      where((e) => e.sourceType.countsInSpendingTotals);

  /// Category budgets.
  Iterable<ExpenseEntity> get inCategoryBudget =>
      where((e) => e.sourceType.countsInCategoryBudget);

  /// End-of-month spend prediction.
  Iterable<ExpenseEntity> get inPrediction =>
      where((e) => e.sourceType.countsInPrediction);

  /// Anomaly detection (excludes scheduled debt/EMI payments).
  Iterable<ExpenseEntity> get inAnomaly =>
      where((e) => e.sourceType.countsInAnomaly);

  /// Cash-flow outflows.
  Iterable<ExpenseEntity> get inCashFlow =>
      where((e) => e.sourceType.countsInCashFlow);

  /// Recurring-pattern detection. Only ordinary expenses feed it — debtPayment
  /// EMIs are already modeled as debt, and goalDeposit is a transfer.
  Iterable<ExpenseEntity> get forRecurringDetection =>
      where((e) => e.sourceType == ExpenseSource.expense);
}
