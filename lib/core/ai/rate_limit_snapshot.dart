class RateLimitSnapshot {
  const RateLimitSnapshot({
    required this.capturedAt,
    this.source,
    this.limitRequests,
    this.remainingRequests,
    this.limitTokens,
    this.remainingTokens,
    this.resetRequests,
    this.resetTokens,
  });

  final DateTime capturedAt;
  final String? source;
  final int? limitRequests;
  final int? remainingRequests;
  final int? limitTokens;
  final int? remainingTokens;
  final String? resetRequests;
  final String? resetTokens;

  static RateLimitSnapshot? tryParse(
    Map<String, String> headers, {
    String? source,
  }) {
    final normalizedHeaders = <String, String>{
      for (final entry in headers.entries) entry.key.toLowerCase(): entry.value,
    };

    final limitRequests = int.tryParse(
      normalizedHeaders['x-ratelimit-limit-requests'] ?? '',
    );
    final remainingRequests = int.tryParse(
      normalizedHeaders['x-ratelimit-remaining-requests'] ?? '',
    );
    final limitTokens = int.tryParse(
      normalizedHeaders['x-ratelimit-limit-tokens'] ?? '',
    );
    final remainingTokens = int.tryParse(
      normalizedHeaders['x-ratelimit-remaining-tokens'] ?? '',
    );
    final resetRequests = normalizedHeaders['x-ratelimit-reset-requests'];
    final resetTokens = normalizedHeaders['x-ratelimit-reset-tokens'];

    if (limitRequests == null &&
        remainingRequests == null &&
        limitTokens == null &&
        remainingTokens == null &&
        resetRequests == null &&
        resetTokens == null) {
      return null;
    }

    return RateLimitSnapshot(
      capturedAt: DateTime.now(),
      source: source,
      limitRequests: limitRequests,
      remainingRequests: remainingRequests,
      limitTokens: limitTokens,
      remainingTokens: remainingTokens,
      resetRequests: resetRequests,
      resetTokens: resetTokens,
    );
  }

  int? get usedRequests {
    if (limitRequests == null || remainingRequests == null) {
      return null;
    }

    final used = limitRequests! - remainingRequests!;
    return used < 0 ? 0 : used;
  }

  int? get usedTokens {
    if (limitTokens == null || remainingTokens == null) {
      return null;
    }

    final used = limitTokens! - remainingTokens!;
    return used < 0 ? 0 : used;
  }

  double? get requestUsageFraction {
    if (limitRequests == null ||
        remainingRequests == null ||
        limitRequests! <= 0) {
      return null;
    }

    return (usedRequests! / limitRequests!).clamp(0, 1);
  }

  double? get tokenUsageFraction {
    if (limitTokens == null || remainingTokens == null || limitTokens! <= 0) {
      return null;
    }

    return (usedTokens! / limitTokens!).clamp(0, 1);
  }

  double? get dominantUsageFraction {
    final fractions = <double?>[
      requestUsageFraction,
      tokenUsageFraction,
    ].whereType<double>().toList(growable: false);
    if (fractions.isEmpty) {
      return null;
    }

    fractions.sort();
    return fractions.last;
  }

  int? get dominantUsagePercent {
    final fraction = dominantUsageFraction;
    if (fraction == null) {
      return null;
    }

    return (fraction * 100).round().clamp(0, 100);
  }

  bool get hasLiveData => dominantUsagePercent != null;

  String get sourceLabel {
    switch (source) {
      case 'chat':
        return 'Chat';
      case 'voice':
        return 'Voice';
      case 'receipt':
        return 'Receipt';
      default:
        return 'OpenAI';
    }
  }
}
