import '../../domain/entities/recurring_expense_entity.dart';
import '../../../expense/domain/entities/expense_entity.dart';

class RecurringDetectionService {
  const RecurringDetectionService();

  Future<List<RecurringExpenseEntity>> detectPatterns(
    List<ExpenseEntity> expenses,
  ) async {
    final groups = <String, List<ExpenseEntity>>{};
    for (final expense in expenses) {
      final key =
          '${expense.category}_${expense.description.trim().toLowerCase()}';
      groups.putIfAbsent(key, () => []).add(expense);
    }

    final patterns = <RecurringExpenseEntity>[];

    for (final entry in groups.entries) {
      final group = [...entry.value];
      if (group.length < 2) {
        continue;
      }

      group.sort((first, second) => first.date.compareTo(second.date));

      final monthlyDay = _isMonthlyPattern(group);
      if (monthlyDay != null) {
        patterns.add(
          RecurringExpenseEntity(
            id: 0,
            description: group.first.description,
            category: group.first.category,
            averageAmount: _average(group.map((expense) => expense.amount)),
            frequency: RecurringFrequency.monthly,
            dayOfMonth: monthlyDay,
            dayOfWeek: 0,
            lastOccurrence: group.last.date,
            nextExpected: _nextMonthly(group.last.date, monthlyDay),
            isActive: true,
            reminderEnabled: true,
          ),
        );
        continue;
      }

      final weeklyDay = _isWeeklyPattern(group);
      if (weeklyDay != null) {
        patterns.add(
          RecurringExpenseEntity(
            id: 0,
            description: group.first.description,
            category: group.first.category,
            averageAmount: _average(group.map((expense) => expense.amount)),
            frequency: RecurringFrequency.weekly,
            dayOfMonth: 0,
            dayOfWeek: weeklyDay,
            lastOccurrence: group.last.date,
            nextExpected: group.last.date.add(const Duration(days: 7)),
            isActive: true,
            reminderEnabled: true,
          ),
        );
      }
    }

    patterns.sort((first, second) {
      final firstDate = first.nextExpected ?? first.lastOccurrence;
      final secondDate = second.nextExpected ?? second.lastOccurrence;
      return firstDate.compareTo(secondDate);
    });
    return patterns;
  }

  int? _isMonthlyPattern(List<ExpenseEntity> expenses) {
    if (expenses.length < 2) {
      return null;
    }

    final days = expenses.map((expense) => expense.date.day).toList();
    final avgDay = days.reduce((sum, day) => sum + day) ~/ days.length;
    final allSimilar = days.every((day) => (day - avgDay).abs() <= 3);
    return allSimilar ? avgDay : null;
  }

  int? _isWeeklyPattern(List<ExpenseEntity> expenses) {
    if (expenses.length < 3) {
      return null;
    }

    final days = expenses.map((expense) => expense.date.weekday).toList();
    final firstWeekday = days.first;
    final allSimilar = days.every((day) => day == firstWeekday);
    return allSimilar ? firstWeekday : null;
  }

  double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0;
    }
    return list.fold<double>(0, (sum, value) => sum + value) / list.length;
  }

  DateTime _nextMonthly(DateTime lastDate, int dayOfMonth) {
    final nextMonth = DateTime(lastDate.year, lastDate.month + 1, 1);
    final lastDayOfNextMonth = DateTime(
      nextMonth.year,
      nextMonth.month + 1,
      0,
    ).day;
    final safeDay = dayOfMonth > lastDayOfNextMonth
        ? lastDayOfNextMonth
        : dayOfMonth;
    return DateTime(nextMonth.year, nextMonth.month, safeDay);
  }
}
