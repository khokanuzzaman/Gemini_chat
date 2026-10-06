import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/net_worth/data/models/net_worth_snapshot_model.dart';
import 'package:gemini_chat/features/net_worth/data/net_worth_snapshot_retention.dart';

typedef _Row = ({int id, int dayKey});

/// One snapshot per calendar day for [days] days ending [today] (inclusive).
List<_Row> _daily(DateTime today, int days) {
  return [
    for (var i = 0; i < days; i++)
      (
        id: i + 1,
        dayKey: dayKeyOf(DateTime(today.year, today.month, today.day - i)),
      ),
  ];
}

List<_Row> _apply(List<_Row> rows, DateTime today) {
  final delete = snapshotIdsToDelete(rows, today: today);
  return rows.where((row) => !delete.contains(row.id)).toList();
}

int _age(DateTime today, int dayKey) {
  final date = dateOfDayKey(dayKey);
  return DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
}

void main() {
  final today = DateTime(2026, 10, 6);
  final all = _daily(today, 800);
  final kept = _apply(all, today);

  test('every snapshot of the last 90 days is kept', () {
    final recent = all.where((row) => _age(today, row.dayKey) <= 90);
    expect(kept, containsAll(recent));
  });

  test('between 91 days and 12 months: exactly the last of each week '
      '(plus month edges)', () {
    final window = kept.where((row) {
      final age = _age(today, row.dayKey);
      return age > 90 && age <= 365;
    });
    // ~39 weeks + ~9 month edges; far fewer than the ~275 daily rows.
    expect(window.length, inInclusiveRange(35, 60));

    // No two kept rows share a Saturday-anchored week unless one is a month edge.
    final byMonth = <int, List<int>>{};
    for (final row in all) {
      byMonth.putIfAbsent(row.dayKey ~/ 100, () => []).add(row.dayKey);
    }
    bool isEdge(int dayKey) {
      final days = byMonth[dayKey ~/ 100]!..sort();
      return days.first == dayKey || days.last == dayKey;
    }

    int week(int dayKey) {
      final d = dateOfDayKey(dayKey);
      return (DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
                  86400000 +
              5) ~/
          7;
    }

    final nonEdgeWeeks = window
        .where((row) => !isEdge(row.dayKey))
        .map((row) => week(row.dayKey))
        .toList();
    expect(nonEdgeWeeks.toSet().length, nonEdgeWeeks.length);
  });

  test(
    'older than 12 months: only the first and last of each month survive',
    () {
      final old = kept.where((row) => _age(today, row.dayKey) > 365);
      final byMonth = <int, List<int>>{};
      for (final row in old) {
        byMonth.putIfAbsent(row.dayKey ~/ 100, () => []).add(row.dayKey);
      }
      for (final entry in byMonth.entries) {
        expect(
          entry.value.length,
          lessThanOrEqualTo(2),
          reason: '${entry.key}',
        );
      }
      // Both edges of a fully-covered old month are present.
      final months = {for (final row in all) row.dayKey ~/ 100: <int>[]};
      for (final row in all) {
        months[row.dayKey ~/ 100]!.add(row.dayKey);
      }
      final probe = 202410; // fully inside the 800-day history, > 12 months old
      final days = months[probe]!..sort();
      expect(
        byMonth[probe],
        unorderedEquals([days.first, days.last]),
        reason: 'first AND last of the month are kept forever',
      );
    },
  );

  test('is idempotent: re-running on its own output deletes nothing', () {
    expect(snapshotIdsToDelete(kept, today: today), isEmpty);
  });

  test('a lone old snapshot is kept (it is its own first and last)', () {
    final rows = [(id: 1, dayKey: 20220315)];
    expect(snapshotIdsToDelete(rows, today: today), isEmpty);
  });

  test('empty input is a no-op', () {
    expect(snapshotIdsToDelete(const [], today: today), isEmpty);
  });

  test('bounded growth: 10 years of daily opens stay a few hundred rows', () {
    final decade = _apply(_daily(today, 3650), today);
    expect(decade.length, lessThan(600));
  });
}
