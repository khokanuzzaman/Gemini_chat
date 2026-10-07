/// Compile-time feature flags.
///
/// These are `const bool.fromEnvironment` values so the Dart compiler can
/// tree-shake gated code out of release builds when the flag is off — the app
/// never ships dead code paths for disabled features.
class FeatureFlags {
  const FeatureFlags._();

  /// Whether AI features (chat entry, voice, receipt scan, RAG "ask", and the
  /// prediction / budget-planner AI narration) are enabled.
  ///
  /// **Off by default (Phase 1).** AI ships disabled and unreachable — no gated
  /// path can reach the AI gateway. Phase 2 turns it on at build time:
  ///
  /// ```
  /// flutter build ... --dart-define=AI_ENABLED=true
  /// ```
  static const bool aiEnabled = bool.fromEnvironment('AI_ENABLED');

  /// Whether Premium (paywall, upgrade prompts, RevenueCat) exists in this build.
  ///
  /// **Off by default (Phase 1).** With it off there is no Premium screen, no
  /// settings banner, no upsell or "Premium" wording anywhere, and RevenueCat is
  /// never configured (no purchase SDK traffic, no uid sent to it). The backup
  /// gating itself is unchanged: auto-backup stays available to users who already
  /// had it ("grandfathered") and is simply not offered to anyone else. Turn it on
  /// with `--dart-define=PREMIUM_ENABLED=true` (and a RevenueCat key) when there is
  /// something to sell.
  static const bool premiumEnabled = bool.fromEnvironment('PREMIUM_ENABLED');
}
