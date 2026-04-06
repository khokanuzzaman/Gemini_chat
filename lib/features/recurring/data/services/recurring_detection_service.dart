import 'dart:math';

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
      if (group.length < 3) {
        continue;
      }

      group.sort((first, second) => first.date.compareTo(second.date));

      final monthlyPattern = _isMonthlyPattern(group);
      if (monthlyPattern != null) {
        patterns.add(
          RecurringExpenseEntity(
            id: 0,
            description: group.first.description,
            category: group.first.category,
            averageAmount: _average(group.map((expense) => expense.amount)),
            frequency: RecurringFrequency.monthly,
            dayOfMonth: monthlyPattern.dayOfMonth,
            dayOfWeek: 0,
            lastOccurrence: group.last.date,
            nextExpected: _nextMonthly(
              group.last.date,
              monthlyPattern.dayOfMonth,
            ),
            isActive: true,
            reminderEnabled: true,
            confidenceScore: monthlyPattern.confidenceScore,
          ),
        );
        continue;
      }

      final weeklyPattern = _isWeeklyPattern(group);
      if (weeklyPattern != null) {
        patterns.add(
          RecurringExpenseEntity(
            id: 0,
            description: group.first.description,
            category: group.first.category,
            averageAmount: _average(group.map((expense) => expense.amount)),
            frequency: RecurringFrequency.weekly,
            dayOfMonth: 0,
            dayOfWeek: weeklyPattern.dayOfWeek,
            lastOccurrence: group.last.date,
            nextExpected: group.last.date.add(const Duration(days: 7)),
            isActive: true,
            reminderEnabled: true,
            confidenceScore: weeklyPattern.confidenceScore,
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

  _MonthlyPatternMatch? _isMonthlyPattern(List<ExpenseEntity> expenses) {
    if (expenses.length < 3 || _hasGapGreaterThan(expenses, 60)) {
      return null;
    }

    final days = expenses.map((expense) => expense.date.day).toList();
    final meanDay = _average(days.map((day) => day.toDouble()));
    final allSimilar = days.every((day) => (day - meanDay).abs() <= 4);
    if (!allSimilar) {
      return null;
    }

    final confidenceScore = (1.0 - (_stdDev(days, meanDay) / 15.0))
        .clamp(0.0, 1.0)
        .toDouble();
    if (confidenceScore < 0.5) {
      return null;
    }

    final dayOfMonth = max(1, min(31, meanDay.round()));
    return _MonthlyPatternMatch(
      dayOfMonth: dayOfMonth,
      confidenceScore: confidenceScore,
    );
  }

  _WeeklyPatternMatch? _isWeeklyPattern(List<ExpenseEntity> expenses) {
    if (expenses.length < 3 || _hasGapGreaterThan(expenses, 21)) {
      return null;
    }

    final weekdays = expenses.map((expense) => expense.date.weekday).toList();
    int? matchedWeekday;
    var bestDistance = double.infinity;

    for (
      var candidate = DateTime.monday;
      candidate <= DateTime.sunday;
      candidate++
    ) {
      final distances = weekdays
          .map((weekday) => _weekdayDistance(weekday, candidate))
          .toList(growable: false);
      if (distances.any((distance) => distance > 1)) {
        continue;
      }

      final totalDistance = distances.fold<int>(0, (sum, value) => sum + value);
      if (totalDistance < bestDistance) {
        bestDistance = totalDistance.toDouble();
        matchedWeekday = candidate;
      }
    }

    if (matchedWeekday == null) {
      return null;
    }

    final intervals = <double>[];
    for (var index = 1; index < expenses.length; index++) {
      intervals.add(
        expenses[index].date
            .difference(expenses[index - 1].date)
            .inDays
            .toDouble(),
      );
    }

    final meanInterval = _average(intervals);
    if (meanInterval < 5 || meanInterval > 9) {
      return null;
    }

    final confidenceScore = (1.0 - (_stdDev(intervals, meanInterval) / 7.0))
        .clamp(0.0, 1.0)
        .toDouble();
    if (confidenceScore < 0.5) {
      return null;
    }

    return _WeeklyPatternMatch(
      dayOfWeek: matchedWeekday,
      confidenceScore: confidenceScore,
    );
  }

  bool _hasGapGreaterThan(List<ExpenseEntity> expenses, int maxDays) {
    for (var index = 1; index < expenses.length; index++) {
      final gap = expenses[index].date
          .difference(expenses[index - 1].date)
          .inDays;
      if (gap > maxDays) {
        return true;
      }
    }
    return false;
  }

  int _weekdayDistance(int left, int right) {
    final diff = (left - right).abs();
    return min(diff, 7 - diff);
  }

  double _stdDev(List<num> values, double mean) {
    if (values.isEmpty) {
      return 0;
    }

    final variance =
        values
            .map((value) => pow(value.toDouble() - mean, 2).toDouble())
            .reduce((sum, value) => sum + value) /
        values.length;
    return sqrt(variance);
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

class _MonthlyPatternMatch {
  const _MonthlyPatternMatch({
    required this.dayOfMonth,
    required this.confidenceScore,
  });

  final int dayOfMonth;
  final double confidenceScore;
}

class _WeeklyPatternMatch {
  const _WeeklyPatternMatch({
    required this.dayOfWeek,
    required this.confidenceScore,
  });

  final int dayOfWeek;
  final double confidenceScore;
}
