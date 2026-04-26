import 'usage_limits.dart';

class UsageStatus {
  const UsageStatus({
    required this.feature,
    required this.used,
    required this.limit,
    required this.isMonthly,
    required this.resetAt,
  });

  final String feature;
  final int used;
  final int limit;
  final bool isMonthly;
  final DateTime resetAt;

  bool get hasReachedLimit => used >= limit;

  bool get isNearLimit => used >= (limit * 0.8).floor() && !hasReachedLimit;

  int get remaining {
    final value = limit - used;
    if (value < 0) {
      return 0;
    }
    if (value > limit) {
      return limit;
    }
    return value;
  }

  double get usagePercentage {
    if (limit <= 0) {
      return 1.0;
    }
    final value = used / limit;
    if (value < 0) {
      return 0.0;
    }
    if (value > 1) {
      return 1.0;
    }
    return value;
  }

  String get bengaliFeatureName => UsageLimits.bengaliName(feature);

  String get resetAtBengali =>
      isMonthly ? 'আগামী মাসের ১ তারিখে' : 'আজ রাত ১২টায়';
}
