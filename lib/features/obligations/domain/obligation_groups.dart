import 'upcoming_obligation.dart';

/// The sections of the full "আসন্ন পরিশোধ" list, in display order.
enum ObligationSection {
  overdue('মেয়াদ পেরিয়েছে'),
  thisWeek('এই সপ্তাহে'),
  thisMonth('এই মাসে'),
  later('পরে');

  const ObligationSection(this.label);
  final String label;
}

class ObligationGroup {
  const ObligationGroup(this.section, this.items);

  final ObligationSection section;
  final List<UpcomingObligation> items;

  double get total => items.fold<double>(0, (sum, item) => sum + item.amount);
}

/// Buckets [items] for the full list. Pure (the clock is a parameter):
///
/// * **overdue** — the combiner's own flag (an unpaid debt due date in the past);
/// * **this week** — due today up to 6 days ahead;
/// * **this month** — after that, still in [today]'s calendar month;
/// * **later** — everything after (the combiner's 30-day window can reach into
///   next month).
///
/// Keeps the combiner's order inside a section (it is already date-sorted) and
/// returns only the non-empty sections.
List<ObligationGroup> groupObligations(
  Iterable<UpcomingObligation> items, {
  required DateTime today,
}) {
  final day = DateTime(today.year, today.month, today.day);
  final weekEnd = day.add(const Duration(days: 6));
  final monthEnd = DateTime(day.year, day.month + 1, 0);

  final buckets = {
    for (final s in ObligationSection.values) s: <UpcomingObligation>[],
  };
  for (final item in items) {
    final due = DateTime(
      item.dueDate.year,
      item.dueDate.month,
      item.dueDate.day,
    );
    final section = item.isOverdue
        ? ObligationSection.overdue
        : !due.isAfter(weekEnd)
        ? ObligationSection.thisWeek
        : !due.isAfter(monthEnd)
        ? ObligationSection.thisMonth
        : ObligationSection.later;
    buckets[section]!.add(item);
  }
  return [
    for (final section in ObligationSection.values)
      if (buckets[section]!.isNotEmpty)
        ObligationGroup(section, buckets[section]!),
  ];
}
