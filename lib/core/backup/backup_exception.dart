/// Coarse, PII-free cause of a backup failure. Safe to log and store; the
/// user-facing Bengali text lives in [BackupException.message].
enum BackupErrorCode {
  network('network'),
  auth('auth'),
  drive('drive'),
  unknown('unknown');

  const BackupErrorCode(this.key);
  final String key;

  static BackupErrorCode fromKey(String? key) {
    for (final code in values) {
      if (code.key == key) {
        return code;
      }
    }
    return BackupErrorCode.unknown;
  }
}

class BackupException implements Exception {
  const BackupException(
    this.message, {
    this.isRecoverable = true,
    this.code = BackupErrorCode.unknown,
  });

  final String message;
  final bool isRecoverable;
  final BackupErrorCode code;

  @override
  String toString() => message;
}
