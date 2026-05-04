import 'package:flutter/material.dart';

import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/utils/category_icon.dart';
import '../../../../../core/widgets/widgets.dart';

class UpcomingRecurringCard extends StatelessWidget {
  const UpcomingRecurringCard({super.key, required this.patterns});

  final List<dynamic> patterns;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: patterns
            .take(3)
            .map((pattern) {
              return AppListTile(
                title: pattern.description,
                subtitle: pattern.nextExpected == null
                    ? 'তারিখ নেই'
                    : BanglaFormatters.fullDate(pattern.nextExpected!),
                leading: CircleAvatar(
                  backgroundColor: CategoryIcon.getColor(
                    pattern.category,
                  ).withValues(alpha: 0.12),
                  child: Icon(
                    CategoryIcon.getIcon(pattern.category),
                    color: CategoryIcon.getColor(pattern.category),
                  ),
                ),
                trailingAmount: pattern.averageAmount,
                trailingSubtitle: 'আনুমানিক',
                dense: true,
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
