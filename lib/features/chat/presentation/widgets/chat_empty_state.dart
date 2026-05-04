import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.showAiGuidePrompt,
    required this.onOpenAiGuide,
    required this.onDismissAiGuidePrompt,
  });

  final bool showAiGuidePrompt;
  final VoidCallback onOpenAiGuide;
  final VoidCallback onDismissAiGuidePrompt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 32
                  ? constraints.maxHeight - 32
                  : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'চ্যাট শুরু করুন',
                  subtitle: 'আপনার খরচ লিখুন, বলুন বা রিসিট স্ক্যান করুন',
                  compact: true,
                ),
                if (showAiGuidePrompt) ...[
                  const SizedBox(height: AppSpacing.md),
                  AiGuidePromptCard(
                    onOpenGuide: onOpenAiGuide,
                    onDismiss: onDismissAiGuidePrompt,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class AiGuidePromptCard extends StatelessWidget {
  const AiGuidePromptCard({
    super.key,
    required this.onOpenGuide,
    required this.onDismiss,
  });

  final VoidCallback onOpenGuide;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 2,
      borderRadius: const BorderRadius.all(AppRadius.heroCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: context.appColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Guide দেখে শুরু করুন',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Feature-wise pattern আর copyable examples দেখে দ্রুত শুরু করুন।',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const PromptBullet(text: 'Copy করুন: আজকে খাবারে ২২০ টাকা'),
          const PromptBullet(
            text: 'Pattern দেখুন: expense, income, split, Smart Mode',
          ),
          const PromptBullet(text: 'Receipt/voice ব্যবহার করার checklist আছে'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  label: 'গাইড দেখুন',
                  icon: Icons.menu_book_outlined,
                  size: AppActionButtonSize.small,
                  onPressed: onOpenGuide,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppActionButton(
                label: 'বাদ দিন',
                variant: AppActionButtonVariant.ghost,
                size: AppActionButtonSize.small,
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PromptBullet extends StatelessWidget {
  const PromptBullet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: context.appColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
