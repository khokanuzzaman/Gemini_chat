import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/settings/premium_screen.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_theme.dart';
import '../usage/usage_status.dart';
import '../utils/bangla_formatters.dart';
import 'app_action_button.dart';
import 'app_bottom_sheet.dart';
import 'app_progress_bar.dart';

class LimitReachedSheet extends StatelessWidget {
  const LimitReachedSheet({super.key, required this.status});

  final UsageStatus status;

  static Future<T?> show<T>({
    required BuildContext context,
    required UsageStatus status,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      title: 'সীমা শেষ',
      child: LimitReachedSheet(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = status.isMonthly
        ? '${status.bengaliFeatureName} এর মাসিক সীমা শেষ'
        : '${status.bengaliFeatureName} এর দৈনিক সীমা শেষ';
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: context.primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${BanglaFormatters.count(status.used)}/${BanglaFormatters.count(status.limit)} ব্যবহার হয়েছে',
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppProgressBar(value: 1, color: AppColors.error, height: 10),
        const SizedBox(height: AppSpacing.md),
        Text(
          'রিসেট হবে: ${status.resetAtBengali}',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(color: context.borderColor),
        const SizedBox(height: AppSpacing.lg),
        AppActionButton(
          label: 'Premium-এ আপগ্রেড করুন',
          icon: Icons.star_rounded,
          fullWidth: true,
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(
              Future<void>.microtask(
                () => rootNavigator.push(
                  AppSlideRoute(builder: (_) => const PremiumScreen()),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppActionButton(
          label: 'ঠিক আছে',
          variant: AppActionButtonVariant.ghost,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
