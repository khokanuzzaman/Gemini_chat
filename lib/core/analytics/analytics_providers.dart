import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'usage_analytics.dart';

/// App-wide anonymous usage analytics (real Firebase logger in production).
final usageAnalyticsProvider = Provider<UsageAnalytics>((ref) {
  return UsageAnalytics(const FirebaseAnalyticsLogger());
});

/// Mirrors the persisted analytics opt-out flag so the UI reacts. Hydrated at
/// startup from AppPreferences.isAnalyticsEnabled() (default true).
final analyticsEnabledProvider = StateProvider<bool>((ref) => true);
