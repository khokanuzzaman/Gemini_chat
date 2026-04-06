// Feature: Prediction
// Layer: Data

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../expense/domain/entities/expense_entity.dart';

abstract class PredictionDataSource {
  Stream<String> predict({
    required List<ExpenseEntity> thisMonthExpenses,
    required List<ExpenseEntity> lastMonthExpenses,
    required int currentDay,
    required int daysInMonth,
  });
}

class PredictionDataSourceImpl implements PredictionDataSource {
  PredictionDataSourceImpl({
    http.Client? client,
    ConnectivityService? connectivityService,
  }) : _client = client ?? http.Client(),
       _connectivityService = connectivityService ?? ConnectivityService();

  final http.Client _client;
  final ConnectivityService _connectivityService;

  @override
  Stream<String> predict({
    required List<ExpenseEntity> thisMonthExpenses,
    required List<ExpenseEntity> lastMonthExpenses,
    required int currentDay,
    required int daysInMonth,
  }) async* {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw const NoInternetException();
    }

    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final thisMonthTotal = _total(thisMonthExpenses);
    final lastMonthTotal = _total(lastMonthExpenses);
    final thisMonthDaily = currentDay == 0 ? 0.0 : thisMonthTotal / currentDay;
    final lastMonthDaily = daysInMonth == 0
        ? 0.0
        : lastMonthTotal / daysInMonth;
    final categoryMap = <String, double>{};
    for (final expense in thisMonthExpenses) {
      categoryMap.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final categoryText = categoryMap.entries
        .map((entry) => '${entry.key}: ৳${entry.value.toStringAsFixed(0)}')
        .join(', ');

    final prompt =
        '''
Today is day $currentDay of $daysInMonth in this month.
Days remaining: ${daysInMonth - currentDay}

This month so far:
Total: ৳${thisMonthTotal.toStringAsFixed(0)}
Daily average: ৳${thisMonthDaily.toStringAsFixed(0)}/day
By category: ${categoryText.isEmpty ? 'কোনো খরচ নেই' : categoryText}

Last month total: ৳${lastMonthTotal.toStringAsFixed(0)}
Last month daily average: ৳${lastMonthDaily.toStringAsFixed(0)}/day

Predict this month's total expense.
Consider: current pace, last month pattern, day of month.

Return this JSON first (no markdown, raw JSON only):
{
  "predictedTotal": <number>,
  "confidence": "<low/medium/high>",
  "trend": "<increasing/decreasing/stable>",
  "projectedDailyAverage": <number>,
  "categoryPredictions": {
    "<category>": <predicted monthly total>
  },
  "reasoning": "<one sentence in Bengali>"
}

After JSON, write 2-3 sentences in Bengali:
- What is the prediction
- Why (based on current pace)
- One specific actionable tip to save money
''';

    yield* _streamCompletion(prompt, maxTokens: 600, temperature: 0.3);
  }

  double _total(List<ExpenseEntity> expenses) {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  Stream<String> _streamCompletion(
    String prompt, {
    required int maxTokens,
    required double temperature,
  }) async* {
    final request = http.Request('POST', Uri.parse(ApiConstants.chatUrl));
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Bearer ${ApiConstants.openAiApiKey}',
      HttpHeaders.contentTypeHeader: 'application/json',
    });
    request.body = jsonEncode({
      'model': ApiConstants.chatModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a financial forecasting assistant for Bangladesh. Always answer in Bengali.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'stream': true,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final buffer = StringBuffer();

    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
      }
      if (response.statusCode == 429) {
        throw const QuotaExceededException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const GeneralException(AppStrings.generalError);
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 30))) {
        if (!line.startsWith('data: ') || line.trim() == 'data: [DONE]') {
          continue;
        }
        final payload = line.substring(6);
        try {
          final decoded = jsonDecode(payload) as Map<String, dynamic>;
          final choices = decoded['choices'];
          if (choices is! List || choices.isEmpty) {
            continue;
          }
          final delta = (choices.first as Map<String, dynamic>)['delta'];
          if (delta is! Map<String, dynamic>) {
            continue;
          }
          final content = delta['content'];
          final text = switch (content) {
            String value => value,
            List value =>
              value
                  .whereType<Map<String, dynamic>>()
                  .map((part) => part['text'])
                  .whereType<String>()
                  .join(),
            _ => '',
          };
          if (text.isEmpty) {
            continue;
          }
          buffer.write(text);
          yield text;
        } catch (_) {
          continue;
        }
      }

      if (buffer.isEmpty) {
        throw const GeneralException(AppStrings.openAiEmptyResponse);
      }
    } on SocketException {
      throw const NoInternetException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on InvalidApiKeyException {
      rethrow;
    } on QuotaExceededException {
      rethrow;
    } on GeneralException {
      rethrow;
    } catch (_) {
      throw const GeneralException(AppStrings.generalError);
    }
  }
}
