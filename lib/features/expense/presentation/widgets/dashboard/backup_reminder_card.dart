import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/analytics/analytics_providers.dart';
import '../../../../../core/analytics/usage_analytics.dart';
import '../../../../../core/backup/backup_reminder_provider.dart';
import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../settings/backup_screen.dart';

/// "You have data but no recent backup" nudge — free for everyone.
///
/// Self-contained (own spacing, own provider) so the Home redesign can move it
/// with a one-line change. Renders nothing when there is nothing to say.
class BackupReminderCard extends ConsumerWidget {
  const BackupReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(backupReminderProvider).valueOrNull;
    if (decision == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.cardGap),
      child: _ReminderBody(daysSinceBackup: decision.daysSinceBackup),
    );
  }
}

class _ReminderBody extends ConsumerStatefulWidget {
  const _ReminderBody({required this.daysSinceBackup});

  final int? daysSinceBackup;

  @override
  ConsumerState<_ReminderBody> createState() => _ReminderBodyState();
}

class _ReminderBodyState extends ConsumerState<_ReminderBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(usageAnalyticsProvider)
            .backupReminder(BackupReminderAction.shown);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.daysSinceBackup;
    final title = days == null
        ? 'এখনো কোনো ব্যাকআপ নেই'
        : 'শেষ ব্যাকআপ ${BanglaFormatters.count(days)} দিন আগে';

    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_upload_outlined, color: context.tokens.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'আপনার হিসাব এই ফোনেই আছে। ফোন হারালে বা বদলালে তা চলে যেতে পারে — '
                      'Google Drive-এ ব্যাকআপ রাখুন।',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  label: 'এখনই ব্যাকআপ করুন',
                  size: AppActionButtonSize.small,
                  fullWidth: true,
                  onPressed: () {
                    ref
                        .read(usageAnalyticsProvider)
                        .backupReminder(BackupReminderAction.tapped);
                    Navigator.of(
                      context,
                    ).push(buildAppRoute(const BackupScreen()));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppActionButton(
                label: 'পরে',
                size: AppActionButtonSize.small,
                variant: AppActionButtonVariant.ghost,
                onPressed: () => snoozeBackupReminder(ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
