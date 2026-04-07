import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/budget_plan_entity.dart';

class BudgetPlannerDataSource {
  BudgetPlannerDataSource({
    http.Client? client,
    ConnectivityService? connectivityService,
  }) : _client = client ?? http.Client(),
       _connectivityService = connectivityService ?? ConnectivityService();

  final http.Client _client;
  final ConnectivityService _connectivityService;

  Stream<String> generateBudget({
    required double monthlyIncome,
    required Map<String, double> avgMonthlyByCategory,
    required List<String> availableCategories,
    required BudgetRule preferredRule,
  }) async* {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw const NoInternetException();
    }

    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final spendingHistory = avgMonthlyByCategory.entries
        .map(
          (entry) =>
              '${entry.key}: ৳${entry.value.toStringAsFixed(0)}/month avg',
        )
        .join('\n');

    final prompt =
        '''
Monthly income: ৳${monthlyIncome.toStringAsFixed(0)}

Current average monthly spending by category:
$spendingHistory

Available categories: ${availableCategories.join(', ')}

Budget rule to apply: ${preferredRule.label}
- ${preferredRule.description}

Create a realistic monthly budget for Bangladesh context.
Consider: rent, food costs, transport in Dhaka/Bangladesh.

Rules:
- Total budgeted amount MUST be less than income
- Savings must be at least 10% of income
- Each category gets a realistic amount
- Use only the available categories listed above

Return this JSON (raw, no markdown):
{
  "rule": "<fiftyThirtyTwenty/seventyTwentyTen/custom>",
  "categoryBudgets": {
    "<category>": <monthly amount>
  },
  "totalBudgeted": <number>,
  "savingsAmount": <number>,
  "savingsPercentage": <number>
}

After JSON, write in Bengali (3-4 sentences):
1. Summary of the plan
2. Which categories need attention
3. How to reach savings goal
4. One specific money-saving tip for Bangladesh
''';

    final request = http.Request('POST', Uri.parse(ApiConstants.chatUrl));
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Bearer $apiKey',
      HttpHeaders.contentTypeHeader: 'application/json',
    });
    request.body = jsonEncode({
      'model': ApiConstants.chatModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a financial advisor specializing in Bangladesh personal finance. '
              'Create practical, achievable budgets. Always return raw JSON first, then Bengali explanation.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'stream': true,
      'max_tokens': 800,
      'temperature': 0.4,
    });

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
        throw const GeneralException('Budget generation failed');
      }

      var hasContent = false;
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 30))) {
        if (!line.startsWith('data: ') || line.trim() == 'data: [DONE]') {
          continue;
        }

        try {
          final decoded = jsonDecode(line.substring(6)) as Map<String, dynamic>;
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
          hasContent = true;
          yield text;
        } catch (_) {
          continue;
        }
      }

      if (!hasContent) {
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
      throw const GeneralException('Budget generation failed');
    }
  }
}
