// Feature: Prediction
// Layer: Domain

import 'package:flutter/material.dart';

class PredictionEntity {
  const PredictionEntity({
    required this.predictedTotal,
    required this.currentTotal,
    required this.lastMonthTotal,
    required this.dailyAverage,
    required this.projectedDailyAverage,
    required this.trend,
    required this.confidence,
    required this.categoryPredictions,
    required this.aiInsight,
    required this.generatedAt,
    required this.currentDay,
    required this.daysInMonth,
    required this.daysRemaining,
  });

  final double predictedTotal;
  final double currentTotal;
  final double lastMonthTotal;
  final double dailyAverage;
  final double projectedDailyAverage;
  final PredictionTrend trend;
  final PredictionConfidence confidence;
  final Map<String, double> categoryPredictions;
  final String aiInsight;
  final DateTime generatedAt;
  final int currentDay;
  final int daysInMonth;
  final int daysRemaining;
}

enum PredictionTrend { increasing, decreasing, stable }

enum PredictionConfidence { low, medium, high }

extension PredictionTrendExt on PredictionTrend {
  String get label {
    return switch (this) {
      PredictionTrend.increasing => '↑ বাড়ছে',
      PredictionTrend.decreasing => '↓ কমছে',
      PredictionTrend.stable => '→ স্থিতিশীল',
    };
  }

  Color get color {
    return switch (this) {
      PredictionTrend.increasing => Colors.red.shade600,
      PredictionTrend.decreasing => Colors.green.shade600,
      PredictionTrend.stable => Colors.blue.shade600,
    };
  }

  IconData get icon {
    return switch (this) {
      PredictionTrend.increasing => Icons.trending_up,
      PredictionTrend.decreasing => Icons.trending_down,
      PredictionTrend.stable => Icons.trending_flat,
    };
  }
}

extension PredictionConfidenceExt on PredictionConfidence {
  String get label {
    return switch (this) {
      PredictionConfidence.low => 'প্রাথমিক',
      PredictionConfidence.medium => 'আনুমানিক',
      PredictionConfidence.high => 'নির্ভরযোগ্য',
    };
  }

  Color get color {
    return switch (this) {
      PredictionConfidence.low => Colors.grey.shade500,
      PredictionConfidence.medium => Colors.orange.shade600,
      PredictionConfidence.high => Colors.green.shade600,
    };
  }
}
