import 'dart:math' as math;

import '../../debt/domain/entities/debt_entity.dart';
import '../../recurring/domain/entities/recurring_expense_entity.dart';

enum ObligationKind {
  /// An instalment (EMI) or the due date of a debt I owe.
  debt,

  /// A recurring expense the user marked (rent, subscriptions…).
  recurring,
}

/// One thing the user will have to pay: "১৬ অক্টোবর: বাড়িভাড়া ৳১৫,০০০".
class UpcomingObligation {
  const UpcomingObligation({
    required this.kind,
    required this.sourceId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.isOverdue,
    this.isEmi = false,
  });

  final ObligationKind kind;

  /// Debt id or recurring-entry id — what a tap deep-links to.
  final int sourceId;
  final String title;
  final double amount;

  /// Date only (midnight, local).
  final DateTime dueDate;

  /// Debt instalments/dues in the past that are still unpaid. Recurring entries
  /// are never overdue: they have no "paid" state to compare against.
  final bool isOverdue;
  final bool isEmi;

  String get key => '${kind.name}:$sourceId';
}

class UpcomingObligations {
  const UpcomingObligations(this.items);

  const UpcomingObligations.empty() : items = const [];

  /// Overdue first, then by date.
  final List<UpcomingObligation> items;

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
  UpcomingObligation? get next => items.isEmpty ? null : items.first;
  int get overdueCount => items.where((item) => item.isOverdue).length;
  double get totalAmount =>
      items.fold<double>(0, (sum, item) => sum + item.amount);
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// [dayOfMonth] in the given month, clamped to the month's length
/// (31 -> Apr 30 / Feb 28 or 29). Always computed from the ORIGINAL day, so
/// 31 goes Jan 31 -> Feb 28 -> Mar 31, never drifting to the 28th.
DateTime dayInMonthClamped(int year, int month, int dayOfMonth) {
  final normalized = DateTime(
    year,
    month,
    1,
  ); // normalises month 13 -> next year
  return DateTime(
    normalized.year,
    normalized.month,
    math.min(dayOfMonth, daysInMonth(normalized.year, normalized.month)),
  );
}

/// First monthly occurrence on or after [today] that is strictly after
/// [lastOccurrence] (so a future-dated entry doesn't fire before its own date).
DateTime nextMonthlyOccurrence({
  required DateTime today,
  required int dayOfMonth,
  required DateTime lastOccurrence,
}) {
  final day = (dayOfMonth >= 1 && dayOfMonth <= 31)
      ? dayOfMonth
      : lastOccurrence.day;
  final last = dateOnly(lastOccurrence);
  final start = dateOnly(today);

  var year = start.year;
  var month = start.month;
  var candidate = dayInMonthClamped(year, month, day);
  while (candidate.isBefore(start) || !candidate.isAfter(last)) {
    month += 1;
    candidate = dayInMonthClamped(year, month, day);
  }
  return candidate;
}

/// First weekly occurrence (`dayOfWeek` 1=Mon..7=Sun, like [DateTime.weekday])
/// on or after [today] and strictly after [lastOccurrence].
DateTime nextWeeklyOccurrence({
  required DateTime today,
  required int dayOfWeek,
  required DateTime lastOccurrence,
}) {
  final weekday = (dayOfWeek >= 1 && dayOfWeek <= 7)
      ? dayOfWeek
      : lastOccurrence.weekday;
  final last = dateOnly(lastOccurrence);
  final start = dateOnly(today);

  var candidate = DateTime(
    start.year,
    start.month,
    start.day + ((weekday - start.weekday) % 7),
  );
  while (!candidate.isAfter(last)) {
    candidate = DateTime(candidate.year, candidate.month, candidate.day + 7);
  }
  return candidate;
}

String _normalize(String text) => text.trim().toLowerCase();

/// The text the ledger writes on the expense for an EMI payment
/// (`_debtExpenseDescription`): the debt's person name, or "EMI" when untitled.
String _emiExpenseDescriptionKey(DebtEntity debt) {
  final name = _normalize(debt.personName);
  return name.isEmpty ? 'emi' : name;
}

/// Merges recurring entries and debts into one date-sorted "what's due" list.
///
/// * **Recurring:** active monthly/weekly entries only (daily ones are habits,
///   not obligations). The next date is computed from `dayOfMonth`/`dayOfWeek`
///   relative to [today]; the stored `nextExpected` is IGNORED because it is
///   stamped once when the entry is created and never advanced, so it goes stale.
/// * **Debts:** money I owe (`iOwe`) that is open and has a due date — an EMI's
///   next instalment or a plain debt's due date. Receivables (`theyOwe`) are not
///   something I pay. Past-due ones are kept and flagged, whatever their age.
/// * **Window:** upcoming items within [windowDays] (inclusive of today).
/// * **De-dup:** an EMI payment expense that the user marked recurring leaves a
///   recurring entry with category "EMI" and the debt's name as its description.
///   That is the same obligation as the debt's instalment, so the debt wins and
///   the recurring entry is dropped. Matching is on that exact signature only —
///   never on amount/date, which would hide e.g. a ৳15,000 rent that happens to
///   fall on the same day as a ৳15,000 EMI.
UpcomingObligations mergeUpcomingObligations({
  required DateTime today,
  required Iterable<RecurringExpenseEntity> recurring,
  required Iterable<DebtEntity> debts,
  int windowDays = 30,
}) {
  final start = dateOnly(today);
  final end = DateTime(start.year, start.month, start.day + windowDays);
  final items = <UpcomingObligation>[];
  final emiSignatures = <String>{};

  for (final debt in debts) {
    final isOpen =
        debt.status == DebtStatus.active || debt.status == DebtStatus.overdue;
    final due = debt.effectiveDueDate;
    if (debt.type != DebtType.iOwe ||
        !isOpen ||
        debt.isFullyPaid ||
        due == null) {
      continue;
    }
    final dueDay = dateOnly(due);
    final overdue = dueDay.isBefore(start);
    if (!overdue && dueDay.isAfter(end)) {
      continue;
    }
    final description = debt.description?.trim();
    items.add(
      UpcomingObligation(
        kind: ObligationKind.debt,
        sourceId: debt.id,
        title: debt.personName.trim().isNotEmpty
            ? debt.personName.trim()
            : (description != null && description.isNotEmpty
                  ? description
                  : 'EMI'),
        amount: debt.nextInstallmentAmount,
        dueDate: dueDay,
        isOverdue: overdue,
        isEmi: debt.isEMI,
      ),
    );
    if (debt.isEMI) {
      emiSignatures.add(_emiExpenseDescriptionKey(debt));
    }
  }

  for (final entry in recurring) {
    if (!entry.isActive || entry.frequency == RecurringFrequency.daily) {
      continue;
    }
    if (_normalize(entry.category) == 'emi' &&
        emiSignatures.contains(_normalize(entry.description))) {
      continue; // already represented by the debt instalment
    }
    final due = switch (entry.frequency) {
      RecurringFrequency.monthly => nextMonthlyOccurrence(
        today: start,
        dayOfMonth: entry.dayOfMonth,
        lastOccurrence: entry.lastOccurrence,
      ),
      _ => nextWeeklyOccurrence(
        today: start,
        dayOfWeek: entry.dayOfWeek,
        lastOccurrence: entry.lastOccurrence,
      ),
    };
    if (due.isAfter(end)) {
      continue;
    }
    items.add(
      UpcomingObligation(
        kind: ObligationKind.recurring,
        sourceId: entry.id,
        title: entry.description.trim().isEmpty
            ? entry.category
            : entry.description.trim(),
        amount: entry.averageAmount,
        dueDate: due,
        isOverdue: false,
      ),
    );
  }

  items.sort((a, b) {
    if (a.isOverdue != b.isOverdue) {
      return a.isOverdue ? -1 : 1;
    }
    final byDate = a.dueDate.compareTo(b.dueDate);
    if (byDate != 0) {
      return byDate;
    }
    final byAmount = b.amount.compareTo(a.amount);
    if (byAmount != 0) {
      return byAmount;
    }
    return a.key.compareTo(b.key); // fully deterministic
  });
  return UpcomingObligations(List.unmodifiable(items));
}
