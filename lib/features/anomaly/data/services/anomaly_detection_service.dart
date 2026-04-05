// Feature: Anomaly
// Layer: Data

import 'dart:math';

import 'package:intl/intl.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../../domain/entities/anomaly_alert.dart';

class AnomalyDetectionService {
  const AnomalyDetectionService();

  /// Detects unusual local spending patterns without using any remote model.
  List<AnomalyAlert> detect({
    required List<ExpenseEntity> last30Days,
    required List<ExpenseEntity> previous90Days,
  }) {
    final alerts = <AnomalyAlert>[];
    var alertId = 1;
    final detectedAt = DateTime.now();

    final currentByCategory = _groupByCategory(last30Days);
    final historicalByCategory = _groupByCategory(previous90Days);

    for (final entry in currentByCategory.entries) {
      final category = entry.key;
      final current = entry.value;
      final historical = historicalByCategory[category] ?? 0.0;
      final historicalMonthly = historical / 3;

      if (historicalMonthly < 100) {
        continue;
      }

      final ratio = current / historicalMonthly;
      final severity = _categorySeverity(ratio);
      if (severity == null) {
        continue;
      }

      alerts.add(
        AnomalyAlert(
          id: alertId++,
          type: AnomalyType.categorySpike,
          severity: severity,
          category: category,
          currentAmount: current,
          normalAmount: historicalMonthly,
          ratio: ratio,
          message:
              '$category এ স্বাভাবিকের চেয়ে ${((ratio - 1) * 100).toStringAsFixed(0)}% বেশি খরচ হচ্ছে। '
              'স্বাভাবিক: ৳${historicalMonthly.toStringAsFixed(0)}, '
              'এই মাসে: ৳${current.toStringAsFixed(0)}',
          detectedAt: detectedAt,
        ),
      );
    }

    if (last30Days.isNotEmpty) {
      final amounts = last30Days
          .map((expense) => expense.amount)
          .toList(growable: false);
      final average =
          amounts.reduce((first, second) => first + second) / amounts.length;
      final stdDev = _standardDeviation(amounts, average);
      final threshold = average + (stdDev * 2.5);

      for (final expense in last30Days) {
        if (expense.amount < threshold || expense.amount < 500) {
          continue;
        }

        alerts.add(
          AnomalyAlert(
            id: alertId++,
            type: AnomalyType.largeTransaction,
            severity: expense.amount >= threshold * 2
                ? AnomalySeverity.medium
                : AnomalySeverity.low,
            category: expense.category,
            currentAmount: expense.amount,
            normalAmount: average,
            ratio: average <= 0 ? 1 : expense.amount / average,
            message:
                '${expense.description} এ বড় পরিমাণ খরচ। গড় transaction: '
                '৳${average.toStringAsFixed(0)}, এটা: ৳${expense.amount.toStringAsFixed(0)}',
            detectedAt: detectedAt,
            relatedDate: expense.date,
          ),
        );
      }
    }

    final dailyTotals = _groupByDay(last30Days);
    if (dailyTotals.isNotEmpty) {
      final dailyValues = dailyTotals.values.toList(growable: false);
      final avgDaily =
          dailyValues.reduce((first, second) => first + second) /
          dailyValues.length;

      for (final entry in dailyTotals.entries) {
        final ratio = avgDaily <= 0 ? 1.0 : entry.value / avgDaily;
        if (ratio < 2.5 || entry.value < 500) {
          continue;
        }

        final severity = ratio >= 4
            ? AnomalySeverity.high
            : ratio >= 3
            ? AnomalySeverity.medium
            : AnomalySeverity.low;

        alerts.add(
          AnomalyAlert(
            id: alertId++,
            type: AnomalyType.dailySpike,
            severity: severity,
            category: 'সব',
            currentAmount: entry.value,
            normalAmount: avgDaily,
            ratio: ratio,
            message:
                '${DateFormat('dd MMMM', 'bn').format(entry.key)} এ স্বাভাবিকের চেয়ে '
                '${((ratio - 1) * 100).toStringAsFixed(0)}% বেশি খরচ হয়েছে। '
                'গড় দৈনিক: ৳${avgDaily.toStringAsFixed(0)}, '
                'ওইদিন: ৳${entry.value.toStringAsFixed(0)}',
            detectedAt: detectedAt,
            relatedDate: entry.key,
          ),
        );
      }
    }

    final last30Count = last30Days.length;
    final previous30Cutoff = DateTime.now().subtract(const Duration(days: 60));
    final prev30Count = previous90Days
        .where((expense) => expense.date.isAfter(previous30Cutoff))
        .length;

    if (prev30Count > 5 && last30Count > prev30Count * 1.8) {
      alerts.add(
        AnomalyAlert(
          id: alertId++,
          type: AnomalyType.frequencyIncrease,
          severity: AnomalySeverity.low,
          category: 'সব',
          currentAmount: last30Count.toDouble(),
          normalAmount: prev30Count.toDouble(),
          ratio: last30Count / prev30Count,
          message:
              'এই মাসে transactions এর সংখ্যা অনেক বেশি। গত মাসে: $prev30Count টি, '
              'এই মাসে: $last30Count টি',
          detectedAt: detectedAt,
        ),
      );
    }

    alerts.sort((first, second) {
      final severityCompare = second.severity.index.compareTo(
        first.severity.index,
      );
      if (severityCompare != 0) {
        return severityCompare;
      }
      return second.ratio.compareTo(first.ratio);
    });
    return alerts;
  }

  AnomalySeverity? _categorySeverity(double ratio) {
    if (ratio >= 3) {
      return AnomalySeverity.high;
    }
    if (ratio >= 2) {
      return AnomalySeverity.medium;
    }
    if (ratio >= 1.5) {
      return AnomalySeverity.low;
    }
    return null;
  }

  Map<String, double> _groupByCategory(List<ExpenseEntity> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  Map<DateTime, double> _groupByDay(List<ExpenseEntity> expenses) {
    final totals = <DateTime, double>{};
    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      totals.update(
        day,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  double _standardDeviation(List<double> values, double mean) {
    if (values.isEmpty) {
      return 0;
    }

    final variance =
        values
            .map((value) => pow(value - mean, 2).toDouble())
            .reduce((first, second) => first + second) /
        values.length;
    return sqrt(variance);
  }
}
