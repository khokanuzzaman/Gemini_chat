import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/config/feature_flags.dart';
import 'package:gemini_chat/features/chat/presentation/screens/chat_screen.dart';

void main() {
  testWidgets(
    'ChatScreen renders the inert view when AI is disabled (default build)',
    (tester) async {
      // No Riverpod scope / Isar is needed: with AI off, ChatScreen must NOT
      // build ChatScreenContent (which would require the full chat providers),
      // proving the AI surface is not mounted and cannot reach the gateway.
      await tester.pumpWidget(const MaterialApp(home: ChatScreen()));

      expect(find.text('AI ফিচার এই সংস্করণে বন্ধ আছে'), findsOneWidget);
    },
    // Off-build behavior; with AI_ENABLED=true ChatScreen mounts the full
    // ChatScreenContent instead of the inert view.
    skip: FeatureFlags.aiEnabled,
  );
}
