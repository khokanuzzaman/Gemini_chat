import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';

abstract class OpenAiReceiptDataSource {
  TokenUsage? get latestTokenUsage;
  RateLimitSnapshot? get latestRateLimitSnapshot;

  Stream<String> parseReceipt(String extractedText);
}

class OpenAiReceiptDataSourceImpl implements OpenAiReceiptDataSource {
  OpenAiReceiptDataSourceImpl({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  TokenUsage? _latestTokenUsage;
  RateLimitSnapshot? _latestRateLimitSnapshot;

  @override
  TokenUsage? get latestTokenUsage => _latestTokenUsage;

  @override
  RateLimitSnapshot? get latestRateLimitSnapshot => _latestRateLimitSnapshot;

  @override
  Stream<String> parseReceipt(String extractedText) async* {
    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': ApiConstants.receiptSystemPrompt},
      {'role': 'user', 'content': extractedText},
    ];

    yield* _streamCompletion(messages);
  }

  Stream<String> _streamCompletion(List<Map<String, String>> messages) async* {
    final request = http.Request('POST', Uri.parse(ApiConstants.chatUrl));
    request.headers.addAll({
      HttpHeaders.authorizationHeader: 'Bearer ${ApiConstants.openAiApiKey}',
      HttpHeaders.contentTypeHeader: 'application/json',
    });
    request.body = jsonEncode({
      'model': ApiConstants.chatModel,
      'messages': messages,
      'stream': true,
      'stream_options': {'include_usage': true},
      'max_tokens': 500,
      'temperature': 0.1,
    });

    _latestTokenUsage = null;
    _latestRateLimitSnapshot = null;
    final buffer = StringBuffer();

    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      _latestRateLimitSnapshot = RateLimitSnapshot.tryParse(
        response.headers,
        source: 'receipt',
      );

      if (response.statusCode == 401) {
        throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
      }
      if (response.statusCode == 429) {
        throw const QuotaExceededException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw GeneralException(_extractErrorMessage(body));
      }

      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 30))) {
        final trimmedLine = line.trim();
        if (!trimmedLine.startsWith('data: ')) {
          continue;
        }
        if (trimmedLine == 'data: [DONE]') {
          continue;
        }

        final payload = trimmedLine.substring(6);
        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map<String, dynamic>) {
            continue;
          }

          _captureUsage(decoded);
          final content = _extractContent(decoded);
          if (content.isEmpty) {
            continue;
          }

          buffer.write(content);
          yield buffer.toString();
        } catch (_) {
          continue;
        }
      }

      if (buffer.isEmpty) {
        throw const GeneralException(AppStrings.openAiEmptyResponse);
      }

      _latestTokenUsage ??= _estimateTokenUsage(messages, buffer.toString());
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
    } catch (error) {
      throw GeneralException('$error');
    }
  }

  void _captureUsage(Map<String, dynamic> decoded) {
    final usage = decoded['usage'];
    if (usage is! Map<String, dynamic>) {
      return;
    }

    final promptTokens = usage['prompt_tokens'];
    final completionTokens = usage['completion_tokens'];
    final totalTokens = usage['total_tokens'];
    if (promptTokens is! int ||
        completionTokens is! int ||
        totalTokens is! int) {
      return;
    }

    _latestTokenUsage = TokenUsage(
      promptTokens: promptTokens,
      outputTokens: completionTokens,
      totalTokens: totalTokens,
    );
  }

  String _extractContent(Map<String, dynamic> decoded) {
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return '';
    }

    final choice = choices.first;
    if (choice is! Map<String, dynamic>) {
      return '';
    }

    final delta = choice['delta'];
    if (delta is! Map<String, dynamic>) {
      return '';
    }

    final content = delta['content'];
    return content is String ? content : '';
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } catch (_) {}

    return AppStrings.generalError;
  }

  TokenUsage _estimateTokenUsage(
    List<Map<String, String>> messages,
    String responseText,
  ) {
    var promptTokens = 0;
    for (final message in messages) {
      promptTokens += 6;
      promptTokens += _estimateTextTokens(message['content'] ?? '');
    }

    final outputTokens = _estimateTextTokens(responseText);
    return TokenUsage(
      promptTokens: promptTokens,
      outputTokens: outputTokens,
      totalTokens: promptTokens + outputTokens,
      isEstimated: true,
    );
  }

  int _estimateTextTokens(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 0;
    }

    final estimated = (trimmed.runes.length / 4).ceil();
    return estimated < 1 ? 1 : estimated;
  }
}
