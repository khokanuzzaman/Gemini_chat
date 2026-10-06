import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../debt/presentation/providers/debt_providers.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/expense_providers.dart';
import '../providers/recent_activity_provider.dart';
import '../screens/manual_add_screen.dart';
import '../widgets/dashboard/dashboard_loading.dart';
import '../widgets/home/home_attention_slot.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_hero.dart';
import '../widgets/home/home_insights_card.dart';
import '../widgets/home/home_recent_card.dart';
import '../widgets/home/home_sms_card.dart';
import '../widgets/home/home_welcome.dart';
import '../widgets/home/monthly_spend_card.dart';

/// হোম. Top to bottom: header · মোট সম্পদ (+ wallet chips) · এই মাসের খরচ ·
/// ONE attention slot (restore > backup reminder) · SMS card · ইনসাইট ·
/// সাম্প্রতিক লেনদেন · FAB. With zero expenses AND zero income it shows the
/// welcome state instead of the figures.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(homeActivityProvider);

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
        tooltip: 'খরচ যোগ করুন',
        child: const Icon(Icons.add_rounded),
      ),
      body: activity.when(
        data: (home) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            // Room for the FAB so the last row is never hidden behind it.
            88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              const SizedBox(height: AppSpacing.md),
              if (home.hasAny) ...[
                const HomeHero(),
                const SizedBox(height: AppSpacing.cardGap),
                const MonthlySpendCard(),
                const HomeAttentionSlot(),
                const HomeSmsCard(),
                const HomeInsightsCard(),
                HomeRecentCard(items: home.recent),
              ] else ...[
                // A backup found on a fresh install must still be offered.
                const HomeAttentionSlot(),
                const SizedBox(height: AppSpacing.cardGap),
                const HomeWelcome(),
                const HomeSmsTeaser(),
              ],
            ],
          ),
        ),
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
