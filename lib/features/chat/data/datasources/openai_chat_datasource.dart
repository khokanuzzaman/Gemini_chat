import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/ai/prompt_builder.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/ai/rag_prompt_builder.dart';
import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/ai/token_usage.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../../domain/entities/message_entity.dart';

abstract class OpenAiChatDataSource {
  TokenUsage? get latestTokenUsage;
  RateLimitSnapshot? get latestRateLimitSnapshot;

  Stream<String> sendMessage(
    List<MessageEntity> history,
    String newMessage, {
    String? ragContext,
  });
}

class OpenAiChatDataSourceImpl implements OpenAiChatDataSource {
  OpenAiChatDataSourceImpl({
    http.Client? client,
    ConnectivityService? connectivityService,
    Future<List<CategoryEntity>> Function()? categoryLoader,
  }) : _client = client ?? http.Client(),
       _connectivityService = connectivityService ?? ConnectivityService(),
       _categoryLoader = categoryLoader;

  final http.Client _client;
  final ConnectivityService _connectivityService;
  final Future<List<CategoryEntity>> Function()? _categoryLoader;

  TokenUsage? _latestTokenUsage;
  RateLimitSnapshot? _latestRateLimitSnapshot;

  @override
  TokenUsage? get latestTokenUsage => _latestTokenUsage;

  @override
  RateLimitSnapshot? get latestRateLimitSnapshot => _latestRateLimitSnapshot;

  @override
  Stream<String> sendMessage(
    List<MessageEntity> history,
    String newMessage, {
    String? ragContext,
  }) async* {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw const NoInternetException();
    }

    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final messages = _buildMessages(
      history,
      newMessage,
      systemPrompt: await _buildSystemPrompt(),
      ragContext: ragContext,
    );
    if (ragContext != null) {
      yield '[RAG]';
    }
    yield* _streamCompletion(
      messages: messages,
      maxTokens: 1024,
      temperature: 0.7,
    );
  }

  List<Map<String, String>> _buildMessages(
    List<MessageEntity> history,
    String newMessage, {
    required String systemPrompt,
    String? ragContext,
  }) {
    final latestText = ragContext != null
        ? RagPromptBuilder.build(newMessage, ragContext)
        : RagPromptBuilder.buildWithoutData(newMessage);

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            '$systemPrompt\n\nআজকের তারিখ: ${_formatIsoDate(DateTime.now())}. Relative date convert করতে এই তারিখ use করুন.',
      },
    ];

    for (final message in history) {
      if (message.isError) {
        continue;
      }

      messages.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
      });
    }

    messages.add({'role': 'user', 'content': latestText});
    return messages;
  }

  Future<String> _buildSystemPrompt() async {
    try {
      final categories = await _categoryLoader?.call();
      if (categories != null && categories.isNotEmpty) {
        return PromptBuilder.buildChatSystemPrompt(categories);
      }
    } catch (_) {}
    return PromptBuilder.buildChatSystemPrompt(const []);
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Stream<String> _streamCompletion({
    required List<Map<String, String>> messages,
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
      'messages': messages,
      'stream': true,
      'stream_options': {'include_usage': true},
      'max_tokens': maxTokens,
      'temperature': temperature,
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
        source: 'chat',
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
    if (content is String) {
      return content;
    }

    if (content is List) {
      final buffer = StringBuffer();
      for (final part in content) {
        if (part is Map<String, dynamic> && part['text'] is String) {
          buffer.write(part['text'] as String);
        }
      }
      return buffer.toString();
    }

    return '';
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
