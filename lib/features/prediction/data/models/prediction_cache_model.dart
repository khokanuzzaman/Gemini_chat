// Feature: Prediction
// Layer: Data

import 'dart:convert';

import 'package:isar/isar.dart';

import '../../domain/entities/prediction_entity.dart';

part 'prediction_cache_model.g.dart';

@collection
class PredictionCacheModel {
  Id id = 1;

  late double predictedTotal;
  late double currentTotal;
  late double lastMonthTotal;
  late double dailyAverage;
  late double projectedDailyAverage;
  late String trend;
  late String confidence;
  late String categoryPredictionsJson;
  late String aiInsight;
  late DateTime generatedAt;
  late int currentDay;
  late int daysInMonth;
  late int daysRemaining;

  PredictionEntity toEntity() {
    final rawMap = jsonDecode(categoryPredictionsJson);
    final categoryPredictions = <String, double>{};
    if (rawMap is Map) {
      for (final entry in rawMap.entries) {
        final value = entry.value;
        if (value is num) {
          categoryPredictions[entry.key.toString()] = value.toDouble();
        }
      }
    }

    return PredictionEntity(
      predictedTotal: predictedTotal,
      currentTotal: currentTotal,
      lastMonthTotal: lastMonthTotal,
      dailyAverage: dailyAverage,
      projectedDailyAverage: projectedDailyAverage,
      trend: PredictionTrend.values.firstWhere(
        (value) => value.name == trend,
        orElse: () => PredictionTrend.stable,
      ),
      confidence: PredictionConfidence.values.firstWhere(
        (value) => value.name == confidence,
        orElse: () => PredictionConfidence.medium,
      ),
      categoryPredictions: categoryPredictions,
      aiInsight: aiInsight,
      generatedAt: generatedAt,
      currentDay: currentDay,
      daysInMonth: daysInMonth,
      daysRemaining: daysRemaining,
    );
  }

  static PredictionCacheModel fromEntity(PredictionEntity entity) {
    return PredictionCacheModel()
      ..id = 1
      ..predictedTotal = entity.predictedTotal
      ..currentTotal = entity.currentTotal
      ..lastMonthTotal = entity.lastMonthTotal
      ..dailyAverage = entity.dailyAverage
      ..projectedDailyAverage = entity.projectedDailyAverage
      ..trend = entity.trend.name
      ..confidence = entity.confidence.name
      ..categoryPredictionsJson = jsonEncode(entity.categoryPredictions)
      ..aiInsight = entity.aiInsight
      ..generatedAt = entity.generatedAt
      ..currentDay = entity.currentDay
      ..daysInMonth = entity.daysInMonth
      ..daysRemaining = entity.daysRemaining;
  }
}
