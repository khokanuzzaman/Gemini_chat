import 'package:flutter/foundation.dart';

/// Lightweight app logger.
///
/// Silent in release builds — every call is guarded by [kDebugMode], so unlike
/// `debugPrint` (which still logs in release, only throttled) these produce no
/// output in a release build.
///
/// Logging rules — this is a finance app, treat logs as untrusted output:
/// - NEVER log financial amounts, balances, SMS content, tokens, API keys, or
///   any other sensitive value — not even in debug.
/// - Avoid logging raw auth/account error objects in a way that could surface
///   PII (emails, account ids). Log the event and a short cause, not the whole
///   payload.
class AppLogger {
  const AppLogger._();

  /// A debug-only diagnostic message.
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// A debug-only error diagnostic. [error] / [stackTrace] are appended when
  /// provided. Keep the message a short cause — do not pass sensitive values.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(error == null ? message : '$message: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
