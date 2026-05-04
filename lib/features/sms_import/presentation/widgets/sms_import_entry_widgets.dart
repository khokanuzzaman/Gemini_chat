import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../models/sms_import_models.dart';
import '../providers/sms_import_provider.dart';
import '../screens/sms_history_screen.dart';
import '../screens/sms_import_screen.dart';

class SmsImportSettingsTile extends ConsumerWidget {
  const SmsImportSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(smsImportStatusProvider);
    final subtitle = statusAsync.maybeWhen(
      data: _settingsSubtitle,
      orElse: () => 'bKash, Nagad, Rocket, Bank SMS থেকে লেনদেন আনুন',
    );

    return AppListTile(
      key: const Key('sms-import-settings-tile'),
      leadingIcon: Icons.sms_rounded,
      leadingColor: AppColors.success,
      title: 'SMS History',
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => SmsHistoryScreen.push(context),
    );
  }

  static String _settingsSubtitle(SmsImportStatus status) {
    switch (status.permissionState) {
      case SmsPermissionState.unsupported:
        return 'এই ডিভাইসে SMS import সমর্থিত নয়';
      case SmsPermissionState.denied:
      case SmsPermissionState.permanentlyDenied:
        return 'History, totals ও import review দেখতে permission দিন';
      case SmsPermissionState.granted:
        if (!status.initialLedgerSyncComplete) {
          return 'Financial SMS sync করে monthly totals ও history দেখুন';
        }
        if (status.ledgerCount == 0) {
          return 'এখনও কোনো parsable financial SMS ledger তৈরি হয়নি';
        }
        final syncLabel = status.lastLedgerSyncAt == null
            ? 'শেষ sync অজানা'
            : 'শেষ sync ${BanglaFormatters.relativeDay(status.lastLedgerSyncAt!)}';
        return '$syncLabel · ${BanglaFormatters.count(status.ledgerCount)}টি history';
    }
  }
}

class SmsImportQuickActionChip extends StatelessWidget {
  const SmsImportQuickActionChip({super.key});

  @override
  Widget build(BuildContext context) {
    return AppChip(
      key: const Key('sms-import-dashboard-chip'),
      label: 'SMS Import',
      icon: Icons.sms_rounded,
      color: AppColors.success,
      onTap: () => SmsImportScreen.push(context),
    );
  }
}

class SmsImportDashboardTeaserCard extends ConsumerWidget {
  const SmsImportDashboardTeaserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(smsImportStatusProvider);

    return statusAsync.maybeWhen(
      data: (status) {
        final shouldShow =
            !status.initialLedgerSyncComplete ||
            status.importedCount == 0 ||
            status.permissionState != SmsPermissionState.granted;
        if (!shouldShow) {
          return const SizedBox.shrink();
        }

        final accent = switch (status.permissionState) {
          SmsPermissionState.granted => AppColors.success,
          SmsPermissionState.unsupported => AppColors.error,
          SmsPermissionState.denied ||
          SmsPermissionState.permanentlyDenied => AppColors.warning,
        };

        return AppCard(
          key: const Key('sms-import-dashboard-teaser'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 440;
              final content = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(AppRadius.card),
                    ),
                    child: Icon(Icons.mark_chat_unread_rounded, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS থেকে লেনদেন আনুন',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _teaserSubtitle(status),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    const SizedBox(height: AppSpacing.md),
                    AppActionButton(
                      label: 'খুলুন',
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => SmsImportScreen.push(context),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: AppSpacing.md),
                  AppActionButton(
                    label: 'খুলুন',
                    size: AppActionButtonSize.small,
                    variant: AppActionButtonVariant.secondary,
                    onPressed: () => SmsImportScreen.push(context),
                  ),
                ],
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  String _teaserSubtitle(SmsImportStatus status) {
    return switch (status.permissionState) {
      SmsPermissionState.unsupported =>
        'SMS import কেবল Android সমর্থিত ডিভাইসে কাজ করবে',
      SmsPermissionState.denied =>
        'প্রথমে SMS permission দিন, তারপর নতুন লেনদেন scan করুন',
      SmsPermissionState.permanentlyDenied =>
        'Permission বন্ধ আছে, Settings থেকে চালু করুন',
      SmsPermissionState.granted when !status.initialLedgerSyncComplete =>
        'পুরো SMS history sync করলে monthly insights দেখবেন',
      SmsPermissionState.granted when status.ledgerCount == 0 =>
        'এখনও কোনো parsable financial SMS ধরা পড়েনি',
      SmsPermissionState.granted when status.importedCount == 0 =>
        'History ready, কিন্তু এখনো কোনো expense বা income import করা হয়নি',
      SmsPermissionState.granted =>
        'শেষ sync ${BanglaFormatters.relativeDay(status.lastLedgerSyncAt ?? DateTime.now())}',
    };
  }
}

class SmsAutoImportSettingsCard extends ConsumerWidget {
  const SmsAutoImportSettingsCard({super.key});

  static const List<String> _sourceLabels = [
    'bKash',
    'Nagad',
    'Rocket',
    'Bank',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsAutoImportProvider);
    final controller = ref.read(smsAutoImportProvider.notifier);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (state.permissionState != SmsPermissionState.granted)
            _permissionNotice(context, state, controller),
          AppListTile(
            key: const Key('sms-auto-import-toggle'),
            leadingIcon: Icons.sms_rounded,
            leadingColor: AppColors.success,
            title: 'SMS স্বয়ংক্রিয় আমদানি',
            subtitle: 'বিকাশ, নগদ, ব্যাংক SMS থেকে স্বয়ংক্রিয়ভাবে খরচ/আয় যোগ করুন',
            trailing: Switch.adaptive(
              value: state.isEnabled,
              onChanged: state.isBusy
                  ? null
                  : (value) async {
                      if (value) {
                        await controller.enable();
                      } else {
                        await controller.disable();
                      }
                    },
            ),
          ),
          if (state.isEnabled) ...[
            Divider(height: 1, color: context.borderColor.withValues(alpha: 0.3)),
            AppListTile(
              leadingIcon: Icons.auto_mode_rounded,
              leadingColor: context.appColors.primary,
              title: 'স্বয়ংক্রিয় সংরক্ষণ',
              subtitle: 'নিশ্চিতকরণ ছাড়াই সংরক্ষণ করুন',
              trailing: Switch.adaptive(
                value: state.autoConfirm,
                onChanged: state.isBusy
                    ? null
                    : (_) => controller.toggleAutoConfirm(),
              ),
            ),
            Divider(height: 1, color: context.borderColor.withValues(alpha: 0.3)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.md,
                AppSpacing.cardPadding,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'কোন SMS উৎস থেকে আমদানি করবেন',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var index = 0; index < _sourceLabels.length; index++) ...[
                    _SourceToggleRow(
                      label: _sourceLabels[index],
                      enabled: state.enabledSources.contains(_sourceLabels[index]),
                      onChanged: state.isBusy
                          ? null
                          : () => controller.toggleSource(_sourceLabels[index]),
                    ),
                    if (index != _sourceLabels.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor.withValues(alpha: 0.3)),
            AppListTile(
              leadingIcon: Icons.sync_rounded,
              leadingColor: AppColors.warning,
              title: 'এখনই স্ক্যান করুন',
              subtitle: state.isRescanning
                  ? 'নতুন SMS খোঁজা হচ্ছে'
                  : 'Pending transaction আছে কি না এখনই দেখে নিন',
              trailing: state.isRescanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: state.isRescanning
                  ? null
                  : () async {
                      await controller.rescan();
                      if (!context.mounted) {
                        return;
                      }
                      final nextState = ref.read(smsAutoImportProvider);
                      final message = nextState.hasPending
                          ? '${BanglaFormatters.count(nextState.pendingTransactions.length)}টি নতুন লেনদেন পাওয়া গেছে'
                          : 'নতুন কোনো pending লেনদেন পাওয়া যায়নি';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    },
            ),
            Divider(height: 1, color: context.borderColor.withValues(alpha: 0.3)),
            AppListTile(
              leadingIcon: Icons.insights_outlined,
              leadingColor: context.appColors.primary,
              title: 'মোট আমদানি: ${BanglaFormatters.count(state.importedCount)} টি লেনদেন',
              subtitle: state.lastScanTime == null
                  ? 'শেষ স্ক্যান এখনো হয়নি'
                  : 'শেষ স্ক্যান: ${_relativeScanLabel(state.lastScanTime!)}',
              trailing: state.hasPending
                  ? _PendingBadge(count: state.pendingTransactions.length)
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () => SmsImportScreen.push(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _permissionNotice(
    BuildContext context,
    SmsAutoImportState state,
    SmsAutoImportNotifier controller,
  ) {
    final isBlocked = state.permissionState == SmsPermissionState.permanentlyDenied;
    final actionLabel = isBlocked ? 'সেটিংস খুলুন' : 'অনুমতি দিন';
    final action = isBlocked ? openAppSettings : controller.enable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 440;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            AppSpacing.md,
            AppSpacing.cardPadding,
            AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBlocked
                                    ? 'সেটিংস থেকে SMS permission দিন'
                                    : 'SMS পড়ার অনুমতি প্রয়োজন',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Permission ছাড়া নতুন financial SMS detect করা যাবে না।',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.secondaryTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppActionButton(
                      label: actionLabel,
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: action,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBlocked
                                ? 'সেটিংস থেকে SMS permission দিন'
                                : 'SMS পড়ার অনুমতি প্রয়োজন',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.primaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Permission ছাড়া নতুন financial SMS detect করা যাবে না।',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.secondaryTextColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppActionButton(
                      label: actionLabel,
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.secondary,
                      onPressed: action,
                    ),
                  ],
                ),
        );
      },
    );
  }

  static String _relativeScanLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    }
    if (difference.inHours < 1) {
      return '${BanglaFormatters.count(difference.inMinutes)} মিনিট আগে';
    }
    if (difference.inDays < 1) {
      return '${BanglaFormatters.count(difference.inHours)} ঘণ্টা আগে';
    }
    return BanglaFormatters.relativeDay(date, now: now);
  }
}

class _SourceToggleRow extends StatelessWidget {
  const _SourceToggleRow({
    required this.label,
    required this.enabled,
    this.onChanged,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
        ),
        Switch.adaptive(value: enabled, onChanged: onChanged == null ? null : (_) => onChanged!()),
      ],
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(AppRadius.card),
      ),
      child: Text(
        '${BanglaFormatters.count(count)} pending',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
