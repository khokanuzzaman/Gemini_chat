import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/anomaly_provider.dart';
import '../widgets/anomaly_alert_card.dart';

class AnomalyScreen extends StatelessWidget {
  const AnomalyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'অস্বাভাবিক খরচ',
      showOfflineBanner: false,
      body: AnomalyView(),
    );
  }
}

class AnomalyView extends ConsumerWidget {
  const AnomalyView({super.key, this.includeTopPadding = true});

  final bool includeTopPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomalyState = ref.watch(anomalyProvider);
    final activeAlerts = anomalyState.activeAlerts;
    final dismissedAlerts = anomalyState.dismissedAlerts;

    if (anomalyState.isDetecting &&
        activeAlerts.isEmpty &&
        dismissedAlerts.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          includeTopPadding ? AppSpacing.md : 0,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        child: const AppLoadingState.list(),
      );
    }

    if (activeAlerts.isEmpty &&
        dismissedAlerts.isEmpty &&
        !anomalyState.isDetecting) {
      return RefreshIndicator(
        onRefresh: () => ref.read(anomalyProvider.notifier).detect(),
        color: context.appColors.primary,
        backgroundColor: context.cardBackgroundColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            includeTopPadding ? AppSpacing.md : 0,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            if (anomalyState.lastDetected != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'সর্বশেষ বিশ্লেষণ: ${_formatRelativeTime(anomalyState.lastDetected!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            const AppEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'কোনো অস্বাভাবিক খরচ নেই',
              subtitle: 'আপনার খরচের ধরন স্বাভাবিক আছে',
            ),
            const SizedBox(height: AppSpacing.md),
            AppActionButton(
              label: 'আবার বিশ্লেষণ করুন',
              icon: Icons.refresh_rounded,
              fullWidth: true,
              onPressed: () => ref.read(anomalyProvider.notifier).detect(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(anomalyProvider.notifier).detect(),
      color: context.appColors.primary,
      backgroundColor: context.cardBackgroundColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          includeTopPadding ? AppSpacing.md : 0,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        children: [
          if (anomalyState.lastDetected != null)
            AppFadeSlideIn(
              child: Text(
                'সর্বশেষ বিশ্লেষণ: ${_formatRelativeTime(anomalyState.lastDetected!)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          if (anomalyState.lastDetected != null)
            const SizedBox(height: AppSpacing.md),
          if (anomalyState.isDetecting)
            AppFadeSlideIn(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.mutedSurfaceColor,
                  borderRadius: AppRadius.cardAll,
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'বিশ্লেষণ আপডেট হচ্ছে...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (anomalyState.isDetecting) const SizedBox(height: AppSpacing.md),
          AppFadeSlideIn(
            delay: AppMotion.staggerDelay,
            child: Row(
              children: [
                Expanded(
                  child: _SeverityStatCard(
                    label: 'উচ্চ',
                    count: anomalyState.highSeverityCount,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SeverityStatCard(
                    label: 'মাঝারি',
                    count: anomalyState.mediumSeverityCount,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SeverityStatCard(
                    label: 'কম',
                    count: anomalyState.lowSeverityCount,
                    color: context.appColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          AppFadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: AppSectionHeader(
              title: 'অস্বাভাবিক খরচ সতর্কতা',
              subtitle: activeAlerts.isEmpty
                  ? 'কোনো সক্রিয় সতর্কতা নেই'
                  : '${activeAlerts.length} টি সক্রিয় সতর্কতা',
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < activeAlerts.length; i++) ...[
            AppFadeSlideIn(
              delay: Duration(
                milliseconds: 120 + (AppMotion.staggerDelay.inMilliseconds * i),
              ),
              child: AnomalyAlertCard(alert: activeAlerts[i]),
            ),
            if (i != activeAlerts.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          if (dismissedAlerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'বাদ দেওয়া সতর্কতা (${dismissedAlerts.length})',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < dismissedAlerts.length; i++) ...[
                    AnomalyAlertCard(
                      alert: dismissedAlerts[i],
                      isDismissed: true,
                    ),
                    if (i != dismissedAlerts.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityStatCard extends StatelessWidget {
  const _SeverityStatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.statLabel.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$count', style: AppTextStyles.statValue.copyWith(color: color)),
        ],
      ),
    );
  }
}

String _formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes <= 0 ? 1 : difference.inMinutes} মিনিট আগে';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} ঘণ্টা আগে';
  }
  return BanglaFormatters.fullDate(dateTime);
}
