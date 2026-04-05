// Feature: Anomaly
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/anomaly_alert.dart';
import '../providers/anomaly_provider.dart';
import '../widgets/anomaly_alert_card.dart';

class AnomalyScreen extends StatelessWidget {
  const AnomalyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _AnomalyAppBar(),
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

    if (anomalyState.isDetecting && activeAlerts.isEmpty && dismissedAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'বিশ্লেষণ করা হচ্ছে...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (activeAlerts.isEmpty &&
        dismissedAlerts.isEmpty &&
        !anomalyState.isDetecting) {
      return RefreshIndicator(
        onRefresh: () => ref.read(anomalyProvider.notifier).detect(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            24,
            includeTopPadding ? 20 : 12,
            24,
            32,
          ),
          children: [
            if (anomalyState.lastDetected != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'সর্বশেষ: ${_formatRelativeTime(anomalyState.lastDetected!)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 60),
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: AppColors.success.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'সব স্বাভাবিক!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'গত ৩০ দিনে কোনো অস্বাভাবিক\nখরচ পাওয়া যায়নি।',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            Align(
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(anomalyProvider.notifier).detect();
                },
                icon: const Icon(Icons.search_rounded),
                label: const Text('আবার check করুন'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(anomalyProvider.notifier).detect(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          includeTopPadding ? 12 : 8,
          16,
          24,
        ),
        children: [
          if (anomalyState.lastDetected != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'সর্বশেষ: ${_formatRelativeTime(anomalyState.lastDetected!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (anomalyState.isDetecting)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'বিশ্লেষণ করা হচ্ছে...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Row(
            children: [
              _SeverityChip(
                count: anomalyState.highSeverityCount,
                label: 'উচ্চ',
                color: AnomalySeverity.high.color,
              ),
              const SizedBox(width: 8),
              _SeverityChip(
                count: anomalyState.mediumSeverityCount,
                label: 'মধ্যম',
                color: AnomalySeverity.medium.color,
              ),
              const SizedBox(width: 8),
              _SeverityChip(
                count: anomalyState.lowSeverityCount,
                label: 'কম',
                color: AnomalySeverity.low.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final alert in activeAlerts) ...[
            AnomalyAlertCard(alert: alert),
            const SizedBox(height: 10),
          ],
          if (dismissedAlerts.isNotEmpty)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  'Dismissed (${dismissedAlerts.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  for (final alert in dismissedAlerts) ...[
                    AnomalyAlertCard(alert: alert, isDismissed: true),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnomalyAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _AnomalyAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(anomalyProvider);
    return AppBar(
      title: const Text('অস্বাভাবিক খরচ'),
      actions: [
        IconButton(
          onPressed: () => ref.read(anomalyProvider.notifier).detect(),
          icon: const Icon(Icons.refresh_rounded),
        ),
        TextButton(
          onPressed: state.activeAlerts.isEmpty
              ? null
              : () => ref.read(anomalyProvider.notifier).dismissAll(),
          child: const Text('সব dismiss'),
        ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime lastDetected) {
  final difference = DateTime.now().difference(lastDetected);
  if (difference.inMinutes < 1) {
    return 'এইমাত্র';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} মিনিট আগে';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours} ঘন্টা আগে';
  }
  return '${difference.inDays} দিন আগে';
}
