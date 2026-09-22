import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/navigation/app_shell_navigation.dart';

void main() {
  group('visibleAppTabs', () {
    test('AI off: চ্যাট is dropped — 4-tab shell in §4 order', () {
      expect(visibleAppTabs(aiEnabled: false), <AppTab>[
        AppTab.home,
        AppTab.expenses,
        AppTab.plan,
        AppTab.more,
      ]);
    });

    test(
      'AI on: চ্যাট re-appears in its §4 position (index 1) — 5-tab shell',
      () {
        final tabs = visibleAppTabs(aiEnabled: true);
        expect(tabs, <AppTab>[
          AppTab.home,
          AppTab.chat,
          AppTab.expenses,
          AppTab.plan,
          AppTab.more,
        ]);
        // Phase 2 = flip the flag; চ্যাট lands in position 1, no re-index.
        expect(tabs.indexOf(AppTab.chat), 1);
      },
    );
  });
}
