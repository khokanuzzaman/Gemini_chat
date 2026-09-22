import 'package:flutter/material.dart';

import '../widgets/chat_screen_content.dart';

/// The চ্যাট tab body. This tab is only present in the shell when AI is enabled
/// (see FeatureFlags.aiEnabled and the nav shell), so no in-screen gate is
/// needed — when AI is off the tab is not built at all.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatScreenContent();
  }
}
