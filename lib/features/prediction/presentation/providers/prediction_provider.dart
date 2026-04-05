import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/json_block_extractor.dart';
import '../../../../core/notifications/budget_settings.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../data/datasources/prediction_datasource.dart';
import '../../domain/entities/expense_prediction_entity.dart';

final predictionDataSourceProvider = Provider<PredictionDataSource>((ref) {
  return PredictionDataSourceImpl();
});

final predictionProvider =
    AsyncNotifierProvider<PredictionNotifier, ExpensePredictionEntity?>(
      PredictionNotifier.new,
    );

class PredictionNotifier extends AsyncNotifier<ExpensePredictionEntity?> {
  static const _cacheKey = 'prediction_cache_v1';
  static const _cacheMonthKey = 'prediction_cache_month_v1';

  @override
  Future<ExpensePredictionEntity?> build() async {
    return null;
  }

  Future<void> loadForMonth(DateTime month, {bool forceRefresh = false}) async {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final targetMonth = DateTime(month.year, month.month, 1);
    if (targetMonth != currentMonth) {
      state = const AsyncData(null);
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    final cacheMonth = prefs.getString(_cacheMonthKey);
    final cachedValue = prefs.getString(_cacheKey);
    final now = DateTime.now();
    if (!forceRefresh &&
        cacheMonth == '${month.year}-${month.month}' &&
        cachedValue != null) {
      final decoded = jsonDecode(cachedValue);
      if (decoded is Map<String, dynamic>) {
        final cached = ExpensePredictionEntity.fromJson(decoded);
        if (now.difference(cached.generatedAt) < const Duration(hours: 6)) {
          state = AsyncData(cached);
          return;
        }
      }
    }

    state = const AsyncLoading();

    final thisMonthExpenses = await ref
        .read(expenseRepositoryProvider)
        .getExpensesForMonth(month);
    final lastMonth = month.month == 1
        ? DateTime(month.year - 1, 12, 1)
        : DateTime(month.year, month.month - 1, 1);
    final lastMonthExpenses = await ref
        .read(expenseRepositoryProvider)
        .getExpensesForMonth(lastMonth);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final currentDay = DateTime.now().day;
    final totalBudget = ref.read(budgetProvider).totalBudget;

    String latestResponse = '';
    await for (final chunk
        in ref
            .read(predictionDataSourceProvider)
            .predictMonthlyExpense(
              thisMonthSoFar: thisMonthExpenses,
              lastMonthExpenses: lastMonthExpenses,
              currentDay: currentDay,
              daysInMonth: daysInMonth,
              totalBudget: totalBudget,
            )) {
      latestResponse = chunk;
    }

    final prediction = _parsePrediction(latestResponse);
    if (prediction == null) {
      state = const AsyncData(null);
      return;
    }

    await prefs.setString(_cacheMonthKey, '${month.year}-${month.month}');
    await prefs.setString(_cacheKey, jsonEncode(prediction.toJson()));
    state = AsyncData(prediction);
  }

  ExpensePredictionEntity? _parsePrediction(String response) {
    final jsonBlock = JsonBlockExtractor.extractFirstObject(response);
    if (jsonBlock == null) {
      return null;
    }
    final explanation = JsonBlockExtractor.removeFirstBlock(
      response,
      jsonBlock,
    );
    try {
      final decoded = jsonDecode(jsonBlock);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ExpensePredictionEntity.fromJson({
        ...decoded,
        'explanation': explanation,
        'generatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      return null;
    }
  }
}
