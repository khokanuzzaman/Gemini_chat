import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../providers/prediction_provider.dart';

class PredictionWidget extends ConsumerStatefulWidget {
  const PredictionWidget({
    super.key,
    required this.month,
    required this.currentSpent,
  });

  final DateTime month;
  final double currentSpent;

  @override
  ConsumerState<PredictionWidget> createState() => _PredictionWidgetState();
}

class _PredictionWidgetState extends ConsumerState<PredictionWidget> {
  DateTime? _requestedMonth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PredictionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadIfNeeded();
  }

  void _loadIfNeeded() {
    final month = DateTime(widget.month.year, widget.month.month, 1);
    if (_requestedMonth == month) {
      return;
    }
    _requestedMonth = month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(predictionProvider.notifier).loadForMonth(month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prediction = ref.watch(predictionProvider);
    final isCurrentMonth =
        widget.month.year == DateTime.now().year &&
        widget.month.month == DateTime.now().month;
    if (!isCurrentMonth) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: prediction.when(
          data: (data) {
            if (data == null) {
              return _buildPlaceholder(context, 'এখনো কোনো পূর্বাভাস নেই');
            }
            final confidenceColor = switch (data.confidence) {
              'high' => AppColors.success,
              'medium' => AppColors.warning,
              _ => context.secondaryTextColor,
            };
            final trendColor = switch (data.trend) {
              'increasing' => AppColors.error,
              'decreasing' => AppColors.success,
              _ => Theme.of(context).colorScheme.primary,
            };
            final progress = data.predictedTotal <= 0
                ? 0.0
                : (widget.currentSpent / data.predictedTotal).clamp(0.0, 1.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 এই মাসের পূর্বাভাস',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      Text(
                        BanglaFormatters.currency(data.predictedTotal),
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'মাস শেষে আনুমানিক খরচ',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: switch (data.confidence) {
                        'high' => 'নির্ভরযোগ্য',
                        'medium' => 'আনুমানিক',
                        _ => 'প্রাথমিক অনুমান',
                      },
                      color: confidenceColor,
                    ),
                    _Badge(
                      label: switch (data.trend) {
                        'increasing' => '↑ বাড়ছে',
                        'decreasing' => '↓ কমছে',
                        _ => '→ স্থিতিশীল',
                      },
                      color: trendColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                Text(data.explanation, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(predictionProvider.notifier)
                        .loadForMonth(widget.month, forceRefresh: true),
                    child: const Text('আপডেট করুন'),
                  ),
                ),
              ],
            );
          },
          loading: () => _buildPlaceholder(
            context,
            'পূর্বাভাস তৈরি হচ্ছে...',
            trailing: const CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, _) => _buildPlaceholder(context, '$error'),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    String text, {
    Widget? trailing,
  }) {
    final children = <Widget>[
      Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
    ];
    if (trailing != null) {
      children.add(trailing);
    }

    return Row(children: children);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
