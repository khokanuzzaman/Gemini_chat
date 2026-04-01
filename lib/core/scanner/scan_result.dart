class ScanResult {
  const ScanResult({
    required this.success,
    this.text,
    this.error,
    this.score = 0,
    this.warnings = const [],
    this.wasAutoCropped = false,
  });

  const ScanResult.success({
    required String text,
    int score = 0,
    List<String> warnings = const [],
    bool wasAutoCropped = false,
  }) : this(
         success: true,
         text: text,
         score: score,
         warnings: warnings,
         wasAutoCropped: wasAutoCropped,
       );

  const ScanResult.failure(
    String error, {
    int score = 0,
    List<String> warnings = const [],
    bool wasAutoCropped = false,
  }) : this(
         success: false,
         error: error,
         score: score,
         warnings: warnings,
         wasAutoCropped: wasAutoCropped,
       );

  final bool success;
  final String? text;
  final String? error;
  final int score;
  final List<String> warnings;
  final bool wasAutoCropped;
}
