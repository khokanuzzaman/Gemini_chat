import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/database/models/sms_ledger_entry_model.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_ledger_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../models/sms_history_models.dart';
import '../models/sms_import_models.dart';
import '../providers/sms_history_provider.dart';
import '../widgets/sms_import_edit_sheet.dart';

class SmsHistoryScreen extends ConsumerStatefulWidget {
  const SmsHistoryScreen({super.key});

  static Future<T?> push<T>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(AppSlideRoute(builder: (_) => const SmsHistoryScreen()));
  }

  @override
  ConsumerState<SmsHistoryScreen> createState() => _SmsHistoryScreenState();
}

class _SmsHistoryScreenState extends ConsumerState<SmsHistoryScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(smsHistoryControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsHistoryControllerProvider);
    final controller = ref.read(smsHistoryControllerProvider.notifier);

    if (_searchController.text != state.searchQuery) {
      _searchController.value = _searchController.value.copyWith(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return AppPageScaffold(
      title: 'SMS History',
      useGradientBackground: true,
      showOfflineBanner: false,
      refreshIndicator: state.hasPermission
          ? () => controller.syncLedger()
          : null,
      actions: [
        IconButton(
          key: const Key('sms-history-refresh'),
          tooltip: 'SMS sync',
          onPressed: state.isSyncing ? null : () => controller.syncLedger(),
          icon: state.isSyncing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.appColors.primary,
                    ),
                  ),
                )
              : const Icon(Icons.sync_rounded),
        ),
      ],
      body: CustomScrollView(
        key: const Key('sms-history-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HistoryHero(state: state),
                  const SizedBox(height: AppSpacing.md),
                  _SyncBanner(state: state),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _InlineErrorCard(message: state.errorMessage!),
                  ],
                  if (state.hasPermission) ...[
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppSegmentedTabs(
                      tabs: const ['Summary', 'History'],
                      selectedIndex: state.activeTab.index,
                      onChanged: (index) {
                        controller.setTab(SmsHistoryTab.values[index]);
                      },
                      tabKeys: const [
                        Key('sms-history-tab-summary'),
                        Key('sms-history-tab-history'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          ..._buildBodySlivers(context, state, controller),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers(
    BuildContext context,
    SmsHistoryScreenState state,
    SmsHistoryController controller,
  ) {
    if (!state.hasPermission) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _PermissionStateView(
            permissionState: state.permissionState,
            onRequestPermission: controller.requestPermission,
          ),
        ),
      ];
    }

    if (state.isLoading && !state.hasEntries) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(child: _HistoryLoadingBody()),
        ),
      ];
    }

    if (!state.hasEntries) {
      final result = state.lastSyncResult;
      final subtitle = result == null
          ? 'Inbox sync করলে parsable financial SMS এখানে জমা হবে।'
          : result.financialMessages == 0
          ? 'এই ডিভাইসে এখনো কোনো financial SMS ধরা পড়েনি।'
          : 'Financial SMS পাওয়া গেছে, কিন্তু parse করা যায়নি ${BanglaFormatters.count(result.unparsedFinancialMessages)}টি।';
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            child: Center(
              child: AppEmptyState(
                icon: Icons.sms_failed_outlined,
                title: 'SMS ledger এখনো খালি',
                subtitle: subtitle,
                compact: true,
                actionLabel: 'আবার sync করুন',
                onAction: controller.syncLedger,
              ),
            ),
          ),
        ),
      ];
    }

    return switch (state.activeTab) {
      SmsHistoryTab.summary => _buildSummarySlivers(context, state, controller),
      SmsHistoryTab.history => _buildHistorySlivers(context, state, controller),
    };
  }

  List<Widget> _buildSummarySlivers(
    BuildContext context,
    SmsHistoryScreenState state,
    SmsHistoryController controller,
  ) {
    final overview = state.overview;
    if (overview == null) {
      return const [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(child: _HistoryLoadingBody()),
        ),
      ];
    }

    final canMoveNext = _canMoveToNextMonth(state.selectedMonth);
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.xl,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _MonthNavigator(
              month: state.selectedMonth,
              canMoveNext: canMoveNext,
              onPrevious: controller.previousMonth,
              onNext: canMoveNext ? controller.nextMonth : null,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _KpiGrid(overview: overview),
            const SizedBox(height: AppSpacing.sectionGap),
            _TrendCard(points: overview.trendPoints),
            const SizedBox(height: AppSpacing.sectionGap),
            _SourceTotalsCard(totals: overview.sourceTotals),
            const SizedBox(height: AppSpacing.sectionGap),
            _KindTotalsCard(totals: overview.kindTotals),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _buildHistorySlivers(
    BuildContext context,
    SmsHistoryScreenState state,
    SmsHistoryController controller,
  ) {
    final filteredEntries = state.filteredEntries;
    final groups = _buildHistoryGroups(filteredEntries);

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(
          child: _HistoryFilterCard(
            state: state,
            searchController: _searchController,
            onSearchChanged: controller.setSearchQuery,
            onStatusChanged: controller.setStatusFilter,
            onSourceChanged: controller.setSourceFilter,
            onKindChanged: controller.setKindFilter,
          ),
        ),
      ),
      if (filteredEntries.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            child: Center(
              child: AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'মিলছে না',
                subtitle: 'ফিল্টার বা সার্চ বদলে আবার দেখুন।',
                compact: true,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          sliver: SliverList.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == groups.length - 1
                      ? 0
                      : AppSpacing.sectionGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HistoryGroupHeader(group: group),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in group.entries) ...[
                      _HistoryEntryCard(
                        key: Key('sms-history-row-${entry.id}'),
                        entry: entry,
                        onImport: entry.canImport
                            ? () => _handleImport(entry)
                            : null,
                        onToggleHidden: () => controller.toggleIgnored(entry),
                        onViewRaw: () => _showRawSms(entry),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
    ];
  }

  Future<void> _handleImport(SmsLedgerEntryModel entry) async {
    final controller = ref.read(smsHistoryControllerProvider.notifier);
    final candidate = await controller.buildImportCandidate(entry);
    if (!mounted) {
      return;
    }

    final updatedDraft = await showSmsImportEditSheet(
      context,
      candidate: candidate,
      draft: SmsImportDraft.fromCandidate(candidate),
    );
    if (updatedDraft == null || !mounted) {
      return;
    }

    final error = await controller.importEntry(entry: entry, draft: updatedDraft);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'SMS থেকে লেনদেন সফলভাবে ইমপোর্ট হয়েছে',
        ),
      ),
    );
  }

  Future<void> _showRawSms(SmsLedgerEntryModel entry) {
    return AppBottomSheet.show<void>(
      context: context,
      title: entry.source.label,
      subtitle: BanglaFormatters.fullDate(entry.receivedAt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _DetailPill(
                icon: Icons.badge_outlined,
                label: entry.sender,
              ),
              _DetailPill(
                icon: Icons.sell_outlined,
                label: entry.kind.labelBn,
              ),
              _DetailPill(
                icon: Icons.schedule_rounded,
                label: BanglaFormatters.time(entry.receivedAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.mutedSurfaceColor,
              borderRadius: const BorderRadius.all(AppRadius.card),
              border: Border.all(color: context.borderColor),
            ),
            child: SelectableText(
              entry.rawMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canMoveToNextMonth(DateTime selectedMonth) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final normalized = DateTime(selectedMonth.year, selectedMonth.month);
    return normalized.isBefore(currentMonth);
  }
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({required this.state});

  final SmsHistoryScreenState state;

  @override
  Widget build(BuildContext context) {
    final entryCount = state.entries.length;
    final amount = '${BanglaFormatters.count(entryCount)}টি';
    final subtitle = switch (state.permissionState) {
      SmsPermissionState.granted when state.isSyncing =>
        'Inbox sync হচ্ছে, source-wise totals ও monthly history আপডেট হবে',
      SmsPermissionState.granted when state.overview != null =>
        'এই মাসে মোট activity ${BanglaFormatters.preciseCurrency(state.overview!.monthlyActivityTotal)}',
      SmsPermissionState.granted =>
        'Financial SMS sync করে payment, cash in, send money breakdown দেখুন',
      SmsPermissionState.denied =>
        'SMS history দেখতে permission দিন',
      SmsPermissionState.permanentlyDenied =>
        'Settings থেকে SMS permission চালু করতে হবে',
      SmsPermissionState.unsupported =>
        'এই ডিভাইসে SMS ledger সমর্থিত নয়',
    };

    return AppHeroCard(
      label: 'SMS History',
      amount: amount,
      subtitle: subtitle,
      icon: Icons.timeline_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF0F766E), Color(0xFF155E75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      trailing: _HeroBadge(state: state),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.state});

  final SmsHistoryScreenState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state.permissionState) {
      SmsPermissionState.granted when state.isSyncing => (
        'Syncing',
        const Color(0xFFFFF3BF),
      ),
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

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.state});

  final SmsHistoryScreenState state;

  @override
  Widget build(BuildContext context) {
    final overview = state.overview;
    final lastSyncAt =
        state.lastSyncResult?.completedAt ?? overview?.lastSuccessfulSyncAt;

    if (state.syncProgress != null) {
      final progress = state.syncProgress!;
      return AppCard(
        key: const Key('sms-history-sync-progress'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync_rounded, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    progress.isInitialBackfill
                        ? 'পুরো inbox history sync হচ্ছে'
                        : 'নতুন SMS sync হচ্ছে',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: AppRadius.cardAll,
              color: context.appColors.primary,
              backgroundColor: context.borderColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Batch ${BanglaFormatters.count(progress.batchIndex)} · scanned ${BanglaFormatters.count(progress.scannedMessages)} · parsed ${BanglaFormatters.count(progress.parsedMessages)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (lastSyncAt == null && state.permissionState == SmsPermissionState.granted) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'এখনও কোনো ledger sync হয়নি। প্রথম sync-এ পুরো financial SMS history আনা হবে।',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (lastSyncAt == null) {
      return const SizedBox.shrink();
    }

    final result = state.lastSyncResult;
    final summary = result == null
        ? 'শেষ sync ${BanglaFormatters.relativeDay(lastSyncAt)}'
        : 'শেষ sync ${BanglaFormatters.relativeDay(lastSyncAt)} · ${BanglaFormatters.count(result.parsedMessages)}টি parsed · ${BanglaFormatters.count(result.unparsedFinancialMessages)}টি বাদ';

    return AppCard(
      child: Row(
        children: [
          Icon(
            overview?.initialBackfillComplete == true
                ? Icons.done_all_rounded
                : Icons.update_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message});

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

class _PermissionStateView extends StatelessWidget {
  const _PermissionStateView({
    required this.permissionState,
    required this.onRequestPermission,
  });

  final SmsPermissionState permissionState;
  final Future<void> Function() onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, actionLabel, onAction) = switch (
      permissionState
    ) {
      SmsPermissionState.unsupported => (
        Icons.phone_android_outlined,
        'এই ডিভাইসে SMS ledger সমর্থিত নয়',
        'PocketPilot AI এখন Android ডিভাইসের inbox থেকে financial SMS history পড়তে পারে।',
        null,
        null,
      ),
      SmsPermissionState.permanentlyDenied => (
        Icons.lock_outline_rounded,
        'SMS permission বন্ধ আছে',
        'Settings থেকে permission চালু করলে monthly history ও source-wise totals দেখা যাবে।',
        'Settings খুলুন',
        openAppSettings,
      ),
      SmsPermissionState.denied => (
        Icons.mark_chat_unread_outlined,
        'SMS permission দরকার',
        'bKash, Nagad, Rocket, Bank SMS থেকে history ও insights আনতে permission দিন।',
        'অনুমতি দিন',
        onRequestPermission,
      ),
      SmsPermissionState.granted => (
        Icons.check_circle_outline_rounded,
        'প্রস্তুত',
        'SMS ledger sync করতে pull-to-refresh বা উপরের sync button ব্যবহার করুন।',
        null,
        null,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                  key: const Key('sms-history-permission-cta'),
                  label: actionLabel,
                  icon: Icons.play_arrow_rounded,
                  fullWidth: true,
                  onPressed: () => onAction(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryLoadingBody extends StatelessWidget {
  const _HistoryLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppLoadingState.heroCard(),
        SizedBox(height: AppSpacing.cardGap),
        AppLoadingState.statRow(),
        SizedBox(height: AppSpacing.cardGap),
        AppLoadingState.card(height: 260),
        SizedBox(height: AppSpacing.cardGap),
        AppLoadingState.card(height: 180),
      ],
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canMoveNext;
  final Future<void> Function() onPrevious;
  final Future<void> Function()? onNext;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          IconButton(
            key: const Key('sms-history-month-prev'),
            onPressed: () {
              onPrevious();
            },
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'নির্বাচিত মাস',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  BanglaFormatters.monthYear(month),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('sms-history-month-next'),
            onPressed: canMoveNext && onNext != null
                ? () {
                    onNext!();
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.overview});

  final SmsLedgerOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'মাসিক activity',
                value: BanglaFormatters.preciseCurrency(
                  overview.monthlyActivityTotal,
                ),
                icon: Icons.query_stats_rounded,
                iconColor: context.appColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatCard(
                label: 'Outflow',
                value: BanglaFormatters.preciseCurrency(overview.monthlyOutflow),
                icon: Icons.call_made_rounded,
                iconColor: AppColors.error,
                valueColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Inflow',
                value: BanglaFormatters.preciseCurrency(overview.monthlyInflow),
                icon: Icons.call_received_rounded,
                iconColor: AppColors.success,
                valueColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatCard(
                label: 'Transfer',
                value: BanglaFormatters.preciseCurrency(
                  overview.monthlyTransfer,
                ),
                icon: Icons.sync_alt_rounded,
                iconColor: AppColors.warning,
                valueColor: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'All-time activity',
                value: BanglaFormatters.preciseCurrency(
                  overview.allTimeActivityTotal,
                ),
                icon: Icons.all_inclusive_rounded,
                iconColor: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppStatCard(
                label: 'Visible ledger',
                value: BanglaFormatters.count(overview.visibleEntries),
                icon: Icons.sms_rounded,
                iconColor: const Color(0xFF0F766E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<SmsLedgerMonthlyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = points.fold<double>(
      0,
      (current, point) => math.max(current, point.activityTotal),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'শেষ ৬ মাসের ট্রেন্ড',
            subtitle: 'প্রতি মাসে financial SMS activity কত ছিল',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxValue == 0 ? 100 : maxValue * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: context.borderColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.cardBackgroundColor,
                    getTooltipItems: (spots) {
                      return spots
                          .map((spot) {
                            final point = points[spot.x.toInt()];
                            return LineTooltipItem(
                              '${BanglaFormatters.monthYear(point.month)}\n${BanglaFormatters.preciseCurrency(point.activityTotal)}',
                              AppTextStyles.bodySmall.copyWith(
                                color: context.primaryTextColor,
                              ),
                            );
                          })
                          .toList(growable: false);
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          BanglaFormatters.count(value.round()),
                          style: AppTextStyles.caption.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final month = points[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${BanglaFormatters.count(month.month)}ম',
                            style: AppTextStyles.caption.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF0F766E),
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: const Color(0xFF0F766E),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x3D0F766E),
                          Color(0x050F766E),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: [
                      for (var index = 0; index < points.length; index++)
                        FlSpot(index.toDouble(), points[index].activityTotal),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final point in points)
                _DetailPill(
                  icon: Icons.calendar_month_rounded,
                  label:
                      '${BanglaFormatters.monthYear(point.month)} · ${BanglaFormatters.count(point.count)}টি',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceTotalsCard extends StatelessWidget {
  const _SourceTotalsCard({required this.totals});

  final List<SmsLedgerSourceTotal> totals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Source breakdown',
            subtitle: 'নির্বাচিত মাসে কোন source থেকে কত activity এসেছে',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          if (totals.isEmpty)
            const AppEmptyState(
              icon: Icons.source_outlined,
              title: 'Source data নেই',
              subtitle: 'এই মাসে parsable entry না থাকলে এখানে breakdown দেখাবে না।',
              compact: true,
            )
          else
            Column(
              children: [
                for (var index = 0; index < totals.length; index++) ...[
                  _TotalRow(
                    label: totals[index].source.labelBn,
                    count: totals[index].count,
                    amount: totals[index].amount,
                    accentColor: _sourceColor(totals[index].source),
                  ),
                  if (index != totals.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _KindTotalsCard extends StatelessWidget {
  const _KindTotalsCard({required this.totals});

  final List<SmsLedgerKindTotal> totals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Kind breakdown',
            subtitle: 'Payment, Cash In, Send Money ইত্যাদির মাসিক মোট',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          if (totals.isEmpty)
            const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'Kind data নেই',
              subtitle: 'এই মাসে parsable transaction kind না থাকলে breakdown দেখাবে না।',
              compact: true,
            )
          else
            Column(
              children: [
                for (var index = 0; index < totals.length; index++) ...[
                  _TotalRow(
                    label: totals[index].kind.labelBn,
                    count: totals[index].count,
                    amount: totals[index].amount,
                    accentColor: _kindColor(totals[index].kind),
                  ),
                  if (index != totals.length - 1)
                    const Divider(height: AppSpacing.lg),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.accentColor,
  });

  final String label;
  final int count;
  final double amount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${BanglaFormatters.count(count)}টি লেনদেন',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Text(
          BanglaFormatters.preciseCurrency(amount),
          style: AppTextStyles.titleMedium.copyWith(color: accentColor),
        ),
      ],
    );
  }
}

class _HistoryFilterCard extends StatelessWidget {
  const _HistoryFilterCard({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSourceChanged,
    required this.onKindChanged,
  });

  final SmsHistoryScreenState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SmsHistoryStatusFilter> onStatusChanged;
  final ValueChanged<ParsedTransactionSource?> onSourceChanged;
  final ValueChanged<ParsedTransactionKind?> onKindChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('sms-history-search'),
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'merchant, counterparty বা sender খুঁজুন',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Status',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final filter in SmsHistoryStatusFilter.values)
                AppChip(
                  key: Key('sms-history-status-${filter.name}'),
                  label: _statusLabel(filter),
                  selected: state.statusFilter == filter,
                  compact: true,
                  onTap: () => onStatusChanged(filter),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Source',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                key: const Key('sms-history-source-all'),
                label: 'সব',
                selected: state.sourceFilter == null,
                compact: true,
                onTap: () => onSourceChanged(null),
              ),
              for (final source in ParsedTransactionSource.values)
                if (source != ParsedTransactionSource.unknown)
                  AppChip(
                    key: Key('sms-history-source-${source.name}'),
                    label: source.label,
                    selected: state.sourceFilter == source,
                    compact: true,
                    color: _sourceColor(source),
                    onTap: () => onSourceChanged(source),
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kind',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                key: const Key('sms-history-kind-all'),
                label: 'সব',
                selected: state.kindFilter == null,
                compact: true,
                onTap: () => onKindChanged(null),
              ),
              for (final kind in ParsedTransactionKind.values)
                if (kind != ParsedTransactionKind.unknown)
                  AppChip(
                    key: Key('sms-history-kind-${kind.name}'),
                    label: kind.labelBn,
                    selected: state.kindFilter == kind,
                    compact: true,
                    color: _kindColor(kind),
                    onTap: () => onKindChanged(kind),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(SmsHistoryStatusFilter filter) {
    return switch (filter) {
      SmsHistoryStatusFilter.all => 'সব',
      SmsHistoryStatusFilter.imported => 'Imported',
      SmsHistoryStatusFilter.notImported => 'Not imported',
      SmsHistoryStatusFilter.hidden => 'Hidden',
    };
  }
}

class _HistoryGroupHeader extends StatelessWidget {
  const _HistoryGroupHeader({required this.group});

  final _HistoryGroup group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          BanglaFormatters.fullDate(group.date),
          style: AppTextStyles.titleMedium.copyWith(
            color: context.primaryTextColor,
          ),
        ),
        const Spacer(),
        Text(
          '${BanglaFormatters.count(group.entries.length)}টি',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    super.key,
    required this.entry,
    required this.onToggleHidden,
    required this.onViewRaw,
    this.onImport,
  });

  final SmsLedgerEntryModel entry;
  final Future<void> Function()? onImport;
  final Future<void> Function() onToggleHidden;
  final Future<void> Function() onViewRaw;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.isIncomeLike;
    final amountColor = isIncome ? AppColors.success : AppColors.error;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _StatusBadge(
                          label: entry.source.label,
                          color: _sourceColor(entry.source),
                        ),
                        _StatusBadge(
                          label: entry.kind.labelBn,
                          color: _kindColor(entry.kind),
                        ),
                        if (entry.isImported)
                          const _StatusBadge(
                            label: 'Imported',
                            color: AppColors.success,
                          ),
                        if (entry.isIgnored)
                          const _StatusBadge(
                            label: 'Hidden',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      entry.displayTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${entry.sender} · ${BanglaFormatters.time(entry.occurredAt)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    BanglaFormatters.preciseCurrency(entry.amount),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: amountColor,
                    ),
                  ),
                  if (entry.fee != null && entry.fee! > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Fee ${BanglaFormatters.preciseCurrency(entry.fee!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (entry.accountMask != null && entry.accountMask!.trim().isNotEmpty)
                _DetailPill(
                  icon: Icons.credit_card_rounded,
                  label: entry.accountMask!,
                ),
              if (entry.reference != null && entry.reference!.trim().isNotEmpty)
                _DetailPill(
                  icon: Icons.pin_outlined,
                  label: entry.reference!,
                ),
              if (entry.balanceAfter != null)
                _DetailPill(
                  icon: Icons.account_balance_wallet_outlined,
                  label:
                      'Balance ${BanglaFormatters.preciseCurrency(entry.balanceAfter!)}',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (onImport != null)
                AppActionButton(
                  key: Key('sms-history-import-${entry.id}'),
                  label: 'Import',
                  icon: Icons.download_done_rounded,
                  size: AppActionButtonSize.small,
                  variant: AppActionButtonVariant.secondary,
                  onPressed: () {
                    onImport!();
                  },
                ),
              AppActionButton(
                key: Key('sms-history-raw-${entry.id}'),
                label: 'Raw SMS',
                icon: Icons.article_outlined,
                size: AppActionButtonSize.small,
                variant: AppActionButtonVariant.ghost,
                onPressed: () {
                  onViewRaw();
                },
              ),
              AppActionButton(
                key: Key('sms-history-toggle-hidden-${entry.id}'),
                label: entry.isIgnored ? 'Restore' : 'Hide from totals',
                icon: entry.isIgnored
                    ? Icons.unarchive_outlined
                    : Icons.visibility_off_outlined,
                size: AppActionButtonSize.small,
                variant: entry.isIgnored
                    ? AppActionButtonVariant.secondary
                    : AppActionButtonVariant.ghost,
                onPressed: () {
                  onToggleHidden();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: const BorderRadius.all(AppRadius.card),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.secondaryTextColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryGroup {
  const _HistoryGroup({required this.date, required this.entries});

  final DateTime date;
  final List<SmsLedgerEntryModel> entries;
}

List<_HistoryGroup> _buildHistoryGroups(List<SmsLedgerEntryModel> entries) {
  final groups = <_HistoryGroup>[];
  DateTime? currentDay;
  final currentEntries = <SmsLedgerEntryModel>[];

  for (final entry in entries) {
    final day = DateTime(
      entry.occurredAt.year,
      entry.occurredAt.month,
      entry.occurredAt.day,
    );
    if (currentDay == null || currentDay != day) {
      if (currentDay != null) {
        groups.add(
          _HistoryGroup(
            date: currentDay,
            entries: List<SmsLedgerEntryModel>.unmodifiable(currentEntries),
          ),
        );
        currentEntries.clear();
      }
      currentDay = day;
    }
    currentEntries.add(entry);
  }

  if (currentDay != null && currentEntries.isNotEmpty) {
    groups.add(
      _HistoryGroup(
        date: currentDay,
        entries: List<SmsLedgerEntryModel>.unmodifiable(currentEntries),
      ),
    );
  }

  return groups;
}

Color _sourceColor(ParsedTransactionSource source) {
  return switch (source) {
    ParsedTransactionSource.bkash => const Color(0xFFE2136E),
    ParsedTransactionSource.nagad => const Color(0xFFFF6B00),
    ParsedTransactionSource.rocket => const Color(0xFF8E44AD),
    ParsedTransactionSource.bank => const Color(0xFF0F766E),
    ParsedTransactionSource.unknown => const Color(0xFF64748B),
  };
}

Color _kindColor(ParsedTransactionKind kind) {
  return switch (kind) {
    ParsedTransactionKind.receivedMoney || ParsedTransactionKind.bankCredit =>
      AppColors.success,
    ParsedTransactionKind.cashIn ||
    ParsedTransactionKind.addMoney ||
    ParsedTransactionKind.transfer => AppColors.warning,
    ParsedTransactionKind.sendMoney ||
    ParsedTransactionKind.cashOut ||
    ParsedTransactionKind.payment ||
    ParsedTransactionKind.bankDebit ||
    ParsedTransactionKind.atmWithdrawal ||
    ParsedTransactionKind.cardPurchase ||
    ParsedTransactionKind.billPay => AppColors.error,
    ParsedTransactionKind.unknown => const Color(0xFF64748B),
  };
}
