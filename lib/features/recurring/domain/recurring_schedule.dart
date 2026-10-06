import 'dart:math' as math;

import 'entities/recurring_expense_entity.dart';

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

/// The next date [entry] is due, on or after [today] (date only).
///
/// THE one place that answers "when is this recurring expense next due?" — the
/// Recurring screen, Home, the obligations list and the AI context all use it.
/// It deliberately does not read `RecurringExpenseEntity.nextExpected`: that field is
/// stamped once when an entry is created and never advanced, so it is in the past
/// after a month. We derive the date from the schedule instead, and never write it
/// back.
DateTime nextDueDate(RecurringExpenseEntity entry, {required DateTime today}) {
  return switch (entry.frequency) {
    RecurringFrequency.monthly => nextMonthlyOccurrence(
      today: today,
      dayOfMonth: entry.dayOfMonth,
      lastOccurrence: entry.lastOccurrence,
    ),
    RecurringFrequency.weekly => nextWeeklyOccurrence(
      today: today,
      dayOfWeek: entry.dayOfWeek,
      lastOccurrence: entry.lastOccurrence,
    ),
    RecurringFrequency.daily => _nextDaily(today, entry.lastOccurrence),
  };
}

DateTime _nextDaily(DateTime today, DateTime lastOccurrence) {
  final start = dateOnly(today);
  final last = dateOnly(lastOccurrence);
  return last.isBefore(start)
      ? start
      : DateTime(last.year, last.month, last.day + 1);
}
