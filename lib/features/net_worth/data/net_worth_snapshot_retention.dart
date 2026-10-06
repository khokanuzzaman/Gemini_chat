import 'models/net_worth_snapshot_model.dart';

/// Which snapshots to delete so history stays bounded:
///
/// * **daily** for the last [dailyDays] (90) days;
/// * **weekly** (the last snapshot of each Saturday-anchored week) out to
///   [weeklyDays] (365) days;
/// * **monthly forever**: the FIRST and LAST snapshot of every calendar month.
///   Capture is open-based, so the true month-end balance is unknowable — the
///   last snapshot of October and the first of November each miss part of the gap.
///   Keeping both lets the chart decide how to label it.
///
/// Pure and idempotent: running it again on its own output deletes nothing.
/// Returns the ids to delete.
Set<int> snapshotIdsToDelete(
  List<({int id, int dayKey})> snapshots, {
  required DateTime today,
  int dailyDays = 90,
  int weeklyDays = 365,
}) {
  if (snapshots.isEmpty) {
    return const {};
  }
  final todayDay = _epochDay(today.year, today.month, today.day);

  int monthOf(int dayKey) => dayKey ~/ 100;
  int weekBucket(int dayKey) {
    final date = dateOfDayKey(dayKey);
    // 1970-01-03 was a Saturday (epoch day 2); +5 floors weeks to start there.
    return (_epochDay(date.year, date.month, date.day) + 5) ~/ 7;
  }

  final firstOfMonth = <int, int>{}; // month -> smallest dayKey
  final lastOfMonth = <int, int>{}; // month -> largest dayKey
  final lastOfWeek = <int, int>{}; // week bucket -> largest dayKey
  for (final snapshot in snapshots) {
    final month = monthOf(snapshot.dayKey);
    final first = firstOfMonth[month];
    if (first == null || snapshot.dayKey < first) {
      firstOfMonth[month] = snapshot.dayKey;
    }
    final last = lastOfMonth[month];
    if (last == null || snapshot.dayKey > last) {
      lastOfMonth[month] = snapshot.dayKey;
    }
    final week = weekBucket(snapshot.dayKey);
    final lastInWeek = lastOfWeek[week];
    if (lastInWeek == null || snapshot.dayKey > lastInWeek) {
      lastOfWeek[week] = snapshot.dayKey;
    }
  }

  final delete = <int>{};
  for (final snapshot in snapshots) {
    final date = dateOfDayKey(snapshot.dayKey);
    final age = todayDay - _epochDay(date.year, date.month, date.day);
    final month = monthOf(snapshot.dayKey);
    final isMonthEdge =
        firstOfMonth[month] == snapshot.dayKey ||
        lastOfMonth[month] == snapshot.dayKey;
    if (age <= dailyDays || isMonthEdge) {
      continue;
    }
    if (age <= weeklyDays &&
        lastOfWeek[weekBucket(snapshot.dayKey)] == snapshot.dayKey) {
      continue;
    }
    delete.add(snapshot.id);
  }
  return delete;
}

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ 86400000;
