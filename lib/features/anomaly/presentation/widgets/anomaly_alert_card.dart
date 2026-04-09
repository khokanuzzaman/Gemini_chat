import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/anomaly_alert.dart';
import '../providers/anomaly_provider.dart';

class AnomalyAlertCard extends ConsumerWidget {
  const AnomalyAlertCard({
    super.key,
    required this.alert,
    this.isDismissed = false,
  });

  final AnomalyAlert alert;
  final bool isDismissed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final severityColor = _severityColor(context, alert.severity);

    return Opacity(
      opacity: isDismissed ? 0.55 : 1,
      child: AppCard(
        elevation: 2,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: severityColor, width: 4)),
          ),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppChip(
                    label: _severityLabel(alert.severity),
                    color: severityColor,
                    selected: true,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categoryEmoji(alert.category),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _typeLabel(alert.type),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                alert.message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ComparisonMetric(
                      label: 'স্বাভাবিক',
                      amount: alert.normalAmount,
                      color: context.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ComparisonMetric(
                      label: 'এই মাসে',
                      amount: alert.currentAmount,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppProgressBar(
                value: (alert.ratio / mathMax(alert.ratio, 2)).clamp(0.0, 1.0),
                color: severityColor,
                showLabel: true,
                label:
                    'পরিবর্তন ${(alert.ratio - 1) * 100 >= 0 ? '+' : ''}${((alert.ratio - 1) * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alert.relatedDate == null
                          ? _categoryDisplayName(alert.category)
                          : '${_categoryDisplayName(alert.category)} · ${BanglaFormatters.dayMonth(alert.relatedDate!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                  if (!isDismissed)
                    AppActionButton(
                      label: 'বাদ দিন',
                      variant: AppActionButtonVariant.ghost,
                      size: AppActionButtonSize.small,
                      onPressed: () =>
                          ref.read(anomalyProvider.notifier).dismiss(alert.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  const _ComparisonMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          BanglaFormatters.currency(amount),
          style: AppTextStyles.titleMedium.copyWith(color: color),
        ),
      ],
    );
  }
}

Color _severityColor(BuildContext context, AnomalySeverity severity) {
  return switch (severity) {
    AnomalySeverity.high => AppColors.error,
    AnomalySeverity.medium => AppColors.warning,
    AnomalySeverity.low => context.appColors.primary,
  };
}

String _severityLabel(AnomalySeverity severity) {
  return switch (severity) {
    AnomalySeverity.high => 'উচ্চ',
    AnomalySeverity.medium => 'মাঝারি',
    AnomalySeverity.low => 'কম',
  };
}

String _typeLabel(AnomalyType type) {
  return switch (type) {
    AnomalyType.categorySpike => 'ক্যাটাগরি স্পাইক',
    AnomalyType.largeTransaction => 'বড় লেনদেন',
    AnomalyType.dailySpike => 'দৈনিক স্পাইক',
    AnomalyType.frequencyIncrease => 'লেনদেন বেড়েছে',
  };
}

double mathMax(double first, double second) => first > second ? first : second;

String _categoryEmoji(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
    case 'খাবার':
      return '🍽️';
    case 'transport':
    case 'যাতায়াত':
      return '🛺';
    case 'shopping':
    case 'কেনাকাটা':
      return '🛍️';
    case 'healthcare':
    case 'স্বাস্থ্য':
      return '🩺';
    case 'bill':
    case 'bills':
    case 'বিল':
      return '💡';
    case 'entertainment':
    case 'বিনোদন':
      return '🎬';
    default:
      return '💸';
  }
}

String _categoryDisplayName(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
      return 'খাবার';
    case 'transport':
      return 'যাতায়াত';
    case 'shopping':
      return 'কেনাকাটা';
    case 'healthcare':
      return 'স্বাস্থ্য';
    case 'bill':
    case 'bills':
      return 'বিল';
    case 'entertainment':
      return 'বিনোদন';
    default:
      return category;
  }
}
