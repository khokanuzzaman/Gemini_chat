class TokenUsage {
  const TokenUsage({
    required this.promptTokens,
    required this.outputTokens,
    required this.totalTokens,
    this.isEstimated = false,
  });

  final int promptTokens;
  final int outputTokens;
  final int totalTokens;
  final bool isEstimated;
}
