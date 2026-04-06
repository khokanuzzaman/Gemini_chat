// Feature: Prediction
// Layer: Domain

import '../../../expense/domain/entities/expense_entity.dart';
import '../entities/prediction_entity.dart';
import '../repositories/prediction_repository.dart';

sealed class PredictionLoadResult {
  const PredictionLoadResult();
}

class CachedPredictionResult extends PredictionLoadResult {
  const CachedPredictionResult(this.prediction);

  final PredictionEntity prediction;
}

class StreamingPredictionResult extends PredictionLoadResult {
  const StreamingPredictionResult(this.stream);

  final Stream<String> stream;
}

class GetPredictionUseCase {
  const GetPredictionUseCase(this._repository);

  final PredictionRepository _repository;

  Future<PredictionLoadResult> call({
    required List<ExpenseEntity> thisMonthExpenses,
    required List<ExpenseEntity> lastMonthExpenses,
    required int currentDay,
    required int daysInMonth,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _repository.getCachedPrediction();
      final shouldRefresh = await _repository.shouldRefreshPrediction();
      if (cached != null && !shouldRefresh) {
        return CachedPredictionResult(cached);
      }
    }

    return StreamingPredictionResult(
      _repository.getPrediction(
        thisMonthExpenses: thisMonthExpenses,
        lastMonthExpenses: lastMonthExpenses,
        currentDay: currentDay,
        daysInMonth: daysInMonth,
      ),
    );
  }
}
