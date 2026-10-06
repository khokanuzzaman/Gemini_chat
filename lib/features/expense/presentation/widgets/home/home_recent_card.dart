import 'package:flutter/material.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/recent_activity.dart';
import '../../utils/expense_category_meta.dart';

/// "সাম্প্রতিক লেনদেন": the last 5 expenses and income together. Category icon in
/// a primary-soft circle (brass for EMI/debt), small date, ৳ amount — income in
/// the success colour with a "+".
class HomeRecentCard extends StatelessWidget {
  const HomeRecentCard({super.key, required this.items});

  final List<RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sectionGap),
        AppSectionHeader(
          title: 'সাম্প্রতিক লেনদেন',
          action: TextButton(
            onPressed: AppShellNavigation.openExpenses,
            // An icon, not a "→" character: the bundled fonts have no arrow glyph.
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('সব দেখুন'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                HomeActivityRow(item: items[i]),
                if (i != items.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.tokens.line,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class HomeActivityRow extends StatelessWidget {
  const HomeActivityRow({super.key, required this.item});

  final RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final icon = item.isIncome
        ? Icons.south_west_rounded
        : resolveExpenseCategory(item.category).icon;
    final (background, foreground) = item.isEmi
        ? (tokens.brassSoft, context.brassGlyph)
        : item.isIncome
        ? (tokens.successSoft, tokens.successText)
        : (tokens.primarySoft, tokens.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
                ),
                Text(
                  '${BanglaFormatters.relativeDay(item.date)} · ${item.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${item.isIncome ? '+' : '-'}${BanglaFormatters.currency(item.amount)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: item.isIncome
                      ? tokens.successText
                      : tokens.expenseText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
