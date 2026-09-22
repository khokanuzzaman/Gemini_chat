import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/chat_screen_content.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AI off (Phase 1): the chat surface — and every AI action inside it
    // (voice, receipt scan, RAG) — is not built, so nothing can reach the AI
    // gateway. The চ্যাট tab itself is removed with the navigation overhaul in
    // the next slice; this inert view only covers the interim.
    if (!FeatureFlags.aiEnabled) {
      return const _AiDisabledView();
    }
    return const ChatScreenContent();
  }
}

class _AiDisabledView extends StatelessWidget {
  const _AiDisabledView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 48,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI ফিচার এই সংস্করণে বন্ধ আছে',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'খরচ যোগ করুন ম্যানুয়ালি অথবা SMS ইম্পোর্ট দিয়ে।',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
