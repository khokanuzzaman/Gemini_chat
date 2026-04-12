import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/category_icon.dart';
import '../../../../../core/widgets/widgets.dart';
import 'rag_card_shell.dart';

class RagCategoryWidget extends StatelessWidget {
  const RagCategoryWidget({
    super.key,
    required this.data,
    required this.onOpenAnalytics,
  });

  final RagResponseData data;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    final categories = _sortedCategories(data.categoryData ?? const {});
    final highlightedCategory = data.highlightedCategory;
    final highlightedColor = highlightedCategory != null
        ? CategoryIcon.getColor(highlightedCategory)
        : categories.isNotEmpty
        ? CategoryIcon.getColor(categories.first.key)
        : AppColors.food;
    final highlightedAmount = highlightedCategory == null
        ? 0.0
        : (data.categoryData?[highlightedCategory] ?? 0);
    final totalAmount = data.totalAmount ?? 0;

    return RagCardShell(
      title: 'ক্যাটাগরি ভিত্তিক',
      icon: Icons.pie_chart_rounded,
      tintColor: highlightedColor,
      subtitle: data.monthName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlightedCategory != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: AppRadius.cardAll,
                border: Border.all(
                  color: context.ragCardBorder(highlightedColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: highlightedColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CategoryIcon.getIcon(highlightedCategory),
                      size: 32,
                      color: highlightedColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'সবচেয়ে বেশি খরচ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          highlightedCategory,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppAmountText(
                    amount: highlightedAmount,
                    style: AppTextStyles.titleLarge,
                    isExpense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'কোনো ক্যাটাগরির তথ্য নেই',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            for (var index = 0; index < categories.length; index++) ...[
              _CategoryProgressRow(
                entry: categories[index],
                totalAmount: totalAmount,
              ),
              if (index != categories.length - 1) const SizedBox(height: 10),
            ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: RagAnalyticsButton(
              onTap: onOpenAnalytics,
              tintColor: highlightedColor,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _sortedCategories(Map<String, double> source) {
    final sorted = source.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    return sorted;
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({required this.entry, required this.totalAmount});

  final MapEntry<String, double> entry;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final color = CategoryIcon.getColor(entry.key);
    final ratio = totalAmount <= 0 ? 0.0 : entry.value / totalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                CategoryIcon.getIcon(entry.key),
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.key,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            AppAmountText(
              amount: entry.value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              isExpense: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(value: ratio, color: color, height: 6),
      ],
    );
  }
}
