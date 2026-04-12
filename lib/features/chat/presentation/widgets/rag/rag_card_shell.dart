import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

class RagCardShell extends StatelessWidget {
  const RagCardShell({
    super.key,
    required this.title,
    required this.icon,
    required this.tintColor,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color tintColor;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      duration: AppMotion.normal,
      offset: const Offset(0, 0.05),
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: context.ragCardBackground(tintColor),
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: context.ragCardBorder(tintColor), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tintColor.withValues(
                      alpha: context.isDarkMode ? 0.25 : 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: tintColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class RagStatBlock extends StatelessWidget {
  const RagStatBlock({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class RagAnalyticsButton extends StatelessWidget {
  const RagAnalyticsButton({
    super.key,
    required this.onTap,
    required this.tintColor,
  });

  final VoidCallback onTap;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.analytics_outlined, size: 16, color: tintColor),
      label: Text(
        'বিশদ দেখুন',
        style: AppTextStyles.bodySmall.copyWith(color: tintColor),
      ),
    );
  }
}
