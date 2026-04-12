// Feature: Prediction
// Layer: Data

import 'package:isar/isar.dart';

import '../../../expense/domain/entities/expense_entity.dart';
import '../../domain/entities/prediction_entity.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../datasources/prediction_datasource.dart';
import '../models/prediction_cache_model.dart';

class PredictionRepositoryImpl implements PredictionRepository {
  const PredictionRepositoryImpl({
    required PredictionDataSource remoteDataSource,
    required Isar isar,
  }) : _remoteDataSource = remoteDataSource,
       _isar = isar;

  final PredictionDataSource _remoteDataSource;
  final Isar _isar;

  @override
  Stream<String> getPrediction({
    required List<ExpenseEntity> thisMonthExpenses,
    required List<ExpenseEntity> lastMonthExpenses,
    required int currentDay,
    required int daysInMonth,
  }) {
    return _remoteDataSource.predict(
      thisMonthExpenses: thisMonthExpenses,
      lastMonthExpenses: lastMonthExpenses,
      currentDay: currentDay,
      daysInMonth: daysInMonth,
    );
  }

  @override
  Future<PredictionEntity?> getCachedPrediction() async {
    final cached = await _isar.predictionCacheModels.get(1);
    return cached?.toEntity();
  }

  @override
  Future<void> savePrediction(PredictionEntity prediction) async {
    final model = PredictionCacheModel.fromEntity(prediction);
    await _isar.writeTxn(() async {
      await _isar.predictionCacheModels.put(model);
    });
  }

  @override
  Future<void> clearCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.predictionCacheModels.clear();
      });
    } catch (_) {
      // Silent fail — cache clearing is non-critical
    }
  }

  @override
  Future<bool> shouldRefreshPrediction() async {
    final cached = await getCachedPrediction();
    if (cached == null) {
      return true;
    }

    final now = DateTime.now();
    if (cached.generatedAt.year != now.year ||
        cached.generatedAt.month != now.month ||
        cached.generatedAt.day != now.day) {
      return true;
    }

    return now.difference(cached.generatedAt) > const Duration(hours: 6);
  }
}
