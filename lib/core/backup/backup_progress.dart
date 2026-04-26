enum BackupOperationKind { backup, restore }

enum BackupProgressStage {
  preparing,
  exporting,
  compressing,
  encrypting,
  uploading,
  downloading,
  decrypting,
  decoding,
  importing,
  finalizing,
  completed,
  failed,
}

class BackupProgressState {
  const BackupProgressState({
    required this.operation,
    required this.stage,
    required this.currentStep,
    required this.totalSteps,
    required this.overallProgress,
    required this.startedAt,
    required this.isBlocking,
    this.processedBytes,
    this.totalBytes,
  });

  final BackupOperationKind operation;
  final BackupProgressStage stage;
  final int currentStep;
  final int totalSteps;
  final double overallProgress;
  final int? processedBytes;
  final int? totalBytes;
  final DateTime startedAt;
  final bool isBlocking;

  bool get hasByteProgress =>
      processedBytes != null &&
      totalBytes != null &&
      totalBytes! > 0 &&
      processedBytes! >= 0;

  double get clampedOverallProgress => overallProgress.clamp(0.0, 1.0);

  BackupProgressState copyWith({
    BackupOperationKind? operation,
    BackupProgressStage? stage,
    int? currentStep,
    int? totalSteps,
    double? overallProgress,
    Object? processedBytes = _backupProgressUnset,
    Object? totalBytes = _backupProgressUnset,
    DateTime? startedAt,
    bool? isBlocking,
  }) {
    return BackupProgressState(
      operation: operation ?? this.operation,
      stage: stage ?? this.stage,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      overallProgress: overallProgress ?? this.overallProgress,
      processedBytes: processedBytes == _backupProgressUnset
          ? this.processedBytes
          : processedBytes as int?,
      totalBytes: totalBytes == _backupProgressUnset
          ? this.totalBytes
          : totalBytes as int?,
      startedAt: startedAt ?? this.startedAt,
      isBlocking: isBlocking ?? this.isBlocking,
    );
  }
}

const _backupProgressUnset = Object();
