import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../../../expense/domain/entities/expense_entity.dart';

abstract class BudgetPlannerDataSource {
  Stream<String> generateBudgetPlan({
    required double monthlyIncome,
    required List<ExpenseEntity> last3MonthsExpenses,
    required List<CategoryEntity> categories,
  });
}

class BudgetPlannerDataSourceImpl implements BudgetPlannerDataSource {
  BudgetPlannerDataSourceImpl({
    http.Client? client,
    ConnectivityService? connectivityService,
  }) : _client = client ?? http.Client(),
       _connectivityService = connectivityService ?? ConnectivityService();

  final http.Client _client;
  final ConnectivityService _connectivityService;

  @override
  Stream<String> generateBudgetPlan({
    required double monthlyIncome,
    required List<ExpenseEntity> last3MonthsExpenses,
    required List<CategoryEntity> categories,
  }) async* {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw const NoInternetException();
    }

    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final prompt =
        '''
User's monthly income: ৳${monthlyIncome.toStringAsFixed(0)}

Spending history (last 3 months average):
${_buildSpendingHistory(last3MonthsExpenses, categories)}

Available categories: ${categories.map((c) => c.name).join(', ')}

Create a realistic monthly budget plan for Bangladesh.
Follow 50/30/20 rule if possible:
- 50% needs (Food, Transport, Bill, Healthcare)
- 30% wants (Shopping, Entertainment)
- 20% savings

Return JSON first, then explanation:
{
  "categoryBudgets": {
    "Food": <amount>,
    "Transport": <amount>
  },
  "savings": <amount>,
  "totalBudgeted": <amount>,
  "savingsPercentage": <number>
}

Then write 2-3 sentences in Bengali explaining the plan.
''';

    yield* _streamCompletion(prompt, maxTokens: 900, temperature: 0.4);
  }

  String _buildSpendingHistory(
    List<ExpenseEntity> expenses,
    List<CategoryEntity> categories,
  ) {
    final totals = <String, double>{};
    for (final category in categories) {
      totals[category.name] = 0;
    }
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final buffer = StringBuffer();
    for (final entry in totals.entries) {
      final average = expenses.isEmpty ? 0.0 : entry.value / 3;
      buffer.writeln('- ${entry.key}: ৳${average.toStringAsFixed(0)}');
    }
    return buffer.toString().trim();
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
              'You are a careful financial planner for Bangladesh. Always respond in Bengali.',
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
          yield buffer.toString();
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
