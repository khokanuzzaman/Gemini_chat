class BackupFileInfo {
  const BackupFileInfo({
    required this.fileId,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String fileId;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
}

class BackupUploadResult {
  const BackupUploadResult({
    required this.fileId,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  final String fileId;
  final int sizeBytes;
  final DateTime uploadedAt;
}

class BackupResult {
  const BackupResult({
    required this.success,
    this.timestamp,
    this.sizeBytes,
    this.errorMessage,
  });

  final bool success;
  final DateTime? timestamp;
  final int? sizeBytes;
  final String? errorMessage;
}

class RestoreResult {
  const RestoreResult({
    required this.success,
    this.timestamp,
    this.sizeBytes,
    this.errorMessage,
  });

  final bool success;
  final DateTime? timestamp;
  final int? sizeBytes;
  final String? errorMessage;
}
