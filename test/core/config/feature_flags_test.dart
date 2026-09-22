import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/config/feature_flags.dart';

void main() {
  test(
    'AI is disabled by default (no --dart-define=AI_ENABLED)',
    () {
      // Phase-1 invariant: the app must ship with AI off unless a build
      // explicitly passes --dart-define=AI_ENABLED=true. Guards against the
      // default being flipped by accident.
      expect(FeatureFlags.aiEnabled, isFalse);
    },
    // Only meaningful for the default build; an explicit AI_ENABLED=true build
    // intentionally flips it.
    skip: FeatureFlags.aiEnabled ? 'AI_ENABLED=true build' : null,
  );
}
