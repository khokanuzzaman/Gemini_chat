import 'package:flutter/material.dart';

import '../../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../prediction/domain/entities/prediction_entity.dart';

class PredictionInsightPage extends StatelessWidget {
  const PredictionInsightPage({super.key, required this.prediction});

  final PredictionEntity prediction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      onTap: AppShellNavigation.openAnalytics,
      child: AppListTile(
        title: '৳${_formatPredictionAmount(prediction.predictedTotal)}',
        subtitle: 'মাস শেষের পূর্বাভাস',
        leadingIcon: Icons.analytics_outlined,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              prediction.trend.icon,
              size: 16,
              color: prediction.trend.color,
            ),
            const SizedBox(width: 4),
            Text(
              prediction.trend.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: prediction.trend.color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.secondaryTextColor,
              size: 18,
            ),
          ],
        ),
        dense: true,
      ),
    );
  }

  String _formatPredictionAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
