/// One calendar day of a money list: its rows (newest first) and their summed
/// amount — the "daily subtotal" in the খরচ / আয় list headers.
class DayGroup<T> {
  const DayGroup({required this.day, required this.items, required this.total});

  /// Local midnight of the day.
  final DateTime day;

  /// Newest first; rows with the same instant keep their input order.
  final List<T> items;

  /// Sum of [items]' amounts. Every row counts, including EMI rows: the header
  /// answers "how much moved that day", not "how much did I spend".
  final double total;
}

/// Groups [items] by local calendar day, newest day first and newest row first
/// within a day. Pure: no I/O, no clock, stable for equal timestamps (input
/// order is the tiebreak, so a list never reshuffles between rebuilds).
List<DayGroup<T>> groupByDay<T>(
  Iterable<T> items, {
  required DateTime Function(T item) dateOf,
  required double Function(T item) amountOf,
}) {
  final indexed = <(int, T)>[for (final (i, item) in items.indexed) (i, item)];
  indexed.sort((a, b) {
    final byDate = dateOf(b.$2).compareTo(dateOf(a.$2));
    return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
  });

  final groups = <DayGroup<T>>[];
  DateTime? currentDay;
  var bucket = <T>[];
  var total = 0.0;

  void flush() {
    final day = currentDay;
    if (day != null) {
      groups.add(DayGroup(day: day, items: bucket, total: total));
    }
  }

  for (final (_, item) in indexed) {
    final d = dateOf(item);
    final day = DateTime(d.year, d.month, d.day);
    if (currentDay == null || day != currentDay) {
      flush();
      currentDay = day;
      bucket = <T>[];
      total = 0;
    }
    bucket.add(item);
    total += amountOf(item);
  }
  flush();
  return groups;
}
