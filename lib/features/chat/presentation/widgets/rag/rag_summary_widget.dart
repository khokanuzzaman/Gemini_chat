import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
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
    final categories = _topCategories(data.categoryData ?? const {});
    final leadingCategory = categories.isEmpty ? null : categories.first.key;
    final leadingAmount = leadingCategory == null
        ? 0
        : (data.categoryData?[leadingCategory] ?? 0);
    final comparison = _buildComparisonText(total, data.lastMonthTotal);
    final insight = (data.insights?.isNotEmpty ?? false)
        ? data.insights!.last
        : data.aiText;

    return RagAnimatedCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RagCardHeader(
              icon: Icons.bar_chart_rounded,
              title: 'এই মাসের সারসংক্ষেপ',
              subtitle: data.monthName,
            ),
            const SizedBox(height: 18),
            Center(
              child: Column(
                children: [
                  Text(
                    BanglaFormatters.currency(total),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'মোট খরচ',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (comparison != null) ...[
                    const SizedBox(height: 10),
                    _ComparisonBadge(
                      isIncrease: comparison.isIncrease,
                      label: comparison.label,
                    ),
                  ],
                ],
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'ক্যাটাগরি অনুযায়ী',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in categories) ...[
                AnimatedCategoryBar(
                  label: entry.key,
                  amountLabel: BanglaFormatters.currency(entry.value),
                  percentLabel: '${_percent(entry.value, total)}%',
                  value: total <= 0 ? 0 : entry.value / total,
                  color: CategoryIcon.getColor(entry.key),
                ),
                const SizedBox(height: 12),
              ],
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickStatChip(
                  icon: Icons.calendar_month_rounded,
                  label:
                      '${BanglaFormatters.count(data.transactionCount ?? 0)}টি transaction',
                ),
                if (leadingCategory != null)
                  _QuickStatChip(
                    icon: CategoryIcon.getIcon(leadingCategory),
                    label:
                        'সবচেয়ে বেশি: $leadingCategory (${BanglaFormatters.currency(leadingAmount)})',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _InsightCard(text: insight),
            const SizedBox(height: 16),
            RagFooter(onTap: onOpenAnalytics),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _topCategories(Map<String, double> source) {
    final sorted = source.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    if (sorted.length <= 4) {
      return sorted;
    }

    final top = sorted.take(3).toList(growable: true);
    final othersTotal = sorted
        .skip(3)
        .fold<double>(0, (sum, entry) => sum + entry.value);
    top.add(MapEntry('অন্যান্য', othersTotal));
    return top;
  }

  int _percent(double amount, double total) {
    if (total <= 0) {
      return 0;
    }
    return ((amount / total) * 100).round();
  }

  _ComparisonInfo? _buildComparisonText(double total, double? lastMonthTotal) {
    if (lastMonthTotal == null) {
      return null;
    }

    final difference = total - lastMonthTotal;
    if (difference.abs() < 1) {
      return const _ComparisonInfo(
        label: 'গত মাসের মতোই আছে',
        isIncrease: false,
      );
    }

    final label = difference > 0
        ? 'গত মাসের চেয়ে ${BanglaFormatters.currency(difference)} বেশি'
        : 'গত মাসের চেয়ে ${BanglaFormatters.currency(difference.abs())} কম';
    return _ComparisonInfo(label: label, isIncrease: difference > 0);
  }
}

class _QuickStatChip extends StatelessWidget {
  const _QuickStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF334155)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '💡 "$text"',
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.isIncrease, required this.label});

  final bool isIncrease;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isIncrease
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final icon = isIncrease
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonInfo {
  const _ComparisonInfo({required this.label, required this.isIncrease});

  final String label;
  final bool isIncrease;
}
