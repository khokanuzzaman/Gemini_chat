import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/expense/domain/day_groups.dart';

typedef DayRow = ({String id, DateTime at, double amount});

DayRow row(String id, DateTime at, double amount) =>
    (id: id, at: at, amount: amount);

List<DayGroup<DayRow>> group(Iterable<DayRow> rows) =>
    groupByDay<DayRow>(rows, dateOf: (x) => x.at, amountOf: (x) => x.amount);

void main() {
  test('empty input -> no groups', () {
    expect(group(const []), isEmpty);
  });

  test('one day: rows newest first, total is their sum', () {
    final g = group([
      row('a', DateTime(2026, 10, 5, 9), 100),
      row('b', DateTime(2026, 10, 5, 21), 250),
      row('c', DateTime(2026, 10, 5, 13), 50),
    ]);
    expect(g, hasLength(1));
    expect(g.single.day, DateTime(2026, 10, 5));
    expect(g.single.items.map((x) => x.id), ['b', 'c', 'a']);
    expect(g.single.total, 400);
  });

  test('days are newest first, whatever the input order', () {
    final g = group([
      row('old', DateTime(2026, 10, 1, 10), 10),
      row('new', DateTime(2026, 10, 7, 10), 20),
      row('mid', DateTime(2026, 10, 4, 10), 30),
    ]);
    expect(g.map((d) => d.day.day), [7, 4, 1]);
    expect(g.map((d) => d.total), [20, 30, 10]);
  });

  test('day boundary: 23:59:59 and 00:00:00 land on different days', () {
    final g = group([
      row('late', DateTime(2026, 10, 4, 23, 59, 59), 5),
      row('early', DateTime(2026, 10, 5, 0, 0, 0), 7),
    ]);
    expect(g, hasLength(2));
    expect(g[0].items.single.id, 'early');
    expect(g[1].items.single.id, 'late');
  });

  test('month and year boundaries group by the real calendar day', () {
    final g = group([
      row('dec', DateTime(2025, 12, 31, 22), 1),
      row('jan', DateTime(2026, 1, 1, 1), 2),
    ]);
    expect(g.map((d) => d.day), [DateTime(2026, 1, 1), DateTime(2025, 12, 31)]);
  });

  test('equal timestamps keep input order (no flicker between rebuilds)', () {
    final t = DateTime(2026, 10, 5, 12);
    final rows = [row('x', t, 1), row('y', t, 1), row('z', t, 1)];
    expect(group(rows).single.items.map((e) => e.id), ['x', 'y', 'z']);
    expect(group(rows.reversed).single.items.map((e) => e.id), ['z', 'y', 'x']);
  });

  test('does not mutate the input', () {
    final rows = [
      row('a', DateTime(2026, 10, 1), 1),
      row('b', DateTime(2026, 10, 2), 2),
    ];
    group(rows);
    expect(rows.map((e) => e.id), ['a', 'b']);
  });

  test('every row is in exactly one group (5,000 rows over 200 days)', () {
    final rows = [
      for (var i = 0; i < 5000; i++)
        row('$i', DateTime(2026, 1, 1).add(Duration(hours: i * 23 % 4800)), 10),
    ];
    final g = group(rows);
    expect(g.fold<int>(0, (n, d) => n + d.items.length), 5000);
    expect(g.fold<double>(0, (n, d) => n + d.total), 50000);
    for (var i = 1; i < g.length; i++) {
      expect(g[i - 1].day.isAfter(g[i].day), isTrue);
    }
  });
}
