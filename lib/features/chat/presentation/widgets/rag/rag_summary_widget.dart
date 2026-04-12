import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
import '../../../../../core/widgets/widgets.dart';
import 'rag_card_shell.dart';

class RagSummaryWidget extends StatelessWidget {
  const RagSummaryWidget({
    super.key,
    required this.data,
    required this.onOpenAnalytics,
  });

  final RagResponseData data;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final total = data.totalAmount ?? 0;
    final transactionCount = data.transactionCount ?? 0;
    final averagePerDay = total / math.max(1, DateTime.now().day);
    final topCategories = _topCategories(data.categoryData ?? const {});

    return RagCardShell(
      title: 'মাসিক সারাংশ',
      icon: Icons.calendar_month_rounded,
      tintColor: context.appColors.primary,
      subtitle: data.monthName,
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
                'মোট খরচ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: RagStatBlock(
                  label: 'লেনদেন',
                  value: '${BanglaFormatters.count(transactionCount)}টি',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RagStatBlock(
                  label: 'প্রতি দিন গড়',
                  value: BanglaFormatters.currency(averagePerDay),
                ),
              ),
            ],
          ),
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < topCategories.length; index++) ...[
              _CategoryAmountRow(entry: topCategories[index]),
              if (index != topCategories.length - 1) const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: RagAnalyticsButton(
              onTap: onOpenAnalytics,
              tintColor: context.appColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _topCategories(Map<String, double> source) {
    final sorted = source.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    return sorted.take(3).toList(growable: false);
  }
}

class _CategoryAmountRow extends StatelessWidget {
  const _CategoryAmountRow({required this.entry});

  final MapEntry<String, double> entry;

  @override
  Widget build(BuildContext context) {
    final color = CategoryIcon.getColor(entry.key);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entry.key,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
        ),
        Text(
          BanglaFormatters.currency(entry.value),
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
