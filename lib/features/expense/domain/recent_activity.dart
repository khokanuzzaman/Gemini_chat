import '../../income/domain/entities/income_entity.dart';
import 'entities/expense_entity.dart';
import 'entities/expense_source.dart';

enum ActivityKind { expense, income }

/// One row of Home's "সাম্প্রতিক লেনদেন": an expense OR an income.
class RecentActivityItem {
  const RecentActivityItem({
    required this.kind,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    this.isEmi = false,
    this.id,
  });

  final ActivityKind kind;
  final String title;

  /// Expense category, or the income source.
  final String category;
  final DateTime date;
  final double amount;

  /// A debt/EMI repayment (shown with the brass marker).
  final bool isEmi;
  final int? id;

  bool get isIncome => kind == ActivityKind.income;
}

/// Last [limit] money movements across expenses and income, newest first.
///
/// Read-only merge of two existing feeds (dashboard recent expenses, all income).
/// Ties on the same instant are ordered deterministically: expense before income,
/// then higher id, then title — so the list never flickers between rebuilds.
List<RecentActivityItem> mergeRecentActivity({
  required Iterable<ExpenseEntity> expenses,
  required Iterable<IncomeEntity> incomes,
  int limit = 5,
}) {
  final items = <RecentActivityItem>[
    for (final expense in expenses)
      RecentActivityItem(
        kind: ActivityKind.expense,
        title: expense.description.trim().isEmpty
            ? expense.category
            : expense.description.trim(),
        category: expense.category,
        date: expense.date,
        amount: expense.amount,
        isEmi: expense.sourceType == ExpenseSource.debtPayment,
        id: expense.id,
      ),
    for (final income in incomes)
      RecentActivityItem(
        kind: ActivityKind.income,
        title: income.description.trim().isEmpty
            ? income.source
            : income.description.trim(),
        category: income.source,
        date: income.date,
        amount: income.amount,
        id: income.id,
      ),
  ];

  items.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) {
      return byDate;
    }
    if (a.kind != b.kind) {
      return a.kind == ActivityKind.expense ? -1 : 1;
    }
    final byId = (b.id ?? 0).compareTo(a.id ?? 0);
    if (byId != 0) {
      return byId;
    }
    return a.title.compareTo(b.title);
  });
  return items.take(limit).toList(growable: false);
}
