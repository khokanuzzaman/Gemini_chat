import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/utils/bangla_formatters.dart';
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
      borderColor: const Color(0xFFFED7AA),
      backgroundColor: const Color(0xFFFFFBEB),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(child: _TableHeading(text: 'Category')),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            BanglaFormatters.currency(amount),
            style: const TextStyle(
              color: Color(0xFF0F172A),
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
      style: const TextStyle(
        color: Color(0xFF64748B),
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
            style: const TextStyle(
              color: Color(0xFF0F172A),
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
        : const Color(0xFF334155);
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
