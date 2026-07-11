// Feature: Prediction
// Layer: Presentation

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/json_block_extractor.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../expense/data/repositories/expense_repository_impl.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../../data/datasources/prediction_datasource.dart';
import '../../data/repositories/prediction_repository_impl.dart';
import '../../domain/entities/prediction_entity.dart';
import '../../domain/repositories/prediction_repository.dart';
import '../../domain/usecases/get_prediction_usecase.dart';

/// Incremented whenever expense data changes in a way that could affect
/// end-of-month prediction accuracy. Watched by predictionProvider and
/// the RAG context builder to trigger prediction invalidation.
final predictionRefreshTokenProvider = StateProvider<int>((ref) => 0);

final predictionDataSourceProvider = Provider<PredictionDataSource>((ref) {
  return PredictionDataSourceImpl(
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final predictionExpenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    localDataSource: ref.watch(expenseLocalDataSourceProvider),
  );
});

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepositoryImpl(
    remoteDataSource: ref.watch(predictionDataSourceProvider),
    isar: ref.watch(isarProvider),
  );
});

final getPredictionUseCaseProvider = Provider<GetPredictionUseCase>((ref) {
  return GetPredictionUseCase(ref.watch(predictionRepositoryProvider));
});

class PredictionState {
  const PredictionState({
    this.prediction,
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingText = '',
    this.error,
    this.fromCache = false,
    this.isStale = false,
  });

  const PredictionState.initial() : this();

  final PredictionEntity? prediction;
  final bool isLoading;
  final bool isStreaming;
  final String streamingText;
  final String? error;
  final bool fromCache;
  final bool isStale;

  PredictionState copyWith({
    PredictionEntity? prediction,
    bool clearPrediction = false,
    bool? isLoading,
    bool? isStreaming,
    String? streamingText,
    String? error,
    bool clearError = false,
    bool? fromCache,
    bool? isStale,
  }) {
    return PredictionState(
      prediction: clearPrediction ? null : prediction ?? this.prediction,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : error ?? this.error,
      fromCache: fromCache ?? this.fromCache,
      isStale: isStale ?? this.isStale,
    );
  }
}

final predictionProvider =
    NotifierProvider<PredictionNotifier, PredictionState>(
      PredictionNotifier.new,
    );

class PredictionNotifier extends Notifier<PredictionState> {
  static const _expensesSincePredictKey = 'expenses_since_predict';
  int? _lastSeenRefreshToken;
  PredictionEntity? _cachedPrediction;
  String? _cachedError;

  @override
  PredictionState build() {
    final refreshToken = ref.watch(predictionRefreshTokenProvider);

    if (_lastSeenRefreshToken == null) {
      _lastSeenRefreshToken = refreshToken;
      Future.microtask(_loadCachedPrediction);
      return const PredictionState.initial();
    }

    if (_lastSeenRefreshToken != refreshToken) {
      _lastSeenRefreshToken = refreshToken;
      return PredictionState(
        prediction: _cachedPrediction,
        isLoading: false,
        error: _cachedError,
        isStale: true,
      );
    }

    return PredictionState(
      prediction: _cachedPrediction,
      isLoading: false,
      error: _cachedError,
      isStale: false,
    );
  }

  Future<void> loadPrediction({bool forceRefresh = false}) async {
    if (state.isLoading || state.isStreaming) {
      return;
    }

    final refreshTokenAtStart = ref.read(predictionRefreshTokenProvider);
    final repository = ref.read(predictionRepositoryProvider);
    final connectivityService = ref.read(connectivityServiceProvider);
    final isConnected = await connectivityService.isConnected();
    final shouldForceRefresh = forceRefresh || state.isStale;

    if (!isConnected) {
      final cached = await repository.getCachedPrediction();
      _cachedPrediction = cached;
      _cachedError = 'ইন্টারনেট নেই — prediction আপডেট করা যাচ্ছে না';
      state = state.copyWith(
        prediction: cached,
        isLoading: false,
        isStreaming: false,
        streamingText: '',
        error: _cachedError,
        fromCache: cached != null,
        isStale: false,
      );
      return;
    }

    if (!shouldForceRefresh) {
      final shouldRefresh = await repository.shouldRefreshPrediction();
      if (!shouldRefresh) {
        final cached = await repository.getCachedPrediction();
        if (cached != null) {
          _cachedPrediction = cached;
          _cachedError = null;
          state = state.copyWith(
            prediction: cached,
            isLoading: false,
            isStreaming: false,
            streamingText: '',
            fromCache: true,
            clearError: true,
            isStale: false,
          );
          return;
        }
      }
    }

    _cachedError = null;
    state = state.copyWith(
      isLoading: true,
      isStreaming: false,
      streamingText: '',
      fromCache: false,
      clearError: true,
      isStale: false,
    );

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

      final expenseRepository = ref.read(predictionExpenseRepositoryProvider);
      final thisMonth = await expenseRepository.getExpensesByDateRange(
        startOfMonth,
        now,
      );
      final lastMonth = await expenseRepository.getExpensesByDateRange(
        startOfLastMonth,
        endOfLastMonth,
      );
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

      final loadResult = await ref
          .read(getPredictionUseCaseProvider)
          .call(
            thisMonthExpenses: thisMonth,
            lastMonthExpenses: lastMonth,
            currentDay: now.day,
            daysInMonth: daysInMonth,
            forceRefresh: shouldForceRefresh,
          );

      if (loadResult case CachedPredictionResult(:final prediction)) {
        if (ref.read(predictionRefreshTokenProvider) != refreshTokenAtStart) {
          state = state.copyWith(
            isLoading: false,
            isStreaming: false,
            streamingText: '',
            fromCache: false,
            isStale: true,
          );
          return;
        }
        _cachedPrediction = prediction;
        _cachedError = null;
        state = state.copyWith(
          prediction: prediction,
          isLoading: false,
          isStreaming: false,
          streamingText: '',
          fromCache: true,
          clearError: true,
          isStale: false,
        );
        return;
      }

      _cachedError = null;
      state = state.copyWith(
        isLoading: false,
        isStreaming: true,
        streamingText: '',
        fromCache: false,
      );

      var fullResponse = '';
      final stream = (loadResult as StreamingPredictionResult).stream;
      await for (final chunk in stream) {
        fullResponse += chunk;
        state = state.copyWith(streamingText: fullResponse);
      }

      if (ref.read(predictionRefreshTokenProvider) != refreshTokenAtStart) {
        state = state.copyWith(
          isLoading: false,
          isStreaming: false,
          streamingText: '',
          fromCache: false,
          isStale: true,
        );
        return;
      }

      final entity = _parseResponse(
        fullResponse,
        thisMonth,
        lastMonth,
        now,
        daysInMonth,
      );
      await repository.savePrediction(entity);
      _cachedPrediction = entity;
      _cachedError = null;
      state = state.copyWith(
        prediction: entity,
        isLoading: false,
        isStreaming: false,
        streamingText: '',
        fromCache: false,
        clearError: true,
        isStale: false,
      );
    } catch (_) {
      final cached = await repository.getCachedPrediction();
      _cachedPrediction = cached;
      _cachedError = 'Prediction করতে সমস্যা হয়েছে';
      state = state.copyWith(
        prediction: cached,
        isLoading: false,
        isStreaming: false,
        streamingText: '',
        error: _cachedError,
        fromCache: cached != null,
        isStale: false,
      );
    }
  }

  Future<void> registerExpenseSaves(int count) async {
    if (count <= 0) {
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final currentCount = prefs.getInt(_expensesSincePredictKey) ?? 0;
    final nextCount = currentCount + count;
    if (nextCount >= 10) {
      await prefs.setInt(_expensesSincePredictKey, 0);
      unawaited(loadPrediction(forceRefresh: true));
      return;
    }
    await prefs.setInt(_expensesSincePredictKey, nextCount);
  }

  Future<PredictionEntity?> getCachedPrediction() {
    return ref.read(predictionRepositoryProvider).getCachedPrediction();
  }

  Future<void> reset() async {
    try {
      final repository = ref.read(predictionRepositoryProvider);
      await repository.clearCache();
    } catch (_) {}

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_expensesSincePredictKey);
    } catch (_) {}

    _lastSeenRefreshToken = null;
    _cachedPrediction = null;
    _cachedError = null;
    state = const PredictionState.initial();
  }

  Future<void> _loadCachedPrediction() async {
    try {
      if (state.isLoading || state.isStreaming) {
        return;
      }

      final cached = await ref
          .read(predictionRepositoryProvider)
          .getCachedPrediction();
      if (cached == null) {
        return;
      }

      _cachedPrediction = cached;
      _cachedError = null;
      state = state.copyWith(
        prediction: cached,
        isLoading: false,
        isStreaming: false,
        streamingText: '',
        fromCache: true,
        clearError: true,
        isStale: false,
      );
    } catch (_) {}
  }

  PredictionEntity _parseResponse(
    String response,
    List<ExpenseEntity> thisMonth,
    List<ExpenseEntity> lastMonth,
    DateTime now,
    int daysInMonth,
  ) {
    final jsonBlock = JsonBlockExtractor.extractFirstObject(response);
    final insight = JsonBlockExtractor.removeFirstBlock(response, jsonBlock);
    final thisMonthTotal = _sumExpenses(thisMonth);
    final lastMonthTotal = _sumExpenses(lastMonth);
    final dailyAverage = now.day == 0 ? 0.0 : thisMonthTotal / now.day;
    final fallbackPredictedTotal = now.day == 0
        ? thisMonthTotal
        : dailyAverage * daysInMonth;
    final fallbackTrend = _fallbackTrend(dailyAverage, lastMonthTotal, now.day);
    final fallbackConfidence = _confidenceForDay(now.day);
    final fallbackCategoryPredictions = _fallbackCategoryPredictions(
      thisMonth,
      fallbackPredictedTotal,
      thisMonthTotal,
    );

    var predictedTotal = fallbackPredictedTotal;
    var trend = fallbackTrend;
    var confidence = fallbackConfidence;
    var projectedDailyAverage = predictedTotal / daysInMonth;
    var categoryPredictions = fallbackCategoryPredictions;
    var reasoning = '';

    if (jsonBlock != null) {
      try {
        final decoded = jsonDecode(jsonBlock);
        if (decoded is Map<String, dynamic>) {
          predictedTotal =
              (decoded['predictedTotal'] as num?)?.toDouble() ?? predictedTotal;
          projectedDailyAverage =
              (decoded['projectedDailyAverage'] as num?)?.toDouble() ??
              projectedDailyAverage;
          trend = PredictionTrend.values.firstWhere(
            (value) => value.name == decoded['trend'],
            orElse: () => trend,
          );
          confidence = PredictionConfidence.values.firstWhere(
            (value) => value.name == decoded['confidence'],
            orElse: () => confidence,
          );
          reasoning = decoded['reasoning']?.toString() ?? '';

          final rawCategoryPredictions = decoded['categoryPredictions'];
          if (rawCategoryPredictions is Map) {
            final parsedCategoryPredictions = <String, double>{};
            for (final entry in rawCategoryPredictions.entries) {
              final value = entry.value;
              if (value is num) {
                parsedCategoryPredictions[entry.key.toString()] = value
                    .toDouble();
              }
            }
            if (parsedCategoryPredictions.isNotEmpty) {
              categoryPredictions = parsedCategoryPredictions;
            }
          }
        }
      } catch (_) {}
    }

    return PredictionEntity(
      predictedTotal: predictedTotal,
      currentTotal: thisMonthTotal,
      lastMonthTotal: lastMonthTotal,
      dailyAverage: dailyAverage,
      projectedDailyAverage: projectedDailyAverage,
      trend: trend,
      confidence: confidence,
      categoryPredictions: categoryPredictions,
      aiInsight: insight.isNotEmpty ? insight : reasoning,
      generatedAt: DateTime.now(),
      currentDay: now.day,
      daysInMonth: daysInMonth,
      daysRemaining: daysInMonth - now.day,
    );
  }

  double _sumExpenses(List<ExpenseEntity> expenses) {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  PredictionTrend _fallbackTrend(
    double thisMonthDailyAverage,
    double lastMonthTotal,
    int currentDay,
  ) {
    if (currentDay <= 0) {
      return PredictionTrend.stable;
    }
    final lastMonthDailyAverage = lastMonthTotal <= 0
        ? 0.0
        : lastMonthTotal / 30;
    if (lastMonthDailyAverage <= 0) {
      return PredictionTrend.stable;
    }
    final ratio = thisMonthDailyAverage / lastMonthDailyAverage;
    if (ratio >= 1.1) {
      return PredictionTrend.increasing;
    }
    if (ratio <= 0.9) {
      return PredictionTrend.decreasing;
    }
    return PredictionTrend.stable;
  }

  PredictionConfidence _confidenceForDay(int day) {
    if (day <= 7) {
      return PredictionConfidence.low;
    }
    if (day <= 20) {
      return PredictionConfidence.medium;
    }
    return PredictionConfidence.high;
  }

  Map<String, double> _fallbackCategoryPredictions(
    List<ExpenseEntity> thisMonth,
    double predictedTotal,
    double currentTotal,
  ) {
    final totals = <String, double>{};
    for (final expense in thisMonth) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    if (totals.isEmpty || currentTotal <= 0) {
      return const {};
    }

    final scale = predictedTotal / currentTotal;
    return totals.map((key, value) => MapEntry(key, value * scale));
  }
}
