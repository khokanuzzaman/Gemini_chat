import 'package:flutter/material.dart';

import '../../../../../core/ai/rag_response_parser.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
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
    final total = data.totalAmount ?? 0;

    return RagAnimatedCard(
      borderColor: const Color(0xFFBFDBFE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RagCardHeader(
              icon: Icons.today_rounded,
              title: 'আজকের খরচ',
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
                    'আজকে মোট',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'আজকে এখনো কোনো খরচ নেই',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else ...[
              const Text(
                'আজকের লেনদেন',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final item in items) ...[
                _TodayTransactionRow(item: item),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 16),
            RagFooter(onTap: onOpenAnalytics),
          ],
        ),
      ),
    );
  }
}

class _TodayTransactionRow extends StatelessWidget {
  const _TodayTransactionRow({required this.item});

  final RecentTransaction item;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: CategoryIcon.getColor(
              item.category,
            ).withValues(alpha: 0.12),
            child: Icon(
              CategoryIcon.getIcon(item.category),
              size: 16,
              color: CategoryIcon.getColor(item.category),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.description,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            BanglaFormatters.currency(item.amount),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            date == null ? item.date : BanglaFormatters.time(date),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
