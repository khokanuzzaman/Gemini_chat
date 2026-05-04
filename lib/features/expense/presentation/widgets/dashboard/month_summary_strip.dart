import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../providers/expense_providers.dart';

class MonthSummaryStrip extends ConsumerWidget {
  const MonthSummaryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final data = dashboard.valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final difference = data.thisMonthTotal - data.lastMonthTotal;
    final monthLabel = BanglaFormatters.monthYear(DateTime.now());
    final totalLabel = BanglaFormatters.currency(data.thisMonthTotal);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
                children: [
                  TextSpan(text: monthLabel),
                  const TextSpan(text: ' · মোট খরচ '),
                  TextSpan(
                    text: totalLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (difference.abs() >= 1) ...[
                    const TextSpan(text: ' · গত মাসের চেয়ে '),
                    TextSpan(
                      text: difference.isNegative ? '↓ ' : '↑ ',
                      style: TextStyle(
                        color: difference.isNegative
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: BanglaFormatters.currency(difference.abs()),
                      style: TextStyle(
                        color: difference.isNegative
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
