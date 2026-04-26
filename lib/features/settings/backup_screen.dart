import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/backup_progress.dart';
import '../../core/backup/backup_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bangla_formatters.dart';
import '../../core/widgets/widgets.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupStateAsync = ref.watch(backupStateProvider);
    final backupState = backupStateAsync.valueOrNull ?? BackupState.initial();
    final notifier = ref.read(backupStateProvider.notifier);
    final hasCloudBackup = backupState.cloudBackupInfo != null;
    final activeProgress = backupState.activeProgress;

    Widget body;
    if (backupStateAsync.isLoading && backupStateAsync.valueOrNull == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppStaggeredList(
          children: [
            _BackupHeroCard(
              state: backupState,
              activeProgress: activeProgress,
              formatDateTime: _formatDateTime,
              formatSize: _formatSize,
            ),
            if (backupState.errorMessage != null) ...[
              AppCard(
                child: Text(
                  backupState.errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (!backupState.isSignedIn) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Google দিয়ে সাইন ইন করুন',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'আপনার Google Drive-এ ব্যাকআপ রাখুন',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppActionButton(
                      label: 'Google দিয়ে সাইন ইন',
                      icon: Icons.login_rounded,
                      fullWidth: true,
                      isLoading: backupStateAsync.isLoading,
                      onPressed: backupStateAsync.isLoading
                          ? null
                          : () => notifier.signIn(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ] else ...[
              AppCard(
                padding: EdgeInsets.zero,
                child: AppListTile(
                  leadingIcon: Icons.account_circle_rounded,
                  leadingColor: context.appColors.primary,
                  title: backupState.displayName ?? 'Google অ্যাকাউন্ট',
                  subtitle: backupState.userEmail ?? '',
                  trailing: TextButton(
                    onPressed: backupState.isBusy
                        ? null
                        : () async {
                            await notifier.signOut();
                            if (!context.mounted) {
                              return;
                            }
                            await notifier.signIn();
                          },
                    child: const Text('পরিবর্তন'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (activeProgress != null && !activeProgress.isBlocking) ...[
              _BackupProgressCard(
                key: const Key('backup-progress-card'),
                progress: activeProgress,
                title: backupState.progressTitle ?? 'ব্যাকআপ চলছে',
                detail: backupState.progressDetail ?? 'প্রস্তুতি নেওয়া হচ্ছে',
                formatSize: _formatSize,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            const AppSectionHeader(title: 'ব্যাকআপ'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppListTile(
                    leadingIcon: Icons.history_rounded,
                    title: 'শেষ ব্যাকআপ',
                    subtitle: backupState.lastBackupTime == null
                        ? 'কখনো হয়নি'
                        : '${_formatDateTime(backupState.lastBackupTime!)} · ${_formatSize(backupState.lastBackupSizeBytes ?? 0)}',
                    trailing: const SizedBox.shrink(),
                  ),
                  Divider(color: context.borderColor.withValues(alpha: 0.3)),
                  AppListTile(
                    leadingIcon: Icons.cloud_rounded,
                    title: 'Drive-এ সংরক্ষিত',
                    subtitle: backupState.cloudBackupInfo == null
                        ? 'নেই'
                        : '${_formatDateTime(backupState.cloudBackupInfo!.modifiedAt)} · ${_formatSize(backupState.cloudBackupInfo!.sizeBytes)}',
                    trailing: IconButton(
                      onPressed: backupState.isBusy
                          ? null
                          : () => notifier.refreshCloudInfo(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppActionButton(
                    label: 'এখনই ব্যাকআপ করুন',
                    fullWidth: true,
                    isLoading: backupState.isBackingUp,
                    onPressed: (!backupState.isSignedIn || backupState.isBusy)
                        ? null
                        : () async {
                            final result = await notifier.createBackup();
                            if (!context.mounted) {
                              return;
                            }
                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text(
                                    'ব্যাকআপ সম্পন্ন ✓ (${_formatSize(result.sizeBytes ?? 0)})',
                                  ),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text(
                                  result.errorMessage ??
                                      'ব্যাকআপ সম্পন্ন হয়নি',
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppListTile(
                leadingIcon: Icons.schedule_rounded,
                title: 'স্বয়ংক্রিয় ব্যাকআপ',
                subtitle: 'প্রতিদিন অ্যাপ খোলার সময় ব্যাকআপ হবে',
                trailing: Switch.adaptive(
                  value: backupState.autoBackupEnabled,
                  onChanged: backupState.isBusy
                      ? null
                      : notifier.setAutoBackupEnabled,
                ),
                onTap: backupState.isBusy
                    ? null
                    : () => notifier.setAutoBackupEnabled(
                        !backupState.autoBackupEnabled,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'রিস্টোর'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'রিস্টোর করলে বর্তমান সব ডেটা মুছে যাবে',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hasCloudBackup
                        ? 'Drive ব্যাকআপ: ${_formatDateTime(backupState.cloudBackupInfo!.modifiedAt)} · ${_formatSize(backupState.cloudBackupInfo!.sizeBytes)}'
                        : 'কোনো ব্যাকআপ নেই',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppActionButton(
                    label: 'ব্যাকআপ থেকে রিস্টোর করুন',
                    fullWidth: true,
                    variant: AppActionButtonVariant.danger,
                    onPressed:
                        (!hasCloudBackup ||
                            backupState.isBusy ||
                            !backupState.isSignedIn)
                        ? null
                        : () async {
                            final shouldRestore = await _showConfirmDialog(
                              context: context,
                              title: 'রিস্টোর নিশ্চিত করুন',
                              message:
                                  'এটি করলে বর্তমান ডেটা মুছে গিয়ে Drive ব্যাকআপ থেকে নতুন করে আসবে।',
                              confirmLabel: 'রিস্টোর',
                            );
                            if (shouldRestore != true) {
                              return;
                            }

                            final result = await notifier.restoreBackup();
                            if (!context.mounted) {
                              return;
                            }
                            if (result.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('রিস্টোর সম্পন্ন ✓'),
                                ),
                              );
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.error,
                                content: Text(
                                  result.errorMessage ??
                                      'রিস্টোর সম্পন্ন হয়নি',
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const AppSectionHeader(title: 'বিপদজনক'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppListTile(
                leadingIcon: Icons.delete_forever_rounded,
                leadingColor: AppColors.error,
                title: 'সব ব্যাকআপ মুছুন',
                subtitle: 'Google Drive appDataFolder থেকে সব ব্যাকআপ মুছে দিন',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error,
                ),
                onTap: backupState.isBusy
                    ? null
                    : () async {
                        final shouldDelete = await _showConfirmDialog(
                          context: context,
                          title: 'সব ব্যাকআপ মুছবেন?',
                          message:
                              'Google Drive-এ থাকা ব্যাকআপগুলো স্থায়ীভাবে মুছে যাবে।',
                          confirmLabel: 'মুছুন',
                          isDanger: true,
                        );
                        if (shouldDelete != true) {
                          return;
                        }
                        final success = await notifier.deleteAllBackups();
                        if (!context.mounted) {
                          return;
                        }
                        if (!success) {
                          final message =
                              ref
                                  .read(backupStateProvider)
                                  .valueOrNull
                                  ?.errorMessage ??
                              'ব্যাকআপ মুছতে সমস্যা হয়েছে';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(message),
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('সব ব্যাকআপ মুছে ফেলা হয়েছে'),
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !backupState.isRestoring,
      child: AppPageScaffold(
        title: 'ডেটা ব্যাকআপ',
        useGradientBackground: true,
        body: Stack(
          children: [
            body,
            if (activeProgress?.isBlocking ?? false)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.46),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: _BackupProgressCard(
                          key: const Key('backup-progress-overlay'),
                          progress: activeProgress!,
                          title: backupState.progressTitle ?? 'রিস্টোর চলছে',
                          detail:
                              backupState.progressDetail ??
                              'প্রস্তুতি নেওয়া হচ্ছে',
                          formatSize: _formatSize,
                          isOverlay: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${BanglaFormatters.fullDate(dateTime)} · ${BanglaFormatters.time(dateTime)}';
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppActionButton(
                  label: 'বাতিল',
                  variant: AppActionButtonVariant.ghost,
                  fullWidth: true,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppActionButton(
                  label: confirmLabel,
                  variant: isDanger
                      ? AppActionButtonVariant.danger
                      : AppActionButtonVariant.primary,
                  fullWidth: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int sizeBytes) {
    if (sizeBytes <= 0) {
      return '০ B';
    }
    if (sizeBytes < 1024) {
      return '${_toBanglaDigits(sizeBytes.toString())} B';
    }
    final kb = sizeBytes / 1024;
    if (kb < 1024) {
      return '${_toBanglaDigits(kb.toStringAsFixed(1))} KB';
    }
    final mb = kb / 1024;
    return '${_toBanglaDigits(mb.toStringAsFixed(1))} MB';
  }

  String _toBanglaDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var result = input;
    for (var index = 0; index < english.length; index++) {
      result = result.replaceAll(english[index], bangla[index]);
    }
    return result;
  }
}

class _BackupProgressCard extends StatelessWidget {
  const _BackupProgressCard({
    super.key,
    required this.progress,
    required this.title,
    required this.detail,
    required this.formatSize,
    this.isOverlay = false,
  });

  final BackupProgressState progress;
  final String title;
  final String detail;
  final String Function(int sizeBytes) formatSize;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final progressPercent =
        '${_toBanglaDigits((progress.clampedOverallProgress * 100).round().toString())}%';
    final icon = switch (progress.operation) {
      BackupOperationKind.backup => Icons.cloud_upload_rounded,
      BackupOperationKind.restore => Icons.settings_backup_restore_rounded,
    };
    final accent = switch (progress.operation) {
      BackupOperationKind.backup => context.appColors.primary,
      BackupOperationKind.restore => AppColors.warning,
    };
    final gradient = isOverlay
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              accent.withValues(alpha: context.isDarkMode ? 0.22 : 0.14),
              context.cardBackgroundColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final stepText =
        'ধাপ ${BanglaFormatters.count(progress.currentStep)}/${BanglaFormatters.count(progress.totalSteps)}';
    final byteText = progress.hasByteProgress
        ? '${formatSize(progress.processedBytes!)} / ${formatSize(progress.totalBytes!)}'
        : null;
    final startedAtText = 'শুরু ${BanglaFormatters.time(progress.startedAt)}';
    final stageLabel = _stageLabel(progress.stage);
    final helperText = switch (progress.operation) {
      BackupOperationKind.backup =>
        'Encrypted কপি Google Drive appDataFolder-এ যাচ্ছে',
      BackupOperationKind.restore =>
        'রিস্টোর শেষ না হওয়া পর্যন্ত এই স্ক্রিন খোলা রাখুন',
    };

    return AppCard(
      elevation: isOverlay ? 5 : 2,
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isOverlay ? 0.18 : 0.12),
                  borderRadius: AppRadius.cardAll,
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isOverlay
                            ? Colors.white
                            : context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        detail,
                        key: ValueKey(detail),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isOverlay
                              ? Colors.white.withValues(alpha: 0.78)
                              : context.secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ProgressBadge(
                label: progressPercent,
                color: accent,
                isOverlay: isOverlay,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ProgressBadge(
                label: stageLabel,
                color: accent,
                isOverlay: isOverlay,
                icon: Icons.bolt_rounded,
              ),
              _ProgressBadge(
                label: stepText,
                color: accent,
                isOverlay: isOverlay,
                icon: Icons.layers_rounded,
              ),
              _ProgressBadge(
                label: startedAtText,
                color: accent,
                isOverlay: isOverlay,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: progress.clampedOverallProgress,
            color: accent,
            backgroundColor: isOverlay
                ? Colors.white.withValues(alpha: 0.18)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  stepText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isOverlay
                        ? Colors.white.withValues(alpha: 0.78)
                        : context.secondaryTextColor,
                  ),
                ),
              ),
              if (byteText != null)
                Text(
                  byteText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isOverlay
                        ? Colors.white.withValues(alpha: 0.78)
                        : context.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            helperText,
            style: AppTextStyles.bodySmall.copyWith(
              color: isOverlay
                  ? Colors.white.withValues(alpha: 0.72)
                  : context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupHeroCard extends StatelessWidget {
  const _BackupHeroCard({
    required this.state,
    required this.activeProgress,
    required this.formatDateTime,
    required this.formatSize,
  });

  final BackupState state;
  final BackupProgressState? activeProgress;
  final String Function(DateTime dateTime) formatDateTime;
  final String Function(int sizeBytes) formatSize;

  @override
  Widget build(BuildContext context) {
    final amount = switch ((state.isSignedIn, activeProgress != null)) {
      (false, _) => 'সেটআপ বাকি',
      (true, true) =>
        '${_toBanglaDigits((activeProgress!.clampedOverallProgress * 100).round().toString())}%',
      _ when state.cloudBackupInfo != null => formatSize(
        state.cloudBackupInfo!.sizeBytes,
      ),
      _ when state.lastBackupTime != null => formatSize(
        state.lastBackupSizeBytes ?? 0,
      ),
      _ => 'প্রস্তুত',
    };
    final subtitle = switch ((state.isSignedIn, activeProgress != null)) {
      (false, _) => 'একবার সাইন ইন করলে encrypted backup আপনার Drive-এ থাকবে',
      (true, true) =>
        '${state.progressDetail ?? 'ব্যাকআপ প্রস্তুত হচ্ছে'} · ${BanglaFormatters.count(activeProgress!.currentStep)}/${BanglaFormatters.count(activeProgress!.totalSteps)} ধাপ',
      _ when state.cloudBackupInfo != null =>
        'সর্বশেষ ক্লাউড কপি ${formatDateTime(state.cloudBackupInfo!.modifiedAt)}',
      _ when state.lastBackupTime != null =>
        'শেষ সফল ব্যাকআপ ${formatDateTime(state.lastBackupTime!)}',
      _ => 'নতুন ব্যাকআপ নিলে encrypted কপি appDataFolder-এ যাবে',
    };
    final gradient = switch ((state.isSignedIn, activeProgress?.operation)) {
      (false, _) => AppGradients.warning,
      (_, BackupOperationKind.restore) => AppGradients.warning,
      (_, BackupOperationKind.backup) => context.primaryGradient,
      _ when state.cloudBackupInfo != null => AppGradients.success,
      _ => context.primaryGradient,
    };

    return AppHeroCard(
      label: 'Google Drive ব্যাকআপ',
      amount: amount,
      subtitle: subtitle,
      icon: Icons.cloud_done_rounded,
      gradient: gradient,
      trailing: _HeroStatusBadge(state: state, activeProgress: activeProgress),
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.state, required this.activeProgress});

  final BackupState state;
  final BackupProgressState? activeProgress;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch ((
      state.isSignedIn,
      activeProgress?.operation,
    )) {
      (false, _) => ('সাইন ইন', const Color(0xFFFFF3BF)),
      (_, BackupOperationKind.restore) => ('রিস্টোর', const Color(0xFFFFF3BF)),
      (_, BackupOperationKind.backup) => ('লাইভ', const Color(0xFFD7F7E7)),
      _ when state.cloudBackupInfo != null => (
        'ক্লাউড রেডি',
        const Color(0xFFD7F7E7),
      ),
      _ => ('রেডি', const Color(0xFFE6EDFF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(AppRadius.card),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.label,
    required this.color,
    required this.isOverlay,
    this.icon,
  });

  final String label;
  final Color color;
  final bool isOverlay;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final background = isOverlay
        ? Colors.white.withValues(alpha: 0.1)
        : color.withValues(alpha: context.isDarkMode ? 0.2 : 0.12);
    final foreground = isOverlay ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(AppRadius.chip),
        border: Border.all(
          color: isOverlay
              ? Colors.white.withValues(alpha: 0.14)
              : color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.chipLabel.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

String _stageLabel(BackupProgressStage stage) {
  return switch (stage) {
    BackupProgressStage.preparing => 'প্রস্তুতি',
    BackupProgressStage.exporting => 'এক্সপোর্ট',
    BackupProgressStage.compressing => 'কম্প্রেস',
    BackupProgressStage.encrypting => 'এনক্রিপ্ট',
    BackupProgressStage.uploading => 'আপলোড',
    BackupProgressStage.downloading => 'ডাউনলোড',
    BackupProgressStage.decrypting => 'ডিক্রিপ্ট',
    BackupProgressStage.decoding => 'ডিকোড',
    BackupProgressStage.importing => 'ইমপোর্ট',
    BackupProgressStage.finalizing => 'শেষ ধাপ',
    BackupProgressStage.completed => 'সম্পন্ন',
    BackupProgressStage.failed => 'ব্যর্থ',
  };
}

String _toBanglaDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  var result = input;
  for (var index = 0; index < english.length; index++) {
    result = result.replaceAll(english[index], bangla[index]);
  }
  return result;
}
