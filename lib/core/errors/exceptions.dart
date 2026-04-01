import '../constants/app_strings.dart';

class NoInternetException implements Exception {
  const NoInternetException();
}

class InvalidApiKeyException implements Exception {
  const InvalidApiKeyException([this.message = AppStrings.apiKeyInvalid]);

  final String message;

  @override
  String toString() => message;
}

class RequestTimeoutException implements Exception {
  const RequestTimeoutException([this.message = AppStrings.timeout]);

  final String message;

  @override
  String toString() => message;
}

class QuotaExceededException implements Exception {
  const QuotaExceededException();
}

class FileTooLargeException implements Exception {
  const FileTooLargeException([this.message = AppStrings.recordingTooLong]);

  final String message;

  @override
  String toString() => message;
}

class TranscriptionFailedException implements Exception {
  const TranscriptionFailedException([
    this.message = AppStrings.transcriptionFailed,
  ]);

  final String message;

  @override
  String toString() => message;
}

class OcrFailedException implements Exception {
  const OcrFailedException([this.message = AppStrings.ocrFailed]);

  final String message;

  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'PermissionDeniedException';
}

class GeneralException implements Exception {
  const GeneralException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'GeneralException';
}
