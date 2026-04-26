class BackupException implements Exception {
  const BackupException(this.message, {this.isRecoverable = true});

  final String message;
  final bool isRecoverable;

  @override
  String toString() => message;
}
