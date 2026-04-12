import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
import '../../../../../core/widgets/widgets.dart';
import 'rag_card_shell.dart';

class RagTodayWidget extends StatelessWidget {
  const RagTodayWidget({
    super.key,
    required this.data,
    required this.onOpenAnalytics,
  });

  final RagResponseData data;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final items = data.recentItems ?? const <RecentTransaction>[];
    final visibleItems = items.take(5).toList(growable: false);
    final total = data.totalAmount ?? 0;
    final remaining = items.length - visibleItems.length;

    return RagCardShell(
      title: 'আজকের সারাংশ',
      icon: Icons.today_rounded,
      tintColor: AppColors.info,
      subtitle: BanglaFormatters.fullDate(DateTime.now()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AppAmountText(
                amount: total,
                style: AppTextStyles.heroAmount.copyWith(fontSize: 28),
                isExpense: true,
              ),
              const SizedBox(height: 4),
              Text(
                'আজকের মোট খরচ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (visibleItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'আজকে কোনো খরচ নেই',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            )
          else ...[
            for (var index = 0; index < visibleItems.length; index++) ...[
              _TodayExpenseRow(item: visibleItems[index]),
              if (index != visibleItems.length - 1) const SizedBox(height: 10),
            ],
            if (remaining > 0) ...[
              const SizedBox(height: 8),
              Text(
                'আরো ${BanglaFormatters.count(remaining)}টি',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: RagAnalyticsButton(
              onTap: onOpenAnalytics,
              tintColor: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayExpenseRow extends StatelessWidget {
  const _TodayExpenseRow({required this.item});

  final RecentTransaction item;

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryIcon.getColor(item.category);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              CategoryIcon.getIcon(item.category),
              size: 16,
              color: categoryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppAmountText(
            amount: item.amount,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            isExpense: true,
          ),
        ],
      ),
    );
  }
}
