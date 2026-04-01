import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/ai/rate_limit_snapshot.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/exceptions.dart';

abstract class OpenAiVoiceDataSource {
  RateLimitSnapshot? get latestRateLimitSnapshot;

  Future<String> transcribeAudio(String audioFilePath);
}

class OpenAiVoiceDataSourceImpl implements OpenAiVoiceDataSource {
  OpenAiVoiceDataSourceImpl({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  RateLimitSnapshot? _latestRateLimitSnapshot;

  @override
  RateLimitSnapshot? get latestRateLimitSnapshot => _latestRateLimitSnapshot;

  @override
  Future<String> transcribeAudio(String audioFilePath) async {
    final apiKey = ApiConstants.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw const GeneralException(AppStrings.recordingFileMissing);
    }

    final bytes = await file.readAsBytes();
    final fileSize = await file.length();

    if (fileSize > 25 * 1024 * 1024) {
      throw const FileTooLargeException(AppStrings.recordingTooLong);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.voiceUrl),
    );
    request.headers[HttpHeaders.authorizationHeader] =
        'Bearer ${ApiConstants.openAiApiKey}';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'voice.m4a',
        contentType: MediaType('audio', 'm4a'),
      ),
    );
    request.fields['model'] = ApiConstants.voiceModel;
    request.fields['prompt'] =
        'The speaker may use Bengali or Bangla words about personal finance. '
        'If the speech is Bengali, prefer Bengali script, not Hindi or '
        'Devanagari transliteration. Common words include nasta, bhara, taka, '
        'khoroch, bill, bazar, doctor, lunch, dinner, rickshaw, shopping, '
        'internet bill, bidyut bill, oshudh, mach, mangsho, and sobji. '
        'The speaker may mention multiple expenses in one sentence, numbered '
        'lists, or a date followed by several items. Dates and month names '
        'matter. Recognize forms like 2/02/2026, 2-2-2026, Feb 2 2026, '
        'March 2025, 03/2025, 2025-03, ১ মার্চ, ২০২৫ সালের ফেব্রুয়ারি, '
        'গতকাল, পরশু, গত সোমবার, last Monday, and গত সপ্তাহে. Keep numbers '
        'and dates exact. Preserve expense words faithfully in the original '
        'language without summarizing.';
    request.fields['response_format'] = 'text';
    _latestRateLimitSnapshot = null;

    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      _latestRateLimitSnapshot = RateLimitSnapshot.tryParse(
        response.headers,
        source: 'voice',
      );
      final text = await response.stream.bytesToString();

      if (response.statusCode == 401) {
        throw const InvalidApiKeyException(AppStrings.apiKeyInvalidWithEnv);
      }
      if (response.statusCode == 429) {
        throw const QuotaExceededException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeneralException(text.trim().isEmpty ? null : text.trim());
      }

      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        throw const TranscriptionFailedException(
          AppStrings.transcriptionFailed,
        );
      }

      return trimmed;
    } on SocketException {
      throw const NoInternetException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on InvalidApiKeyException {
      rethrow;
    } on QuotaExceededException {
      rethrow;
    } on FileTooLargeException {
      rethrow;
    } on TranscriptionFailedException {
      rethrow;
    } on GeneralException {
      rethrow;
    } catch (error) {
      throw GeneralException('$error');
    }
  }
}
