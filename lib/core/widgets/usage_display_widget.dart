import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../premium/premium_providers.dart';
import '../theme/app_theme.dart';
import '../usage/usage_limits.dart';
import '../usage/usage_providers.dart';
import '../usage/usage_status.dart';
import '../utils/bangla_formatters.dart';
import 'app_card.dart';
import 'app_error_state.dart';
import 'app_loading_state.dart';
import 'app_progress_bar.dart';
import 'app_section_header.dart';

class UsageDisplayWidget extends ConsumerWidget {
  const UsageDisplayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final statusesAsync = ref.watch(allUsageStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: 'আজকের ব্যবহার'),
        const SizedBox(height: AppSpacing.md),
        if (isPremium)
          AppCard(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(
                  alpha: context.isDarkMode ? 0.24 : 0.14,
                ),
                context.cardBackgroundColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Premium — সীমাহীন ব্যবহার',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          statusesAsync.when(
            loading: () => const AppLoadingState.card(height: 360),
            error: (error, stackTrace) => AppErrorState(
              compact: true,
              message: 'ব্যবহারের তথ্য এখন দেখানো যাচ্ছে না',
              onRetry: () => ref.invalidate(allUsageStatusProvider),
            ),
            data: (statuses) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < UsageLimits.allFeatures.length;
                    index++
                  ) ...[
                    _UsageFeatureRow(
                      status: statuses[UsageLimits.allFeatures[index]]!,
                    ),
                    if (index != UsageLimits.allFeatures.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UsageFeatureRow extends StatelessWidget {
  const _UsageFeatureRow({required this.status});

  final UsageStatus status;

  @override
  Widget build(BuildContext context) {
    final progressColor = switch (status.usagePercentage) {
      > 0.8 => AppColors.error,
      >= 0.6 => AppColors.warning,
      _ => AppColors.success,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status.bengaliFeatureName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            Text(
              '${BanglaFormatters.count(status.used)}/${BanglaFormatters.count(status.limit)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(value: status.usagePercentage, color: progressColor),
        const SizedBox(height: AppSpacing.xs),
        Text(
          status.resetAtBengali,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
