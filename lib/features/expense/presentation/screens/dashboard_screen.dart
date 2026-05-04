import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_providers.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../../settings/backup_screen.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/screens/wallet_management_screen.dart';
import '../../../debt/presentation/providers/debt_providers.dart';
import '../providers/expense_providers.dart';
import '../screens/manual_add_screen.dart';
import '../widgets/dashboard/category_breakdown_section.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_loading.dart';
import '../widgets/dashboard/dashboard_sms_card.dart';
import '../widgets/dashboard/insights_strip/insights_strip.dart';
import '../widgets/dashboard/month_summary_strip.dart';
import '../widgets/dashboard/net_worth_hero_card.dart';
import '../widgets/dashboard/primary_quick_actions.dart';
import '../widgets/dashboard/recent_transactions_card.dart';
import '../widgets/dashboard/restore_backup_banner.dart';
import '../widgets/dashboard/upcoming_recurring_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenExpenses,
    required this.onOpenChat,
  });

  final ValueChanged<String?> onOpenExpenses;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final restorePrompt = ref.watch(restorePromptProvider);
    final recurringExpenses =
        ref.watch(recurringProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final upcomingRecurring = recurringExpenses
        .where((pattern) {
          final next = pattern.nextExpected;
          if (next == null) return false;
          final days = next.difference(now).inDays;
          return days >= 0 && days <= 7;
        })
        .toList(growable: false);

    return AppPageScaffold(
      showOfflineBanner: true,
      onManualAdd: () => showManualAddSheet(context),
      refreshIndicator: () async {
        ref.invalidate(cashFlowProvider);
        ref.invalidate(walletProvider);
        ref.read(incomeRefreshTokenProvider.notifier).state++;
        await ref.read(debtListProvider.notifier).refresh();
        await ref.read(dashboardControllerProvider.notifier).refresh();
        ref.read(dashboardLastRefreshedAtProvider.notifier).state =
            DateTime.now();
        HapticFeedback.mediumImpact();
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => showManualAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: dashboard.when(
        data: (_) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 0),
                  child: DashboardHeader(),
                ),
                if (restorePrompt != null) ...[
                  const SizedBox(height: AppSpacing.cardGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 50),
                    child: RestoreBackupBanner(
                      info: restorePrompt,
                      onRestore: () {
                        Navigator.of(
                          context,
                        ).push(buildAppRoute(const BackupScreen()));
                      },
                      onSkip: () {
                        ref.read(restorePromptProvider.notifier).state = null;
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: NetWorthHeroCard(
                    onTap: () {
                      Navigator.of(context).push(
                        AppSlideRoute(
                          builder: (_) => const WalletManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 150),
                  child: MonthSummaryStrip(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 200),
                  child: PrimaryQuickActions(),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 250),
                  child: DashboardSmsCard(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: RecentTransactionsCard(onOpenChat: onOpenChat),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const AppFadeSlideIn(
                  delay: Duration(milliseconds: 350),
                  child: InsightsStrip(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 400),
                  child: CategoryBreakdownSection(
                    onTapCategory: onOpenExpenses,
                  ),
                ),
                if (upcomingRecurring.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionHeader(
                          title: 'আসছে খরচ',
                          action: TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).push(buildAppRoute(const RecurringScreen()));
                            },
                            child: const Text('সব দেখুন →'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        UpcomingRecurringCard(patterns: upcomingRecurring),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const DashboardLoading(),
        error: (error, stackTrace) => AppErrorState(
          title: 'ড্যাশবোর্ড লোড করা যায়নি',
          message: '$error',
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
