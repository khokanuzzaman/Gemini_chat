import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_import_entry.dart';
import '../../../../core/sms/sms_import_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../models/sms_import_models.dart';
import '../providers/sms_import_provider.dart';
import '../widgets/sms_import_edit_sheet.dart';
import 'sms_history_screen.dart';

class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});

  static Future<T?> push<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(AppSlideRoute(builder: (_) => const SmsImportScreen()));
  }

  @override
  ConsumerState<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends ConsumerState<SmsImportScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(smsImportControllerProvider.notifier).refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsImportControllerProvider);
    final controller = ref.read(smsImportControllerProvider.notifier);
    final autoImportState = ref.watch(smsAutoImportProvider);
    final autoImportController = ref.read(smsAutoImportProvider.notifier);

    return AppPageScaffold(
      title: 'SMS Auto-Import',
      useGradientBackground: true,
      showOfflineBanner: false,
      bottomNavigationBar: state.hasCandidates
          ? _ImportFooter(
              selectedCount: state.selectedCount,
              isImporting: state.isImporting,
              onImport: () async {
                final outcome = await controller.importSelected();
                if (!context.mounted ||
                    (!outcome.hasSuccess && !outcome.hasFailures)) {
                  return;
                }
                await _showImportSummary(context, outcome);
              },
            )
          : null,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 480;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                _StatusHero(state: state),
                const SizedBox(height: AppSpacing.sm),
                if (isCompact)
                  AppActionButton(
                    key: const Key('sms-import-open-history'),
                    label: 'SMS History',
                    icon: Icons.timeline_rounded,
                    size: AppActionButtonSize.small,
                    variant: AppActionButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => SmsHistoryScreen.push(context),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppActionButton(
                      key: const Key('sms-import-open-history'),
                      label: 'SMS History',
                      icon: Icons.timeline_rounded,
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.secondary,
                      onPressed: () => SmsHistoryScreen.push(context),
                    ),
                  ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                if (autoImportState.hasPending) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  _PendingAutoImportPanel(
                    state: autoImportState,
                    onSaveAll: () async {
                      final outcome = await autoImportController
                          .confirmAndSaveAll();
                      if (!context.mounted ||
                          (!outcome.hasSuccess && !outcome.hasFailures)) {
                        return;
                      }
                      await _showImportSummary(context, outcome);
                    },
                    onDismissAll: autoImportController.dismissAll,
                    onSaveEntry: (entry) async {
                      final error = await autoImportController.confirmAndSave(
                        entry,
                      );
                      if (error == null || !context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    },
                    onDismissEntry: autoImportController.dismissEntry,
                  ),
                ],
                if (state.latestScanResult != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  _ScanSummaryStrip(
                    result: state.latestScanResult!,
                    readyCount: state.candidates.length,
                  ),
                ],
                if (state.hasCandidates) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppSegmentedTabs(
                    tabs: const ['সব', 'খরচ', 'আয়'],
                    selectedIndex: state.activeTab.index,
                    compact: isCompact,
                    onChanged: (index) {
                      controller.setTab(SmsImportTabFilter.values[index]);
                    },
                    tabKeys: const [
                      Key('sms-import-tab-all'),
                      Key('sms-import-tab-expense'),
                      Key('sms-import-tab-income'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 460;
                      final actions = Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          TextButton(
                            key: const Key('sms-import-select-all'),
                            onPressed: state.isImporting
                                ? null
                                : controller.selectAllVisible,
                            child: const Text('সব নির্বাচন'),
                          ),
                          TextButton(
                            key: const Key('sms-import-clear-selection'),
                            onPressed: state.isImporting
                                ? null
                                : controller.clearVisibleSelection,
                            child: const Text('সব বাদ'),
                          ),
                        ],
                      );
                      final countLabel = Text(
                        '${BanglaFormatters.count(state.filteredCandidates.length)}টি দেখা যাচ্ছে',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            actions,
                            const SizedBox(height: AppSpacing.xs),
                            countLabel,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: actions),
                          const SizedBox(width: AppSpacing.sm),
                          countLabel,
                        ],
                      );
                    },
                  ),
                ],
                ..._buildContentChildren(context, state, controller),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContentChildren(
    BuildContext context,
    SmsImportScreenState state,
    SmsImportController controller,
  ) {
    if (state.isScanning) {
      return const [
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.list(),
      ];
    }

    switch (state.permissionState) {
      case SmsPermissionState.unsupported:
        return [
          _PermissionStateView(
            icon: Icons.phone_android_outlined,
            title: 'এই ডিভাইসে SMS import সমর্থিত নয়',
            subtitle:
                'PocketPilot AI এখন Android ডিভাইসের SMS inbox থেকে লেনদেন পড়তে পারে।',
          ),
        ];
      case SmsPermissionState.permanentlyDenied:
        return [
          _PermissionStateView(
            icon: Icons.lock_outline_rounded,
            title: 'SMS permission বন্ধ আছে',
            subtitle:
                'Settings থেকে SMS permission চালু করলে নতুন লেনদেন scan করা যাবে।',
            actionLabel: 'Settings খুলুন',
            actionKey: const Key('sms-import-open-settings-cta'),
            onAction: openAppSettings,
          ),
        ];
      case SmsPermissionState.denied:
        return [
          _PermissionStateView(
            icon: Icons.mark_chat_unread_outlined,
            title: 'SMS permission দরকার',
            subtitle:
                'bKash, Nagad, Rocket, Bank SMS থেকে খরচ ও আয় আনতে permission দিন।',
            actionLabel: 'অনুমতি দিন',
            actionKey: const Key('sms-import-permission-cta'),
            onAction: controller.requestPermission,
          ),
        ];
      case SmsPermissionState.granted:
        break;
    }

    if (!state.scanAttempted) {
      return [
        _PermissionStateView(
          icon: Icons.sms_rounded,
          title: 'নতুন SMS scan করতে প্রস্তুত',
          subtitle:
              'নতুন financial SMS খুঁজে category ও wallet suggestion সহ review list দেখানো হবে।',
          actionLabel: 'SMS Scan করুন',
          actionKey: const Key('sms-import-scan-cta'),
          onAction: controller.scanForNewTransactions,
        ),
      ];
    }

    if (state.hasCandidates) {
      final groups = _buildGroups(state.filteredCandidates);
      return [
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < groups.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == groups.length - 1 ? 0 : AppSpacing.sectionGap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GroupHeader(group: groups[index]),
                const SizedBox(height: AppSpacing.sm),
                for (final candidate in groups[index].candidates) ...[
                  _CandidateRow(
                    key: Key('sms-import-row-${candidate.sms.id}'),
                    candidate: candidate,
                    draft: state.drafts[candidate.sms.id]!,
                    isSelected: state.selectedIds.contains(candidate.sms.id),
                    errorText: state.rowErrors[candidate.sms.id],
                    isLocked: state.isImporting,
                    onSelectionChanged: (selected) {
                      controller.toggleCandidate(candidate.sms.id, selected);
                    },
                    onTap: () async {
                      final updated = await showSmsImportEditSheet(
                        context,
                        candidate: candidate,
                        draft: state.drafts[candidate.sms.id]!,
                      );
                      if (updated != null) {
                        controller.updateDraft(updated);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
      ];
    }

    final latest = state.latestScanResult;
    if (latest == null) {
      return const [SizedBox.shrink()];
    }

    if (latest.scannedCount == 0) {
      return [
        _PermissionStateView(
          icon: Icons.inbox_outlined,
          title: 'নতুন কোনো SMS পাওয়া যায়নি',
          subtitle: 'Inbox-এ নতুন SMS এলে আবার scan করুন।',
          actionLabel: 'আবার স্ক্যান করুন',
          onAction: controller.scanForNewTransactions,
        ),
      ];
    }

    if (latest.financialCount == 0) {
      return [
        _PermissionStateView(
          icon: Icons.filter_alt_off_outlined,
          title: 'Financial SMS পাওয়া যায়নি',
          subtitle: 'এই batch-এ খরচ বা আয়ের মতো কোনো SMS ধরা পড়েনি।',
          actionLabel: 'আবার স্ক্যান করুন',
          onAction: controller.scanForNewTransactions,
        ),
      ];
    }

    if (state.lastScanReadyCount > 0 && state.rowErrors.isEmpty) {
      return [
        _PermissionStateView(
          icon: Icons.task_alt_rounded,
          title: 'সব নির্বাচিত লেনদেন ইমপোর্ট হয়েছে',
          subtitle:
              '${BanglaFormatters.count(state.lastScanReadyCount)}টি SMS থেকে লেনদেন সংরক্ষণ করা হয়েছে। চাইলে আবার scan করতে পারেন।',
          actionLabel: 'আবার স্ক্যান করুন',
          onAction: controller.scanForNewTransactions,
        ),
      ];
    }

    return [
      _PermissionStateView(
        icon: Icons.verified_rounded,
        title: 'নতুন কিছু বাকি নেই',
        subtitle: latest.duplicateCount > 0
            ? '${BanglaFormatters.count(latest.duplicateCount)}টি duplicate আগে থেকেই import করা ছিল।'
            : 'এই scan-এ import করার মতো নতুন expense বা income পাওয়া যায়নি।',
        actionLabel: 'আবার স্ক্যান করুন',
        onAction: controller.scanForNewTransactions,
      ),
    ];
  }

  Future<void> _showImportSummary(
    BuildContext context,
    SmsImportBatchOutcome outcome,
  ) {
    final title = outcome.hasFailures
        ? 'আংশিক ইমপোর্ট সম্পন্ন'
        : 'ইমপোর্ট সম্পন্ন';
    return AppBottomSheet.show<void>(
      context: context,
      title: title,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 420 ? 1 : 3;
              final spacing = AppSpacing.sm;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              final cards = [
                AppStatCard(
                  label: 'ইমপোর্ট হয়েছে',
                  value: BanglaFormatters.count(outcome.importedCount),
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.success,
                  valueColor: AppColors.success,
                ),
                AppStatCard(
                  label: 'ব্যর্থ',
                  value: BanglaFormatters.count(outcome.failedCount),
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.error,
                  valueColor: AppColors.error,
                ),
                AppStatCard(
                  label: 'স্কিপ',
                  value: BanglaFormatters.count(outcome.skippedCount),
                  icon: Icons.remove_circle_outline_rounded,
                  iconColor: AppColors.warning,
                  valueColor: AppColors.warning,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final card in cards)
                    SizedBox(width: itemWidth, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            outcome.hasFailures
                ? 'যেগুলো ব্যর্থ হয়েছে, সেগুলো তালিকায় রয়ে গেছে। edit করে আবার import করতে পারবেন।'
                : 'সব নির্বাচিত SMS নিরাপদে সংরক্ষণ হয়েছে।',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.state});

  final SmsImportScreenState state;

  @override
  Widget build(BuildContext context) {
    final importedLabel = '${BanglaFormatters.count(state.importedCount)}টি';
    final subtitle = state.lastImportDate == null
        ? 'নতুন financial SMS scan করে category ও wallet suggestion সহ review করুন'
        : 'শেষ import ${BanglaFormatters.relativeDay(state.lastImportDate!)} · আবার scan করতে পারেন';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;
        return AppHeroCard(
          label: 'SMS Auto-Import',
          amount: importedLabel,
          subtitle: subtitle,
          icon: Icons.sms_rounded,
          gradient: AppGradients.primary,
          trailing: isCompact
              ? null
              : _HeroBadge(permissionState: state.permissionState),
          height: isCompact ? 182 : 164,
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.permissionState});

  final SmsPermissionState permissionState;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (permissionState) {
      SmsPermissionState.granted => ('Ready', const Color(0xFFC8FACC)),
      SmsPermissionState.denied => ('Permission', const Color(0xFFFFE7A3)),
      SmsPermissionState.permanentlyDenied => (
        'Blocked',
        const Color(0xFFFFD2D2),
      ),
      SmsPermissionState.unsupported => (
        'Unsupported',
        const Color(0xFFE6E9FF),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
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

class _ScanSummaryStrip extends StatelessWidget {
  const _ScanSummaryStrip({required this.result, required this.readyCount});

  final SmsImportResult result;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AppStatCard(
        label: 'স্ক্যান',
        value: BanglaFormatters.count(result.scannedCount),
        icon: Icons.mark_chat_read_rounded,
      ),
      AppStatCard(
        label: 'ফিন্যান্স',
        value: BanglaFormatters.count(result.financialCount),
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.success,
      ),
      AppStatCard(
        label: 'ডুপ্লিকেট',
        value: BanglaFormatters.count(result.duplicateCount),
        icon: Icons.copy_all_rounded,
        iconColor: AppColors.warning,
      ),
      AppStatCard(
        label: 'প্রস্তুত',
        value: BanglaFormatters.count(readyCount),
        icon: Icons.playlist_add_check_circle_rounded,
        iconColor: context.appColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 720
            ? 2
            : 4;
        final spacing = AppSpacing.sm;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingAutoImportPanel extends StatelessWidget {
  const _PendingAutoImportPanel({
    required this.state,
    required this.onSaveAll,
    required this.onDismissAll,
    required this.onSaveEntry,
    required this.onDismissEntry,
  });

  final SmsAutoImportState state;
  final Future<void> Function() onSaveAll;
  final Future<void> Function() onDismissAll;
  final Future<void> Function(SmsImportEntry entry) onSaveEntry;
  final Future<void> Function(SmsImportEntry entry) onDismissEntry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 440;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.appColors.primary.withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(AppRadius.card),
                    ),
                    child: Icon(
                      Icons.notification_important_rounded,
                      color: context.appColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${BanglaFormatters.count(state.pendingTransactions.length)}টি auto-detected লেনদেন অপেক্ষায় আছে',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'নিশ্চিত করলে এগুলো expense বা income হিসেবে সংরক্ষণ হবে।',
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
              if (isCompact)
                Column(
                  children: [
                    AppActionButton(
                      label: 'সব সংরক্ষণ',
                      size: AppActionButtonSize.small,
                      fullWidth: true,
                      onPressed: state.isBusy ? null : onSaveAll,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppActionButton(
                      label: 'সব বাদ',
                      size: AppActionButtonSize.small,
                      fullWidth: true,
                      variant: AppActionButtonVariant.ghost,
                      onPressed: state.isBusy ? null : onDismissAll,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: AppActionButton(
                        label: 'সব সংরক্ষণ',
                        size: AppActionButtonSize.small,
                        onPressed: state.isBusy ? null : onSaveAll,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppActionButton(
                        label: 'সব বাদ',
                        size: AppActionButtonSize.small,
                        variant: AppActionButtonVariant.ghost,
                        onPressed: state.isBusy ? null : onDismissAll,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),
              for (
                var index = 0;
                index < state.pendingTransactions.length && index < 3;
                index++
              ) ...[
                if (index > 0)
                  Divider(
                    height: AppSpacing.lg,
                    color: context.borderColor.withValues(alpha: 0.3),
                  ),
                _PendingAutoImportRow(
                  entry: state.pendingTransactions[index],
                  isBusy: state.isBusy,
                  onSave: () => onSaveEntry(state.pendingTransactions[index]),
                  onDismiss: () => onDismissEntry(state.pendingTransactions[index]),
                ),
              ],
              if (state.pendingTransactions.length > 3) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'আরও ${BanglaFormatters.count(state.pendingTransactions.length - 3)}টি অপেক্ষায় আছে',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PendingAutoImportRow extends StatelessWidget {
  const _PendingAutoImportRow({
    required this.entry,
    required this.isBusy,
    required this.onSave,
    required this.onDismiss,
  });

  final SmsImportEntry entry;
  final bool isBusy;
  final Future<void> Function() onSave;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final amountColor = entry.isIncome ? AppColors.success : AppColors.error;
    final subtitle = entry.suggestedWallet?.name ?? 'Wallet মেলেনি';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.transaction.counterparty?.trim().isNotEmpty == true
                  ? entry.transaction.counterparty!.trim()
                  : entry.transaction.source.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.transaction.source.label} · ${entry.mappedLabel} · $subtitle',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              BanglaFormatters.preciseCurrency(entry.transaction.amount),
              style: AppTextStyles.titleMedium.copyWith(color: amountColor),
            ),
          ],
        );
        final actions = isCompact
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'সংরক্ষণ',
                    onPressed: isBusy ? null : () => onSave(),
                    icon: const Icon(Icons.check_circle_rounded),
                    color: AppColors.success,
                  ),
                  IconButton(
                    tooltip: 'বাদ',
                    onPressed: isBusy ? null : () => onDismiss(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.warning,
                  ),
                ],
              )
            : Column(
                children: [
                  IconButton(
                    tooltip: 'সংরক্ষণ',
                    onPressed: isBusy ? null : () => onSave(),
                    icon: const Icon(Icons.check_circle_rounded),
                    color: AppColors.success,
                  ),
                  IconButton(
                    tooltip: 'বাদ',
                    onPressed: isBusy ? null : () => onDismiss(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.warning,
                  ),
                ],
              );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [content, const SizedBox(height: AppSpacing.xs), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            const SizedBox(width: AppSpacing.sm),
            actions,
          ],
        );
      },
    );
  }
}

class _PermissionStateView extends StatelessWidget {
  const _PermissionStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppEmptyState(
              icon: icon,
              title: title,
              subtitle: subtitle,
              compact: true,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: AppActionButton(
                  key: actionKey,
                  label: actionLabel!,
                  icon: Icons.play_arrow_rounded,
                  fullWidth: true,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImportFooter extends StatelessWidget {
  const _ImportFooter({
    required this.selectedCount,
    required this.isImporting,
    required this.onImport,
  });

  final int selectedCount;
  final bool isImporting;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${BanglaFormatters.count(selectedCount)}টি নির্বাচিত',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ইমপোর্টের আগে review বা edit করতে পারেন',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          );
          final action = AppActionButton(
            key: const Key('sms-import-footer-button'),
            label: 'নির্বাচিতগুলো ইমপোর্ট করুন',
            icon: Icons.download_done_rounded,
            fullWidth: true,
            isLoading: isImporting,
            onPressed: selectedCount == 0 || isImporting
                ? null
                : () {
                    onImport();
                  },
          );

          return Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      summary,
                      const SizedBox(height: AppSpacing.md),
                      action,
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: AppSpacing.md),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 196,
                          maxWidth: 220,
                        ),
                        child: action,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({
    super.key,
    required this.candidate,
    required this.draft,
    required this.isSelected,
    required this.errorText,
    required this.isLocked,
    required this.onSelectionChanged,
    required this.onTap,
  });

  final SmsImportCandidate candidate;
  final SmsImportDraft draft;
  final bool isSelected;
  final String? errorText;
  final bool isLocked;
  final ValueChanged<bool> onSelectionChanged;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = draft.walletId == null
        ? null
        : ref.watch(walletByIdProvider(draft.walletId!));
    final accentColor = candidate.isIncome
        ? AppColors.success
        : resolveExpenseCategory(draft.category ?? 'Other').color;
    final leadingIcon = candidate.isIncome
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final label = draft.description.trim().isEmpty
        ? _fallbackTitle(candidate)
        : draft.description.trim();
    final secondary = candidate.isExpense
        ? draft.category ?? 'Other'
        : findIncomeSourceByName(draft.incomeSource ?? '')?.banglaLabel ??
              (draft.incomeSource ?? 'Other');

    return AppCard(
      onTap: isLocked
          ? null
          : () async {
              await onTap();
            },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 430;
          final badges = Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SourceBadge(label: candidate.transaction.sourceLabel),
              if (candidate.transaction.confidence < 0.98)
                _ConfidenceBadge(confidence: candidate.transaction.confidence),
            ],
          );
          final amountText = Text(
            BanglaFormatters.preciseCurrency(draft.amount),
            style: AppTextStyles.titleMedium.copyWith(
              color: candidate.isIncome
                  ? AppColors.success
                  : context.primaryTextColor,
            ),
          );
          final editText = Text(
            'Edit',
            style: AppTextStyles.caption.copyWith(
              color: context.appColors.primary,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    key: Key('sms-import-check-${candidate.sms.id}'),
                    value: isSelected,
                    onChanged: isLocked
                        ? null
                        : (value) => onSelectionChanged(value ?? false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        badges,
                        const SizedBox(height: AppSpacing.sm),
                        if (isCompact) ...[
                          Text(
                            label,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          amountText,
                          const SizedBox(height: AppSpacing.xs),
                          editText,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: context.primaryTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  amountText,
                                  const SizedBox(height: AppSpacing.xs),
                                  editText,
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(leadingIcon, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$secondary · ${BanglaFormatters.time(draft.date)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MetaPill(
                              icon: Icons.account_balance_wallet_outlined,
                              label: wallet == null
                                  ? 'ওয়ালেট ঠিক হয়নি'
                                  : '${wallet.emoji} ${wallet.name}',
                            ),
                            _MetaPill(
                              icon: Icons.schedule_rounded,
                              label: BanglaFormatters.fullDate(draft.date),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.all(AppRadius.card),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    errorText!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _fallbackTitle(SmsImportCandidate candidate) {
    final transaction = candidate.transaction;
    return transaction.counterparty?.trim().isNotEmpty == true
        ? transaction.counterparty!.trim()
        : transaction.merchantName?.trim().isNotEmpty == true
        ? transaction.merchantName!.trim()
        : transaction.rawCategory?.trim().isNotEmpty == true
        ? transaction.rawCategory!.trim()
        : candidate.sms.address;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: const BorderRadius.all(AppRadius.chip),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.secondaryTextColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.appColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: context.appColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).clamp(0, 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(AppRadius.chip),
      ),
      child: Text(
        '$percent% নিশ্চিত',
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFFB45309),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _CandidateGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          BanglaFormatters.relativeDay(group.date),
          style: AppTextStyles.titleMedium.copyWith(
            color: context.primaryTextColor,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${BanglaFormatters.count(group.candidates.length)}টি',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _CandidateGroup {
  const _CandidateGroup({required this.date, required this.candidates});

  final DateTime date;
  final List<SmsImportCandidate> candidates;
}

List<_CandidateGroup> _buildGroups(List<SmsImportCandidate> candidates) {
  final sorted = [...candidates]
    ..sort(
      (first, second) =>
          second.transaction.occurredAt.compareTo(first.transaction.occurredAt),
    );

  final groups = <_CandidateGroup>[];
  for (final candidate in sorted) {
    final date = candidate.transaction.occurredAt;
    final groupIndex = groups.indexWhere(
      (group) =>
          group.date.year == date.year &&
          group.date.month == date.month &&
          group.date.day == date.day,
    );
    if (groupIndex == -1) {
      groups.add(_CandidateGroup(date: date, candidates: [candidate]));
    } else {
      groups[groupIndex].candidates.add(candidate);
    }
  }
  return groups;
}
