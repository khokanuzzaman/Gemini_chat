class MutationResult {
  const MutationResult._({
    required this.isSuccess,
    required this.message,
    this.warnings = const [],
  });

  final bool isSuccess;
  final String message;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty;

  factory MutationResult.success(
    String message, {
    List<String> warnings = const [],
  }) {
    return MutationResult._(
      isSuccess: true,
      message: message,
      warnings: warnings,
    );
  }

  factory MutationResult.failure(
    String message, {
    List<String> warnings = const [],
  }) {
    return MutationResult._(
      isSuccess: false,
      message: message,
      warnings: warnings,
    );
  }
}
