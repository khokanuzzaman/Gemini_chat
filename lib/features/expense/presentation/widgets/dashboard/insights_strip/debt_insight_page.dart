import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/bangla_formatters.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../debt/presentation/providers/debt_providers.dart';

class DebtInsightPage extends ConsumerWidget {
  const DebtInsightPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(debtSummaryProvider);
    final netColor = summary.netPosition >= 0
        ? AppColors.success
        : AppColors.error;

    return AppCard(
      onTap: AppShellNavigation.openDebts,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: context.appColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ধার-দেনা',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (summary.overdueCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            AppChip(
              label:
                  '${BanglaFormatters.count(summary.overdueCount)} টি মেয়াদোত্তীর্ণ',
              color: AppColors.error,
              compact: true,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.secondaryTextColor,
              ),
              children: [
                TextSpan(
                  text:
                      'পাওনা: ${BanglaFormatters.currency(summary.totalOwedToMe)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' · '),
                TextSpan(
                  text:
                      'দেনা: ${BanglaFormatters.currency(summary.totalIOwe)}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'নিট: ${summary.netPosition >= 0 ? '+' : '-'}${BanglaFormatters.currency(summary.netPosition.abs())}',
            style: AppTextStyles.titleMedium.copyWith(
              color: netColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (summary.upcomingEMICount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '⚠️ ${BanglaFormatters.count(summary.upcomingEMICount)} কিস্তি এই সপ্তাহে · ${BanglaFormatters.currency(summary.upcomingEMITotal)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
