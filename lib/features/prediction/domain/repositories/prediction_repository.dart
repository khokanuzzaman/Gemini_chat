// Feature: Prediction
// Layer: Domain

import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/prediction_entity.dart';

abstract class PredictionRepository {
  Stream<String> getPrediction({
    required List<ExpenseEntity> thisMonthExpenses,
    required List<ExpenseEntity> lastMonthExpenses,
    required int currentDay,
    required int daysInMonth,
  });

  Future<PredictionEntity?> getCachedPrediction();

  Future<void> savePrediction(PredictionEntity prediction);

  Future<void> clearCache();

  Future<bool> shouldRefreshPrediction();
}
