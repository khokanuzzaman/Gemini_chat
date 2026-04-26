import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../usage/usage_status.dart';
import '../utils/bangla_formatters.dart';

class NearLimitBanner extends StatelessWidget {
  const NearLimitBanner({
    super.key,
    required this.status,
    required this.onUpgrade,
    required this.onDismiss,
  });

  final UsageStatus status;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!status.isNearLimit) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(
          alpha: context.isDarkMode ? 0.18 : 0.12,
        ),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'আজ আর ${BanglaFormatters.count(status.remaining)}টি ${status.bengaliFeatureName} বাকি',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onUpgrade, child: const Text('আপগ্রেড')),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: context.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}
