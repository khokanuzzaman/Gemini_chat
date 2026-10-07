import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/obligations/domain/obligation_groups.dart';
import 'package:gemini_chat/features/obligations/domain/upcoming_obligation.dart';

UpcomingObligation _ob(
  String title,
  DateTime due, {
  bool overdue = false,
  double amount = 100,
}) => UpcomingObligation(
  kind: ObligationKind.recurring,
  sourceId: title.hashCode,
  title: title,
  amount: amount,
  dueDate: due,
  isOverdue: overdue,
);

void main() {
  final today = DateTime(2026, 10, 6, 9, 30); // Tuesday

  test('empty -> no sections', () {
    expect(groupObligations(const [], today: today), isEmpty);
  });

  test('buckets by how soon, in display order, skipping empty sections', () {
    final groups = groupObligations([
      _ob('late', DateTime(2026, 9, 28), overdue: true),
      _ob('today', DateTime(2026, 10, 6)),
      _ob('in 6 days', DateTime(2026, 10, 12)),
      _ob('in 7 days', DateTime(2026, 10, 13)),
      _ob('month end', DateTime(2026, 10, 31)),
      _ob('next month', DateTime(2026, 11, 2)),
    ], today: today);

    expect(groups.map((g) => g.section), [
      ObligationSection.overdue,
      ObligationSection.thisWeek,
      ObligationSection.thisMonth,
      ObligationSection.later,
    ]);
    expect(groups[0].items.map((i) => i.title), ['late']);
    expect(groups[1].items.map((i) => i.title), ['today', 'in 6 days']);
    expect(groups[2].items.map((i) => i.title), ['in 7 days', 'month end']);
    expect(groups[3].items.map((i) => i.title), ['next month']);
  });

  test('only the sections that have something are returned', () {
    final groups = groupObligations([
      _ob('a', DateTime(2026, 10, 8)),
    ], today: today);
    expect(groups.map((g) => g.section), [ObligationSection.thisWeek]);
  });

  test('the overdue flag wins over the date', () {
    final groups = groupObligations([
      _ob('flagged', DateTime(2026, 10, 7), overdue: true),
    ], today: today);
    expect(groups.single.section, ObligationSection.overdue);
  });

  test('keeps the combiner order inside a section and sums amounts', () {
    final groups = groupObligations([
      _ob('b', DateTime(2026, 10, 7), amount: 300),
      _ob('a', DateTime(2026, 10, 9), amount: 200),
    ], today: today);
    expect(groups.single.items.map((i) => i.title), ['b', 'a']);
    expect(groups.single.total, 500);
  });

  test('time of day does not move a due date across a boundary', () {
    final groups = groupObligations([
      _ob('late night', DateTime(2026, 10, 12, 23, 59)),
    ], today: DateTime(2026, 10, 6, 0, 1));
    expect(groups.single.section, ObligationSection.thisWeek);
  });

  test('a December date does not break "this month" (year rollover)', () {
    final groups = groupObligations([
      _ob('jan', DateTime(2027, 1, 3)),
    ], today: DateTime(2026, 12, 28));
    expect(groups.single.section, ObligationSection.thisWeek);
    final later = groupObligations([
      _ob('jan', DateTime(2027, 1, 20)),
    ], today: DateTime(2026, 12, 28));
    expect(later.single.section, ObligationSection.later);
  });
}
