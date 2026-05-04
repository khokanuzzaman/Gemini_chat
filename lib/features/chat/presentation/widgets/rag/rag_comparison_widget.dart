import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../chat_card_primitives.dart';
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
    final categories = _collectCategories(
      data.lastMonthCategoryData ?? const {},
      data.categoryData ?? const {},
    );
    final insightLines = data.insights ?? const <String>[];

    return RagAnimatedCard(
      borderColor: context.ragCardBorder(AppColors.warning),
      backgroundColor: context.ragCardBackground(AppColors.warning),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RagCardHeader(
              icon: Icons.compare_arrows_rounded,
              title: 'মাসিক তুলনা',
              subtitle:
                  '${data.lastMonthName ?? 'আগের মাস'} বনাম ${data.monthName}',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChatStatChip(
                  icon: difference == 0
                      ? Icons.remove_rounded
                      : difference > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  label: difference == 0
                      ? 'খরচ অপরিবর্তিত'
                      : difference > 0
                      ? '${BanglaFormatters.currency(difference.abs())} বেশি'
                      : '${BanglaFormatters.currency(difference.abs())} কম',
                  accentColor: difference > 0
                      ? const Color(0xFFDC2626)
                      : difference < 0
                      ? const Color(0xFF16A34A)
                      : AppColors.warning,
                ),
                ChatStatChip(
                  icon: Icons.category_rounded,
                  label: '${BanglaFormatters.count(categories.length)}টি ক্যাটাগরি',
                  accentColor: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: data.lastMonthName ?? 'আগের মাস',
                    amount: previousTotal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AmountColumn(
                    label: data.monthName,
                    amount: currentTotal,
                    difference: difference,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ChatSectionSurface(
              accentColor: AppColors.warning,
              backgroundColor: context.cardBackgroundColor,
              borderColor: context.ragCardBorder(AppColors.warning),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(child: _TableHeading(text: 'ক্যাটাগরি')),
                      SizedBox(width: 12),
                      Expanded(child: _TableHeading(text: 'আগের মাস')),
                      SizedBox(width: 12),
                      Expanded(child: _TableHeading(text: 'এই মাস')),
                      SizedBox(width: 12),
                      Expanded(child: _TableHeading(text: 'পরিবর্তন')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final category in categories) ...[
                    _ComparisonRow(
                      category: category,
                      previous: data.lastMonthCategoryData?[category] ?? 0,
                      current: data.categoryData?[category] ?? 0,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (insightLines.isNotEmpty)
              ...insightLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InsightLine(text: line),
                ),
              ),
            RagFooter(onTap: onOpenAnalytics),
          ],
        ),
      ),
    );
  }

  List<String> _collectCategories(
    Map<String, double> previous,
    Map<String, double> current,
  ) {
    final all = {...previous.keys, ...current.keys}.toList(growable: false)
      ..sort((a, b) {
        final currentDiff = (current[b] ?? 0).compareTo(current[a] ?? 0);
        return currentDiff;
      });
    return all.take(4).toList(growable: false);
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.amount,
    this.difference,
  });

  final String label;
  final double amount;
  final double? difference;

  @override
  Widget build(BuildContext context) {
    return ChatSectionSurface(
      accentColor: AppColors.warning,
      backgroundColor: context.cardBackgroundColor,
      borderColor: context.ragCardBorder(AppColors.warning),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            BanglaFormatters.currency(amount),
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (difference != null) ...[
            const SizedBox(height: 8),
            Text(
              difference == 0
                  ? 'অপরিবর্তিত'
                  : difference! > 0
                  ? '↑ ${BanglaFormatters.currency(difference!.abs())} বেশি'
                  : '↓ ${BanglaFormatters.currency(difference!.abs())} কম',
              style: TextStyle(
                color: difference == 0
                    ? const Color(0xFF64748B)
                    : difference! > 0
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  const _TableHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.secondaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.category,
    required this.previous,
    required this.current,
  });

  final String category;
  final double previous;
  final double current;

  @override
  Widget build(BuildContext context) {
    final difference = current - previous;
    final color = difference > 0
        ? const Color(0xFFDC2626)
        : difference < 0
        ? const Color(0xFF16A34A)
        : const Color(0xFF64748B);
    final symbol = difference > 0
        ? '↑'
        : difference < 0
        ? '↓'
        : '•';

    return Row(
      children: [
        Expanded(
          child: Text(
            category,
            style: TextStyle(
              color: context.primaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(BanglaFormatters.currency(previous))),
        const SizedBox(width: 12),
        Expanded(child: Text(BanglaFormatters.currency(current))),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$symbol ${BanglaFormatters.currency(difference.abs())}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isPositive = text.contains('সাশ্রয়') || text.contains('কম');
    final isWarning = text.contains('বেশি') || text.contains('সতর্ক');
    final color = isPositive
        ? const Color(0xFF16A34A)
        : isWarning
        ? const Color(0xFFF59E0B)
        : Theme.of(context).textTheme.bodySmall?.color ?? AppColors.grey600;
    final prefix = isPositive
        ? '✅'
        : isWarning
        ? '⚠️'
        : '•';

    return Text(
      '$prefix $text',
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}
