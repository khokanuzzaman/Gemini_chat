// Feature: Prediction
// Layer: Presentation

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon.dart';
import '../../domain/entities/prediction_entity.dart';
import '../providers/prediction_provider.dart';

class PredictionCard extends ConsumerStatefulWidget {
  const PredictionCard({super.key});

  @override
  ConsumerState<PredictionCard> createState() => _PredictionCardState();
}

class _PredictionCardState extends ConsumerState<PredictionCard> {
  bool _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) {
      return;
    }
    _requestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(predictionProvider.notifier).loadPrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionProvider);

    if (state.isStale && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(predictionProvider.notifier)
            .loadPrediction(forceRefresh: true);
      });
    }

    if (state.isLoading || state.isStale) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.isStale
                      ? 'রিফ্রেশ হচ্ছে...'
                      : 'পূর্বাভাস তৈরি হচ্ছে...',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isStreaming) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📈 পূর্বাভাস', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text(
                state.streamingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final prediction = state.prediction;
    if (prediction == null) {
      if (state.error != null) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline, color: AppColors.error),
            title: Text(state.error!, style: AppTextStyles.bodyMedium),
            trailing: TextButton(
              onPressed: () => ref
                  .read(predictionProvider.notifier)
                  .loadPrediction(forceRefresh: true),
              child: const Text('আবার চেষ্টা'),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final progress = prediction.predictedTotal <= 0
        ? 0.0
        : (prediction.currentTotal / prediction.predictedTotal).clamp(0.0, 1.0);
    final compareColor = _compareColor(
      prediction.predictedTotal,
      prediction.lastMonthTotal,
    );
    final sortedCategories = prediction.categoryPredictions.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'মাস শেষের পূর্বাভাস',
                  style: AppTextStyles.titleMedium,
                ),
                const Spacer(),
                if (state.fromCache)
                  Tooltip(
                    message:
                        'Cache থেকে — ${_formatTime(prediction.generatedAt)}',
                    child: Icon(
                      Icons.history,
                      size: 14,
                      color: context.secondaryTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => ref
                      .read(predictionProvider.notifier)
                      .loadPrediction(forceRefresh: true),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '৳ ${_formatAmount(prediction.predictedTotal)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'মাস শেষে আনুমানিক মোট',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(
                  label: prediction.trend.label,
                  color: prediction.trend.color,
                  icon: prediction.trend.icon,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: prediction.confidence.label,
                  color: prediction.confidence.color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Text(
                      'এখন',
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'মাস শেষ',
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final markerFraction = prediction.daysInMonth <= 0
                        ? 0.0
                        : (prediction.currentDay / prediction.daysInMonth)
                              .clamp(0.0, 1.0);
                    final markerLeft =
                        (constraints.maxWidth - 2) * markerFraction;

                    return Stack(
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: context.borderColor.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Positioned(
                          left: markerLeft,
                          child: Container(
                            width: 2,
                            height: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '৳${_formatAmount(prediction.currentTotal)} (এখন)',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '৳${_formatAmount(prediction.predictedTotal)} (পূর্বাভাস)',
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'দৈনিক গড়',
                    value: '৳${prediction.dailyAverage.toStringAsFixed(0)}',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _MiniStat(
                    label: 'বাকি দিন',
                    value: '${prediction.daysRemaining} দিন',
                  ),
                ),
                const _VerticalDivider(),
                Expanded(
                  child: _MiniStat(
                    label: 'গত মাস',
                    value: '৳${_formatAmount(prediction.lastMonthTotal)}',
                  ),
                ),
              ],
            ),
            if (prediction.lastMonthTotal > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: compareColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      prediction.predictedTotal <= prediction.lastMonthTotal
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 14,
                      color: compareColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'গত মাসের চেয়ে ৳${(prediction.predictedTotal - prediction.lastMonthTotal).abs().toStringAsFixed(0)} ${prediction.predictedTotal <= prediction.lastMonthTotal ? 'কম' : 'বেশি'} হওয়ার সম্ভাবনা',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: compareColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (sortedCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Category পূর্বাভাস',
                  style: AppTextStyles.titleMedium,
                ),
                children: sortedCategories
                    .take(5)
                    .map((entry) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          CategoryIcon.getIcon(entry.key),
                          color: CategoryIcon.getColor(entry.key),
                          size: 18,
                        ),
                        title: Text(entry.key, style: AppTextStyles.bodySmall),
                        trailing: Text(
                          '৳${entry.value.toStringAsFixed(0)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.primaryTextColor,
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
            if (prediction.aiInsight.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prediction.aiInsight,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'আপডেট: ${_formatTime(prediction.generatedAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Color _compareColor(double predicted, double lastMonth) {
    return predicted <= lastMonth ? AppColors.success : AppColors.error;
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${math.max(diff.inMinutes, 1)} মিনিট আগে';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ঘণ্টা আগে';
    }
    return DateFormat('dd MMM, hh:mm a').format(dateTime);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: context.secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: context.primaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: context.borderColor,
    );
  }
}
