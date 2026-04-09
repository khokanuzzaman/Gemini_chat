import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
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

    if (state.isLoading) {
      return const AppFadeSlideIn(child: AppLoadingState.card(height: 160));
    }

    if (state.isStreaming) {
      return AppFadeSlideIn(
        child: AppCard(
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'মাসের শেষে পূর্বাভাস',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppChip(
                label: 'রিফ্রেশ হচ্ছে...',
                color: context.appColors.primary,
                selected: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.streamingText.isEmpty
                    ? 'পূর্বাভাস তৈরি হচ্ছে...'
                    : state.streamingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppProgressBar(value: 0.6, color: context.appColors.primary),
            ],
          ),
        ),
      );
    }

    final prediction = state.prediction;
    if (prediction == null) {
      if (state.error == null) {
        return const SizedBox.shrink();
      }
      return AppFadeSlideIn(
        child: AppErrorState(
          title: 'পূর্বাভাস লোড হয়নি',
          message: state.error,
          onRetry: () => ref
              .read(predictionProvider.notifier)
              .loadPrediction(forceRefresh: true),
        ),
      );
    }

    final progress = prediction.predictedTotal <= 0
        ? 0.0
        : (prediction.currentTotal / prediction.predictedTotal).clamp(0.0, 1.0);
    final isStale = state.fromCache;

    return AppFadeSlideIn(
      child: Stack(
        children: [
          AppCard(
            elevation: 2,
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.appColors.primary.withValues(alpha: 0.08),
                    context.cardBackgroundColor,
                    context.cardBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: AppSectionHeader(
                          title: 'মাসের শেষে পূর্বাভাস',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      if (isStale)
                        AppChip(
                          label: 'রিফ্রেশ হচ্ছে...',
                          color: AppColors.warning,
                          selected: true,
                          compact: true,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton(
                        onPressed: () => ref
                            .read(predictionProvider.notifier)
                            .loadPrediction(forceRefresh: true),
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: context.secondaryTextColor,
                        ),
                        tooltip: 'রিফ্রেশ',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    BanglaFormatters.currency(prediction.predictedTotal),
                    style: AppTextStyles.heroAmount.copyWith(
                      color: context.appColors.primary,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'এখন পর্যন্ত: ${BanglaFormatters.currency(prediction.currentTotal)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppProgressBar(
                    value: progress,
                    color: context.appColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        'আত্মবিশ্বাস: ${_confidencePercentage(prediction.confidence)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'আপডেট: ${_formatRelativeTime(prediction.generatedAt)}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          label: 'দৈনিক গড়',
                          value: BanglaFormatters.currency(
                            prediction.dailyAverage,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MiniMetric(
                          label: 'বাকি দিন',
                          value:
                              '${BanglaFormatters.count(prediction.daysRemaining)} দিন',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _MiniMetric(
                          label: 'গত মাস',
                          value: BanglaFormatters.currency(
                            prediction.lastMonthTotal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (prediction.lastMonthTotal > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ComparisonHint(prediction: prediction),
                  ],
                  if (prediction.aiInsight.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.appColors.primary.withValues(
                          alpha: 0.06,
                        ),
                        borderRadius: AppRadius.cardAll,
                        border: Border.all(
                          color: context.appColors.primary.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡'),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              prediction.aiInsight,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isStale)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: context.isDarkMode ? 0.04 : 0.02,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ComparisonHint extends StatelessWidget {
  const _ComparisonHint({required this.prediction});

  final PredictionEntity prediction;

  @override
  Widget build(BuildContext context) {
    final compareColor = prediction.predictedTotal <= prediction.lastMonthTotal
        ? AppColors.success
        : AppColors.error;
    final difference = (prediction.predictedTotal - prediction.lastMonthTotal)
        .abs();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: compareColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardAll,
      ),
      child: Row(
        children: [
          Icon(
            prediction.predictedTotal <= prediction.lastMonthTotal
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 16,
            color: compareColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'গত মাসের তুলনায় ${BanglaFormatters.currency(difference)} ${prediction.predictedTotal <= prediction.lastMonthTotal ? 'কম' : 'বেশি'} হতে পারে',
              style: AppTextStyles.bodySmall.copyWith(color: compareColor),
            ),
          ),
        ],
      ),
    );
  }
}

int _confidencePercentage(PredictionConfidence confidence) {
  return switch (confidence) {
    PredictionConfidence.low => 45,
    PredictionConfidence.medium => 70,
    PredictionConfidence.high => 90,
  };
}

String _formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 60) {
    return '${math.max(diff.inMinutes, 1)} মিনিট আগে';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} ঘণ্টা আগে';
  }
  return BanglaFormatters.fullDate(dateTime);
}
