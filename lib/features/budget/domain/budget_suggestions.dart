// Feature: Budget
// Layer: Domain
//
// Local, rule-based budget maths. No AI, no network, no storage: everything here
// is a pure function of the user's own expenses, so it is the same with the AI
// flag on or off and is unit-testable without a database.

import '../../../core/utils/bangla_formatters.dart';
import '../../expense/domain/entities/expense_entity.dart';
import '../../expense/domain/entities/expense_source_filters.dart';

/// Below this a limit moves in ৳100 steps, from here up in ৳500 steps.
const double budgetStepThreshold = 10000;
const double budgetSmallStep = 100;
const double budgetLargeStep = 500;

/// How many full calendar months the average looks back over.
const int suggestionLookbackMonths = 3;

/// Most suggestions shown at once — a short list is one people actually read.
const int maxSuggestions = 5;

double budgetStepFor(num amount) =>
    amount < budgetStepThreshold ? budgetSmallStep : budgetLargeStep;

/// Nearest ৳100 (under ৳10,000) or ৳500 (from ৳10,000) — a limit like ৳1,237 is
/// noise nobody will remember. Non-positive / non-finite input gives 0.
double roundBudgetLimit(num amount) {
  if (!amount.isFinite || amount <= 0) {
    return 0;
  }
  final step = budgetStepFor(amount);
  return (amount / step).round() * step;
}

/// Same grid, always rounding DOWN. Used when a total has to stay under a cap
/// (the 10% minimum savings): rounding up could push it back over.
double floorBudgetLimit(num amount) {
  if (!amount.isFinite || amount <= 0) {
    return 0;
  }
  final step = budgetStepFor(amount);
  return (amount / step).floor() * step;
}

/// Average monthly spend per category over the [suggestionLookbackMonths] FULL
/// calendar months before [now]'s month (the month in progress is left out — a
/// half-finished month would drag every average down).
///
/// A user with less history is not penalised: the divisor is the number of
/// months since their first expense in that window (1–3), not a flat 3.
Map<String, double> averageMonthlySpendByCategory(
  Iterable<ExpenseEntity> expenses, {
  required DateTime now,
}) {
  final windowStart = DateTime(now.year, now.month - suggestionLookbackMonths);
  final windowEnd = DateTime(now.year, now.month);

  final inWindow = expenses.inCategoryBudget
      .where((e) => !e.date.isBefore(windowStart) && e.date.isBefore(windowEnd))
      .toList(growable: false);
  if (inWindow.isEmpty) {
    return const {};
  }

  final months = monthsObserved(inWindow, now: now);
  final totals = <String, double>{};
  for (final expense in inWindow) {
    totals.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }
  return totals.map((key, value) => MapEntry(key, value / months));
}

/// How many months of history [averageMonthlySpendByCategory] divided by for
/// these expenses (1 when there is none).
int monthsOfHistory(Iterable<ExpenseEntity> expenses, {required DateTime now}) {
  final windowStart = DateTime(now.year, now.month - suggestionLookbackMonths);
  final windowEnd = DateTime(now.year, now.month);
  final inWindow = expenses.inCategoryBudget.where(
    (e) => !e.date.isBefore(windowStart) && e.date.isBefore(windowEnd),
  );
  return monthsObserved(inWindow, now: now);
}

/// 1–[suggestionLookbackMonths]: calendar months from the earliest expense in
/// the window up to (not including) the current month.
int monthsObserved(Iterable<ExpenseEntity> inWindow, {required DateTime now}) {
  if (inWindow.isEmpty) {
    return 1;
  }
  final earliest = inWindow
      .map((e) => e.date)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final span = (now.year - earliest.year) * 12 + (now.month - earliest.month);
  return span.clamp(1, suggestionLookbackMonths);
}

class CategoryLimitSuggestion {
  const CategoryLimitSuggestion({
    required this.category,
    required this.averageMonthly,
    required this.suggestedLimit,
    required this.currentLimit,
    required this.months,
  });

  final String category;
  final double averageMonthly;
  final double suggestedLimit;

  /// 0 when the category has no limit yet.
  final double currentLimit;
  final int months;

  bool get isNew => currentLimit <= 0;

  /// One line, Bengali numerals: why this number.
  String get reason {
    final avg = BanglaFormatters.currency(averageMonthly.round());
    final span = 'গত ${BanglaFormatters.count(months)} মাসে';
    return isNew
        ? '$span গড়ে $avg খরচ হয়েছে'
        : '$span গড়ে $avg খরচ — এখনকার সীমা ${BanglaFormatters.currency(currentLimit.round())}';
  }
}

/// Suggested monthly limits from past spending: each category's average rounded
/// to the limit grid (never below one step for a category you do spend on).
/// Only categories whose suggestion differs from the current limit are returned,
/// the biggest change first, capped at [maxSuggestions]. Pure — nothing is
/// written; the caller applies a suggestion only when the user taps it.
List<CategoryLimitSuggestion> suggestCategoryLimits({
  required Map<String, double> averageByCategory,
  required Map<String, double> currentLimits,
  required Set<String> liveCategoryNames,
  required int months,
}) {
  final live = liveCategoryNames.map((n) => n.trim().toLowerCase()).toSet();
  final suggestions = <CategoryLimitSuggestion>[];
  for (final entry in averageByCategory.entries) {
    if (entry.value <= 0 || !live.contains(entry.key.trim().toLowerCase())) {
      continue;
    }
    final rounded = roundBudgetLimit(entry.value);
    final suggested = rounded <= 0 ? budgetSmallStep : rounded;
    final current = currentLimits[entry.key] ?? 0;
    if (suggested == current) {
      continue;
    }
    suggestions.add(
      CategoryLimitSuggestion(
        category: entry.key,
        averageMonthly: entry.value,
        suggestedLimit: suggested,
        currentLimit: current,
        months: months,
      ),
    );
  }
  suggestions.sort(
    (a, b) => (b.suggestedLimit - b.currentLimit).abs().compareTo(
      (a.suggestedLimit - a.currentLimit).abs(),
    ),
  );
  return suggestions.take(maxSuggestions).toList(growable: false);
}

/// Share of a category limit already spent, in whole percent. Unclamped on
/// purpose: 130% is more honest than a bar silently capped at 100%.
int usagePercent(double spent, double limit) {
  if (limit <= 0 || !spent.isFinite || spent <= 0) {
    return 0;
  }
  return (spent / limit * 100).round();
}

enum LimitLevel { onTrack, nearLimit, over }

/// primary < 80%, warning 80–100%, danger only when over 100%. Compares real
/// amounts, so spending exactly the limit is "near limit", not "over".
LimitLevel limitLevel(double spent, double limit) {
  if (limit <= 0) {
    return LimitLevel.onTrack;
  }
  if (spent > limit) {
    return LimitLevel.over;
  }
  if (spent >= limit * 0.8) {
    return LimitLevel.nearLimit;
  }
  return LimitLevel.onTrack;
}
