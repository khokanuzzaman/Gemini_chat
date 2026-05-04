import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
import '../chat_card_primitives.dart';
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
    final category =
        data.highlightedCategory ??
        (data.categoryData?.isNotEmpty ?? false
            ? data.categoryData!.entries.first.key
            : 'Other');
    final total = data.totalAmount ?? 0;
    final categoryAmount = data.categoryData?[category] ?? 0;
    final percent = total <= 0 ? 0 : ((categoryAmount / total) * 100).round();
    final transactions = data.recentItems ?? const <RecentTransaction>[];
    final insight = (data.insights?.isNotEmpty ?? false)
        ? data.insights!.last
        : data.aiText;

    return RagAnimatedCard(
      borderColor: CategoryIcon.getColor(category).withValues(alpha: 0.22),
      backgroundColor: context.ragCardBackground(
        CategoryIcon.getColor(category),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RagCardHeader(
              icon: CategoryIcon.getIcon(category),
              title: 'ক্যাটাগরি বিশ্লেষণ',
              subtitle: data.monthName,
            ),
            const SizedBox(height: 18),
            ChatSectionSurface(
              accentColor: CategoryIcon.getColor(category),
              backgroundColor: context.cardBackgroundColor,
              borderColor: CategoryIcon.getColor(category).withValues(alpha: 0.18),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: CategoryIcon.getColor(
                          category,
                        ).withValues(alpha: 0.14),
                        child: Icon(
                          CategoryIcon.getIcon(category),
                          color: CategoryIcon.getColor(category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    BanglaFormatters.currency(categoryAmount),
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percent% মোটের',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedCategoryBar(
                    label: 'এই মাসে',
                    amountLabel: BanglaFormatters.currency(categoryAmount),
                    percentLabel: '$percent%',
                    value: total <= 0 ? 0 : categoryAmount / total,
                    color: CategoryIcon.getColor(category),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChatStatChip(
                  icon: Icons.pie_chart_rounded,
                  label: '$percent% শেয়ার',
                  accentColor: CategoryIcon.getColor(category),
                ),
                ChatStatChip(
                  icon: Icons.receipt_long_rounded,
                  label:
                      '${BanglaFormatters.count(transactions.length)}টি লেনদেন',
                  accentColor: CategoryIcon.getColor(category),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'সাম্প্রতিক খরচ',
              style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (transactions.isEmpty)
              Text(
                'এই ক্যাটাগরিতে এখনো কোনো খরচ নেই',
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              for (final item in transactions.take(4)) ...[
                _TransactionRow(item: item),
                const SizedBox(height: 10),
              ],
              if (transactions.length > 4)
                Text(
                  '... আরো ${BanglaFormatters.count(transactions.length - 4)}টি',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
            const SizedBox(height: 16),
            ChatSectionSurface(
              accentColor: CategoryIcon.getColor(category),
              backgroundColor: context.mutedSurfaceColor,
              borderColor: context.borderColor,
              child: Text(
                '💡 "$insight"',
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            RagFooter(onTap: onOpenAnalytics),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});

  final RecentTransaction item;

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(item.date);

    return Row(
      children: [
        Expanded(
          child: Text(
            item.description,
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          BanglaFormatters.currency(item.amount),
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          parsedDate == null
              ? item.date
              : BanglaFormatters.dayMonth(parsedDate),
          style: TextStyle(
            color: context.secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
