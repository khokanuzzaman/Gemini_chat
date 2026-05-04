import 'package:flutter/material.dart';

import '../../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/bangla_formatters.dart';
import '../../../../../../core/widgets/widgets.dart';

class AnomalyInsightPage extends StatelessWidget {
  const AnomalyInsightPage({
    super.key,
    required this.count,
    required this.highCount,
  });

  final int count;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    final color = highCount > 0 ? AppColors.error : AppColors.warning;
    return AppCard(
      onTap: () => AppShellNavigation.openAnalytics(tabIndex: 1),
      padding: const EdgeInsets.all(16),
      child: AppListTile(
        title: '${BanglaFormatters.count(count)}টি অস্বাভাবিক খরচ',
        subtitle: highCount > 0
            ? '$highCount টি উচ্চ ঝুঁকির'
            : '${BanglaFormatters.count(count)} টি সামান্য অস্বাভাবিক',
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.warning_amber_rounded, color: color),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        dense: true,
      ),
    );
  }
}
