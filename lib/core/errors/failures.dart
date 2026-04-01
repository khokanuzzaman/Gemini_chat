import '../constants/app_strings.dart';

sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = AppStrings.generalError]);
}

final class StorageFailure extends Failure {
  const StorageFailure([super.message = AppStrings.storageError]);
}

final class NoInternetFailure extends Failure {
  const NoInternetFailure([super.message = AppStrings.noInternet]);
}

final class InvalidApiKeyFailure extends Failure {
  const InvalidApiKeyFailure([super.message = AppStrings.apiKeyInvalid]);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = AppStrings.timeout]);
}

final class QuotaExceededFailure extends Failure {
  const QuotaExceededFailure([super.message = AppStrings.quotaExceeded]);
}

final class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure([super.message = AppStrings.recordingTooLong]);
}

final class TranscriptionFailedFailure extends Failure {
  const TranscriptionFailedFailure([
    super.message = AppStrings.transcriptionFailed,
  ]);
}

final class OcrFailedFailure extends Failure {
  const OcrFailedFailure([super.message = AppStrings.ocrFailed]);
}

final class GeneralFailure extends Failure {
  const GeneralFailure([super.message = AppStrings.generalError]);
}
