import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/budget_settings.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../budget/domain/entities/budget_plan_entity.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../export/presentation/screens/export_screen.dart';
import '../../../goals/domain/entities/goal_entity.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../prediction/domain/entities/prediction_entity.dart';
import '../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/screens/wallet_management_screen.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/expense_entity.dart';
import '../screens/manual_add_screen.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

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
    final budgets = ref.watch(budgetSettingsProvider).categoryBudgets;
    final budgetPlan = ref.watch(budgetProvider).activeBudget;
    final recurringExpenses =
        ref.watch(recurringProvider).valueOrNull ?? const [];
    final activeGoals = ref.watch(goalProvider).activeGoals;
    final anomalyState = ref.watch(anomalyProvider);
    final activeAlerts = anomalyState.activeAlerts;
    final highSeverityCount = anomalyState.highSeverityCount;
    final prediction = ref.watch(predictionProvider).prediction;
    final categoryNames = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    final now = DateTime.now();
    final upcomingRecurring = recurringExpenses
        .where((pattern) {
          final next = pattern.nextExpected;
          if (next == null) {
            return false;
          }
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
        await ref.read(dashboardControllerProvider.notifier).refresh();
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => showManualAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: dashboard.when(
        data: (data) {
          final recentExpenses = [...data.recentExpenses]
            ..sort((first, second) => second.date.compareTo(first.date));
          final todayTotal = data.todayExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

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
                const _GreetingHeader(),
                const SizedBox(height: AppSpacing.lg),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: _NetWorthSection(
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
                  delay: Duration(milliseconds: 200),
                  child: _CashFlowStatRow(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _QuickActions(
                    onOpenChat: onOpenChat,
                    onOpenIncome: AppShellNavigation.openIncome,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 400),
                  child: _WalletSummarySection(
                    onTapWallet: (walletId) async {
                      final controller = ref.read(
                        expenseListControllerProvider.notifier,
                      );
                      await controller.clearFilters();
                      await controller.setWallet(walletId);
                      AppShellNavigation.openExpenses();
                    },
                    onTapManage: () {
                      Navigator.of(context).push(
                        AppSlideRoute(
                          builder: (_) => const WalletManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(title: 'এই মাসে'),
                      const SizedBox(height: AppSpacing.sm),
                      _HeaderCard(data: data),
                      const SizedBox(height: AppSpacing.cardGap),
                      _QuickStatsRow(
                        todayTotal: todayTotal,
                        weekTotal: data.thisWeekTotal,
                        transactionCount: data.transactionCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: 'Category অনুযায়ী',
                        action: TextButton(
                          onPressed: () => onOpenExpenses(null),
                          child: const Text('সব দেখুন'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _CategoryScroller(
                        categories: categoryNames,
                        totals: data.categoryTotals,
                        budgets: budgets,
                        onTapCategory: onOpenExpenses,
                      ),
                    ],
                  ),
                ),
                if (upcomingRecurring.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionHeader(
                          title: 'আসছে খরচ',
                          action: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                buildAppRoute(const RecurringScreen()),
                              );
                            },
                            child: const Text('সব দেখুন →'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _UpcomingRecurringCard(patterns: upcomingRecurring),
                      ],
                    ),
                  ),
                ],
                if (prediction != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppSectionHeader(title: 'পূর্বাভাস'),
                        const SizedBox(height: AppSpacing.sm),
                        _PredictionTeaserCard(prediction: prediction),
                      ],
                    ),
                  ),
                ],
                if (budgetPlan != null) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 850),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppSectionHeader(title: 'বাজেট'),
                        const SizedBox(height: AppSpacing.sm),
                        _BudgetProgressCard(
                          spent: data.thisMonthTotal,
                          plan: budgetPlan,
                        ),
                      ],
                    ),
                  ),
                ],
                if (activeGoals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSectionHeader(
                          title: 'আমার লক্ষ্য',
                          action: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                buildAppRoute(const GoalsScreen()),
                              );
                            },
                            child: const Text('সব দেখুন →'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _GoalsSummaryCard(
                          goals: activeGoals.take(2).toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
                if (activeAlerts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 950),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppSectionHeader(title: 'অস্বাভাবিক খরচ'),
                        const SizedBox(height: AppSpacing.sm),
                        _AnomalyAlertCard(
                          count: activeAlerts.length,
                          highCount: highSeverityCount,
                          onTap: () {
                            AppShellNavigation.openAnalytics(tabIndex: 1);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sectionGap),
                AppFadeSlideIn(
                  delay: const Duration(milliseconds: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: 'সাম্প্রতিক লেনদেন',
                        action: TextButton(
                          onPressed: AppShellNavigation.openExpenses,
                          child: const Text('সব দেখুন'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (recentExpenses.isEmpty)
                        _DashboardEmptyState(onOpenChat: onOpenChat)
                      else
                        AppCard(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: recentExpenses
                                .take(5)
                                .map(
                                  (expense) => Column(
                                    children: [
                                      _RecentExpenseTile(expense: expense),
                                      if (expense !=
                                          recentExpenses.take(5).last)
                                        Divider(
                                          height: 1,
                                          color:
                                              context.borderColor.withValues(
                                            alpha: 0.55,
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const _DashboardLoading(),
        error: (error, stackTrace) => AppErrorState(
          title: 'ড্যাশবোর্ড লোড করা যায়নি',
          message: '$error',
          onRetry: () =>
              ref.read(dashboardControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'সুপ্রভাত';
    if (hour < 17) return 'শুভ দুপুর';
    if (hour < 20) return 'শুভ সন্ধ্যা';
    return 'শুভ রাত্রি';
  }

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BanglaFormatters.fullDate(DateTime.now()),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const GlobalSettingsButton(),
        ],
      ),
    );
  }
}

class _NetWorthSection extends ConsumerWidget {
  const _NetWorthSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);
    return walletsAsync.when(
      loading: () => const AppLoadingState.heroCard(),
      error: (error, _) => AppErrorState(
        title: 'মোট সম্পদ লোড করা যায়নি',
        onRetry: () => ref.invalidate(walletProvider),
        compact: true,
      ),
      data: (wallets) {
        final activeWallets =
            wallets.where((wallet) => !wallet.isArchived).toList();
        if (activeWallets.isEmpty) {
          return AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'কোনো ওয়ালেট নেই',
            subtitle: 'প্রথমে একটি ওয়ালেট যোগ করুন',
            actionLabel: 'ওয়ালেট যোগ করুন',
            onAction: onTap,
            compact: true,
          );
        }

        final netWorth = ref.watch(totalBalanceProvider);
        return AppHeroCard(
          label: 'মোট সম্পদ',
          amount: BanglaFormatters.currency(netWorth),
          subtitle:
              '${BanglaFormatters.count(activeWallets.length)} টি ওয়ালেট থেকে',
          icon: Icons.account_balance_wallet_rounded,
          gradient: context.primaryGradient,
          onTap: onTap,
        );
      },
    );
  }
}

class _CashFlowStatRow extends ConsumerWidget {
  const _CashFlowStatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowProvider);
    return cashFlowAsync.when(
      loading: () => const AppLoadingState.statRow(),
      error: (error, _) => AppErrorState(
        title: 'ক্যাশ ফ্লো লোড করা যায়নি',
        onRetry: () => ref.invalidate(cashFlowProvider),
        compact: true,
      ),
      data: (cashFlow) {
        return Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'আয়',
                value: BanglaFormatters.currency(cashFlow.income),
                icon: Icons.trending_up_rounded,
                iconColor: AppColors.success,
                valueColor: context.incomeColor,
                trend: cashFlow.lastMonthIncome > 0
                    ? StatTrend(
                        percentage: ((cashFlow.income -
                                    cashFlow.lastMonthIncome) /
                                cashFlow.lastMonthIncome) *
                            100,
                        isPositive:
                            cashFlow.income >= cashFlow.lastMonthIncome,
                      )
                    : null,
                onTap: AppShellNavigation.openIncome,
              ),
            ),
            const SizedBox(width: AppSpacing.tightGap),
            Expanded(
              child: AppStatCard(
                label: 'খরচ',
                value: BanglaFormatters.currency(cashFlow.expense),
                icon: Icons.trending_down_rounded,
                iconColor: AppColors.error,
                valueColor: context.expenseColor,
                trend: cashFlow.lastMonthExpense > 0
                    ? StatTrend(
                        percentage: ((cashFlow.expense -
                                    cashFlow.lastMonthExpense) /
                                cashFlow.lastMonthExpense) *
                            100,
                        isPositive:
                            cashFlow.expense <= cashFlow.lastMonthExpense,
                      )
                    : null,
                onTap: AppShellNavigation.openExpenses,
              ),
            ),
            const SizedBox(width: AppSpacing.tightGap),
            Expanded(
              child: AppStatCard(
                label: 'সঞ্চয়',
                value: '${cashFlow.savingsRate.toStringAsFixed(0)}%',
                icon: Icons.savings_rounded,
                iconColor: context.appColors.primary,
                valueColor: cashFlow.isPositive
                    ? context.incomeColor
                    : context.expenseColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenChat,
    required this.onOpenIncome,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenIncome;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          AppChip(
            label: 'খরচ যোগ',
            icon: Icons.add_rounded,
            onTap: onOpenChat,
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'আয় যোগ',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            onTap: onOpenIncome,
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'রিসিট স্ক্যান',
            icon: Icons.camera_alt_rounded,
            onTap: () {
              AppShellNavigation.openChat();
            },
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'স্প্লিট বিল',
            icon: Icons.call_split_rounded,
            onTap: AppShellNavigation.openSplit,
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'বাজেট',
            icon: Icons.pie_chart_rounded,
            onTap: () {
              Navigator.of(context).push(
                AppSlideRoute(builder: (_) => const BudgetPlannerScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'লক্ষ্য',
            icon: Icons.flag_outlined,
            onTap: () {
              Navigator.of(context).push(buildAppRoute(const GoalsScreen()));
            },
          ),
          const SizedBox(width: 8),
          AppChip(
            label: 'এক্সপোর্ট',
            icon: Icons.ios_share_rounded,
            onTap: () {
              Navigator.of(context).push(buildAppRoute(const ExportScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final difference = data.thisMonthTotal - data.lastMonthTotal;
    final hasDifference = difference.abs() > 0;
    final diffColor = difference.isNegative
        ? const Color(0xFFC8FACC)
        : const Color(0xFFFFD2D2);

    return AppHeroCard(
      label: BanglaFormatters.monthYear(DateTime.now()),
      amount: BanglaFormatters.currency(data.thisMonthTotal),
      subtitle: 'এই মাসে মোট খরচ',
      icon: Icons.insights_rounded,
      gradient: AppGradients.primary,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              hasDifference
                  ? 'গত মাসের চেয়ে ${difference.isNegative ? '↓' : '↑'} ${BanglaFormatters.currency(difference.abs())}'
                  : 'গত মাসের মতোই খরচ',
              style: AppTextStyles.bodySmall.copyWith(
                color: diffColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (data.manualEntryCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${BanglaFormatters.count(data.manualEntryCount)} টি manual entry',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.todayTotal,
    required this.weekTotal,
    required this.transactionCount,
  });

  final double todayTotal;
  final double weekTotal;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            icon: Icons.today_rounded,
            label: 'আজকে',
            value: BanglaFormatters.currency(todayTotal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            icon: Icons.view_week_rounded,
            label: 'এই সপ্তাহে',
            value: BanglaFormatters.currency(weekTotal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'লেনদেন',
            value: '${BanglaFormatters.count(transactionCount)}টি',
          ),
        ),
      ],
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({
    required this.categories,
    required this.totals,
    required this.budgets,
    required this.onTapCategory,
  });

  final List<String> categories;
  final Map<String, double> totals;
  final Map<String, double> budgets;
  final ValueChanged<String?> onTapCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map((category) {
              final meta = resolveExpenseCategory(category);
              final amount = totals[category] ?? 0.0;
              final budget = budgets[category] ?? 0.0;
              final progress = budget <= 0
                  ? 0.0
                  : (amount / budget).clamp(0.0, 1.0).toDouble();
              final progressColor = _progressColor(progress);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 188,
                  child: AppCard(
                    onTap: () => onTapCategory(category),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: meta.color.withValues(alpha: 0.12),
                          child: Icon(meta.icon, color: meta.color),
                        ),
                        const SizedBox(height: 12),
                        Text(category, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 4),
                        AppAmountText(amount: amount),
                        if (budget > 0) ...[
                          const SizedBox(height: 12),
                          AppProgressBar(
                            value: progress,
                            color: progressColor,
                            backgroundColor: context.borderColor.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${BanglaFormatters.currency(amount)} / ${BanglaFormatters.currency(budget)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress > 0.9) {
      return AppColors.error;
    }
    if (progress >= 0.7) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({required this.spent, required this.plan});

  final double spent;
  final BudgetPlanEntity plan;

  @override
  Widget build(BuildContext context) {
    final totalBudget = plan.totalBudgeted <= 0 ? 1.0 : plan.totalBudgeted;
    final progress = (spent / totalBudget).clamp(0.0, 1.0);
    final progressColor = progress >= 1
        ? AppColors.error
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.success;
    return AppCard(
      onTap: () {
        Navigator.of(
          context,
        ).push(buildAppRoute(const BudgetPlannerScreen()));
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('মাসিক বাজেট', style: AppTextStyles.titleMedium),
              const Spacer(),
              AppActionButton(
                label: 'দেখুন →',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const BudgetPlannerScreen()));
                },
                variant: AppActionButtonVariant.ghost,
                size: AppActionButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(plan.totalBudgeted)}',
                style: AppTextStyles.titleMedium,
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.titleMedium.copyWith(color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: progress,
            color: progressColor,
            backgroundColor: context.borderColor.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 6),
          Text(
            'সঞ্চয় লক্ষ্য: ${BanglaFormatters.currency(plan.savingsAmount)} (${plan.savingsPercentage.toStringAsFixed(0)}%)',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _UpcomingRecurringCard extends StatelessWidget {
  const _UpcomingRecurringCard({required this.patterns});

  final List<dynamic> patterns;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: patterns
            .take(3)
            .map((pattern) {
              return AppListTile(
                title: pattern.description,
                subtitle: pattern.nextExpected == null
                    ? 'তারিখ নেই'
                    : BanglaFormatters.fullDate(pattern.nextExpected!),
                leading: CircleAvatar(
                  backgroundColor: CategoryIcon.getColor(
                    pattern.category,
                  ).withValues(alpha: 0.12),
                  child: Icon(
                    CategoryIcon.getIcon(pattern.category),
                    color: CategoryIcon.getColor(pattern.category),
                  ),
                ),
                trailingAmount: pattern.averageAmount,
                trailingSubtitle: 'আনুমানিক',
                dense: true,
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard({required this.goals});

  final List<GoalEntity> goals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: goals
            .map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(goal.emoji),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(
                          '${goal.progressPercentage.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppProgressBar(
                      value: goal.progressPercentage / 100,
                      backgroundColor: context.borderColor.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _PredictionTeaserCard extends StatelessWidget {
  const _PredictionTeaserCard({required this.prediction});

  final PredictionEntity prediction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(8),
      child: AppListTile(
        onTap: AppShellNavigation.openAnalytics,
        title: 'মাস শেষের পূর্বাভাস',
        subtitle: '৳${_formatPredictionAmount(prediction.predictedTotal)}',
        leadingIcon: Icons.analytics_outlined,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              prediction.trend.icon,
              size: 16,
              color: prediction.trend.color,
            ),
            const SizedBox(width: 4),
            Text(
              prediction.trend.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: prediction.trend.color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.secondaryTextColor,
              size: 18,
            ),
          ],
        ),
        dense: true,
      ),
    );
  }

  String _formatPredictionAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _AnomalyAlertCard extends StatelessWidget {
  const _AnomalyAlertCard({
    required this.count,
    required this.highCount,
    required this.onTap,
  });

  final int count;
  final int highCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = highCount > 0 ? AppColors.error : AppColors.warning;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: AppListTile(
        title: '${BanglaFormatters.count(count)}টি অস্বাভাবিক খরচ',
        subtitle: highCount > 0
            ? '$highCount টি উচ্চ ঝুঁকির'
            : '${BanglaFormatters.count(count)} টি সামান্য অস্বাভাবিক',
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: color,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        dense: true,
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(expense.category);
    return AppListTile(
      title: expense.description,
      subtitle:
          '${BanglaFormatters.relativeDay(expense.date)} · ${expense.category}',
      leadingIcon: meta.icon,
      leadingColor: meta.color,
      trailingAmount: expense.amount,
      trailingAmountIsExpense: true,
      dense: true,
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'এখনো কোনো খরচ নেই',
        subtitle: 'চ্যাটে গিয়ে খরচ যোগ করুন',
        actionLabel: 'চ্যাটে যান',
        onAction: onOpenChat,
        compact: true,
      ),
    );
  }
}

class _WalletSummarySection extends ConsumerWidget {
  const _WalletSummarySection({
    required this.onTapWallet,
    required this.onTapManage,
  });

  final ValueChanged<int> onTapWallet;
  final VoidCallback onTapManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'আমার ওয়ালেট',
          subtitle: 'মোট ব্যালেন্স ${BanglaFormatters.currency(totalBalance)}',
        ),
        const SizedBox(height: AppSpacing.sm),
        walletsAsync.when(
          data: (wallets) {
            final activeWallets = wallets
                .where((wallet) => !wallet.isArchived)
                .toList(growable: false);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...activeWallets.map(
                    (wallet) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _DashboardWalletCard(
                        walletId: wallet.id,
                        emoji: wallet.emoji,
                        name: wallet.name,
                        walletType: wallet.type,
                        balance: wallet.currentBalance,
                        onTap: () => onTapWallet(wallet.id),
                      ),
                    ),
                  ),
                  _AddWalletCard(onTap: onTapManage),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 152,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ShimmerBox(height: 152, width: 160, radius: 20),
                  SizedBox(width: 12),
                  ShimmerBox(height: 152, width: 160, radius: 20),
                  SizedBox(width: 12),
                  ShimmerBox(height: 152, width: 120, radius: 20),
                ],
              ),
            ),
          ),
          error: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ওয়ালেট লোড করা যায়নি',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                  AppActionButton(
                    label: 'আবার চেষ্টা',
                    onPressed: () =>
                        ref.read(walletProvider.notifier).refresh(),
                    size: AppActionButtonSize.small,
                    variant: AppActionButtonVariant.ghost,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardWalletCard extends ConsumerWidget {
  const _DashboardWalletCard({
    required this.walletId,
    required this.emoji,
    required this.name,
    required this.walletType,
    required this.balance,
    required this.onTap,
  });

  final int walletId;
  final String emoji;
  final String name;
  final WalletType walletType;
  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySpent = ref.watch(walletMonthlySpentProvider(walletId));
    final gradient = _walletGradient(walletType);

    return SizedBox(
      width: 160,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        gradient: gradient,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            AppAmountText(
              amount: balance,
              style: AppTextStyles.statValue.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            monthlySpent.when(
              data: (spent) => Text(
                'এই মাসে খরচ: ${BanglaFormatters.currency(spent)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () =>
                  const ShimmerBox(height: 14, width: 96, radius: 999),
              error: (_, _) => Text(
                'খরচ জানা যায়নি',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _walletGradient(WalletType type) {
    return switch (type) {
      WalletType.cash => AppGradients.walletTeal,
      WalletType.bkash => AppGradients.walletOrange,
      WalletType.nagad => AppGradients.walletPurple,
      WalletType.rocket => AppGradients.walletBlue,
      WalletType.bank => AppGradients.walletBlue,
      WalletType.card => AppGradients.walletPurple,
      WalletType.other => AppGradients.walletTeal,
    };
  }
}

class _AddWalletCard extends StatelessWidget {
  const _AddWalletCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.mutedSurfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'নতুন\nওয়ালেট',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        AppLoadingState.heroCard(),
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.card(height: 170),
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.card(height: 160),
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.statRow(),
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.card(height: 140),
        SizedBox(height: AppSpacing.sectionGap),
        AppLoadingState.list(),
      ],
    );
  }
}
