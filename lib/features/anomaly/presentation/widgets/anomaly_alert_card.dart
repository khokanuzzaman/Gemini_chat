// Feature: Anomaly
// Layer: Presentation

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
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
    final severityColor = alert.severity.color;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: isDismissed ? 0.58 : 1,
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.36),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(alert.severity.icon, color: severityColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _typeLabel(alert.type),
                        style: textTheme.titleSmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SeverityBadge(severity: alert.severity),
                    const SizedBox(width: 8),
                    if (!isDismissed)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          ref.read(anomalyProvider.notifier).dismiss(alert.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alert.category != 'সব' || alert.relatedDate != null) ...[
                      Row(
                        children: [
                          if (alert.category != 'সব')
                            _CategoryBadge(category: alert.category),
                          const Spacer(),
                          if (alert.relatedDate != null)
                            Text(
                              DateFormat('dd MMM', 'bn').format(
                                alert.relatedDate!,
                              ),
                              style: textTheme.bodySmall,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(alert.message, style: textTheme.bodyMedium),
                    const SizedBox(height: 14),
                    _ComparisonBar(
                      current: alert.currentAmount,
                      normal: alert.normalAmount,
                      color: severityColor,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _AmountMetric(
                          label: 'স্বাভাবিক',
                          value: BanglaFormatters.currency(alert.normalAmount),
                        ),
                        const SizedBox(width: 24),
                        _AmountMetric(
                          label: 'এখন',
                          value: BanglaFormatters.currency(alert.currentAmount),
                          valueColor: severityColor,
                          emphasize: true,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+${((alert.ratio - 1) * 100).toStringAsFixed(0)}%',
                            style: textTheme.titleSmall?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(AnomalyType type) {
    return switch (type) {
      AnomalyType.categorySpike => 'Category তে বেশি খরচ',
      AnomalyType.largeTransaction => 'বড় transaction',
      AnomalyType.dailySpike => 'একদিনে বেশি খরচ',
      AnomalyType.frequencyIncrease => 'বেশি transaction',
    };
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final AnomalySeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = severity.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = CategoryIcon.getColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CategoryIcon.getIcon(category), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            category,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountMetric extends StatelessWidget {
  const _AmountMetric({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: (emphasize ? textTheme.titleMedium : textTheme.bodyMedium)
              ?.copyWith(
                color: valueColor,
                fontWeight: emphasize ? FontWeight.w700 : null,
              ),
        ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.current,
    required this.normal,
    required this.color,
  });

  final double current;
  final double normal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = max(current, normal);
    final progress = maxValue <= 0 ? 0.0 : (current / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: 1,
            minHeight: 10,
            backgroundColor: context.borderColor.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation<Color>(
              context.borderColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
