import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import 'rag_card_shell.dart';

class RagComparisonWidget extends StatelessWidget {
  const RagComparisonWidget({
    super.key,
    required this.data,
    required this.onOpenAnalytics,
  });

  final RagResponseData data;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final currentTotal = data.totalAmount ?? 0;
    final previousTotal = data.lastMonthTotal ?? 0;
    final difference = currentTotal - previousTotal;
    final percentChange = previousTotal <= 0
        ? null
        : ((difference.abs() / previousTotal) * 100).round();
    final differenceColor = difference > 0
        ? AppColors.error
        : difference < 0
        ? AppColors.success
        : context.secondaryTextColor;
    final differenceBackground = differenceColor.withValues(
      alpha: context.isDarkMode ? 0.18 : 0.10,
    );
    final differenceText = _buildDifferenceText(
      difference: difference,
      percentChange: percentChange,
      currentTotal: currentTotal,
    );

    return RagCardShell(
      title: 'মাসিক তুলনা',
      icon: Icons.compare_arrows_rounded,
      tintColor: Colors.purple,
      subtitle: '${data.monthName} বনাম ${data.lastMonthName ?? 'গত মাস'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _MonthBlock(
                  label: data.monthName.isEmpty ? 'এই মাস' : data.monthName,
                  amount: currentTotal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MonthBlock(
                  label: data.lastMonthName ?? 'গত মাস',
                  amount: previousTotal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: differenceBackground,
              borderRadius: AppRadius.cardAll,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  difference > 0
                      ? Icons.trending_up_rounded
                      : difference < 0
                      ? Icons.trending_down_rounded
                      : Icons.trending_flat_rounded,
                  color: differenceColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    differenceText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: differenceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: RagAnalyticsButton(
              onTap: onOpenAnalytics,
              tintColor: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  String _buildDifferenceText({
    required double difference,
    required int? percentChange,
    required double currentTotal,
  }) {
    if (difference == 0) {
      return 'গত মাসের মতোই খরচ হয়েছে';
    }

    if (percentChange == null) {
      if (currentTotal <= 0) {
        return 'তুলনার জন্য যথেষ্ট তথ্য নেই';
      }
      return 'এই মাসে নতুন খরচ ধরা হয়েছে';
    }

    final direction = difference > 0 ? 'বেশি' : 'কম';
    return 'গত মাসের চেয়ে ${BanglaFormatters.count(percentChange)}% $direction খরচ';
  }
}

class _MonthBlock extends StatelessWidget {
  const _MonthBlock({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.6)),
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
          AppAmountText(
            amount: amount,
            style: AppTextStyles.titleLarge,
            isExpense: true,
          ),
        ],
      ),
    );
  }
}
