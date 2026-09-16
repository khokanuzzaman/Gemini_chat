// Feature: Expense
// Layer: Domain
//
// Origin/kind of an expense record. Persisted on ExpenseRecordModel and used to
// decide, PER AGGREGATION SURFACE, whether a row participates. There is no
// blanket `isConsumption` flag by design: debt/EMI and goal deposits differ per
// surface (e.g. EMI feeds prediction but not anomaly), so every aggregation site
// must reference the specific predicate it needs.

/// APPEND ONLY — Isar stores the ordinal (the index), not the name. Never
/// reorder or insert; new values go at the end. Reordering or inserting would
/// silently re-class existing rows on disk (e.g. every `debtPayment` row would
/// read back as `goalDeposit`) — the exact silent corruption this feature fixes.
/// `expense` MUST stay at index 0 so legacy rows (written before this field
/// existed, and any call site that doesn't set it) default to it. The ordinals
/// are locked by expense_source_migration_test.dart.
enum ExpenseSource {
  /// Ordinary user/AI/receipt/SMS expense — full consumption. (index 0 — do not move)
  expense,

  /// Debt / EMI repayment. A real, highly predictable cash outflow, but a
  /// scheduled payment is not an anomaly.
  debtPayment,

  /// Wallet → goal deposit. A transfer into savings, not consumption.
  goalDeposit,
}

/// Per-surface participation policy. Each getter maps 1:1 to one aggregation
/// surface; aggregation code must call the exact predicate it means.
///
/// Policy matrix (approved):
///                 spendingTotals  categoryBudget  prediction  anomaly  cashFlow
///   expense             ✅              ✅            ✅          ✅        ✅
///   debtPayment         ✅              ✅            ✅          ❌        ✅
///   goalDeposit         ❌              ❌            ❌          ❌        ✅
extension ExpenseSourcePolicy on ExpenseSource {
  /// Counts toward spending totals / analytics ("how much did I spend").
  bool get countsInSpendingTotals => switch (this) {
    ExpenseSource.expense => true,
    ExpenseSource.debtPayment => true,
    ExpenseSource.goalDeposit => false,
  };

  /// Counts against category budgets.
  bool get countsInCategoryBudget => switch (this) {
    ExpenseSource.expense => true,
    ExpenseSource.debtPayment => true,
    ExpenseSource.goalDeposit => false,
  };

  /// Feeds end-of-month spend prediction. EMI is the most predictable outflow a
  /// user has, so excluding it would understate real cash needs.
  bool get countsInPrediction => switch (this) {
    ExpenseSource.expense => true,
    ExpenseSource.debtPayment => true,
    ExpenseSource.goalDeposit => false,
  };

  /// Considered by anomaly detection. Scheduled debt/EMI payments would
  /// false-positive, so they are excluded.
  bool get countsInAnomaly => switch (this) {
    ExpenseSource.expense => true,
    ExpenseSource.debtPayment => false,
    ExpenseSource.goalDeposit => false,
  };

  /// Appears as an outflow in cash flow — all real money movement is visible.
  bool get countsInCashFlow => switch (this) {
    ExpenseSource.expense => true,
    ExpenseSource.debtPayment => true,
    ExpenseSource.goalDeposit => true,
  };
}
