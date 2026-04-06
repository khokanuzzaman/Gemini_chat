import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/notifications/budget_settings.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/global_settings_button.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../budget/presentation/providers/budget_plan_provider.dart';
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
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/expense_entity.dart';
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
    final budgets = ref.watch(budgetProvider).categoryBudgets;
    final budgetPlan = ref.watch(budgetPlanProvider).valueOrNull;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('হোম'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(buildAppRoute(const ExportScreen()));
            },
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(buildAppRoute(const GoalsScreen()));
            },
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Goals',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'split') {
                AppShellNavigation.openSplit();
                return;
              }
              final route = switch (value) {
                'budget' => buildAppRoute(const BudgetPlannerScreen()),
                'recurring' => buildAppRoute(const RecurringScreen()),
                'anomaly' => null,
                _ => null,
              };
              if (value == 'anomaly') {
                AppShellNavigation.openAnalytics(tabIndex: 1);
                return;
              }
              if (route != null) {
                Navigator.of(context).push(route);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'budget', child: Text('Budget Planner')),
              PopupMenuItem(
                value: 'recurring',
                child: Text('Regular Expenses'),
              ),
              PopupMenuItem(value: 'split', child: Text('Split Bill')),
              PopupMenuItem(value: 'anomaly', child: Text('Spending Alerts')),
            ],
          ),
          const GlobalSettingsButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context, ref),
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

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _HeaderCard(data: data),
                const SizedBox(height: AppSpacing.md),
                _QuickStatsRow(
                  todayTotal: todayTotal,
                  weekTotal: data.thisWeekTotal,
                  transactionCount: data.transactionCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Category অনুযায়ী',
                  actionLabel: 'সব দেখুন',
                  onTap: () => onOpenExpenses(null),
                ),
                const SizedBox(height: AppSpacing.sm),
                _CategoryScroller(
                  categories: categoryNames,
                  totals: data.categoryTotals,
                  budgets: budgets,
                  onTapCategory: onOpenExpenses,
                ),
                if (budgetPlan != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'বাজেট অগ্রগতি',
                    actionLabel: 'Planner',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(buildAppRoute(const BudgetPlannerScreen()));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BudgetProgressCard(
                    spent: data.thisMonthTotal,
                    plan: budgetPlan,
                  ),
                ],
                if (upcomingRecurring.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'আসছে খরচ',
                    actionLabel: 'সব দেখুন →',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(buildAppRoute(const RecurringScreen()));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _UpcomingRecurringCard(patterns: upcomingRecurring),
                ],
                if (activeGoals.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'আমার লক্ষ্য',
                    actionLabel: 'সব দেখুন →',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(buildAppRoute(const GoalsScreen()));
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _GoalsSummaryCard(
                    goals: activeGoals.take(2).toList(growable: false),
                  ),
                ],
                if (prediction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _PredictionTeaserCard(prediction: prediction),
                ],
                if (activeAlerts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AnomalyAlertCard(
                    count: activeAlerts.length,
                    highCount: highSeverityCount,
                    onTap: () {
                      AppShellNavigation.openAnalytics(tabIndex: 1);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'সাম্প্রতিক খরচ',
                  actionLabel: 'সব দেখুন →',
                  onTap: () => onOpenExpenses(null),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (recentExpenses.isEmpty)
                  _DashboardEmptyState(onOpenChat: onOpenChat)
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: recentExpenses
                            .take(5)
                            .map(
                              (expense) => Column(
                                children: [
                                  _RecentExpenseTile(expense: expense),
                                  if (expense != recentExpenses.take(5).last)
                                    Divider(
                                      height: 1,
                                      color: context.borderColor.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const _DashboardLoading(),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'ড্যাশবোর্ড লোড করা যায়নি\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _QuickAddSheet(
        onSaved: (expense) async {
          final error = await ref
              .read(expenseMutationControllerProvider)
              .saveDetectedExpense(expense);
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error ?? 'খরচ যোগ করা হয়েছে')));
        },
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BanglaFormatters.monthYear(DateTime.now()),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightBackground.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            BanglaFormatters.currency(data.thisMonthTotal),
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.lightBackground,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'এই মাসে মোট খরচ',
            style: TextStyle(
              color: AppColors.lightBackground.withValues(alpha: 0.72),
            ),
          ),
          if (data.manualEntryCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'এর মধ্যে ${BanglaFormatters.count(data.manualEntryCount)} টি manual entry',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.lightBackground.withValues(alpha: 0.72),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.lightBackground.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              hasDifference
                  ? 'গত মাসের চেয়ে ${difference.isNegative ? '↓' : '↑'} ${BanglaFormatters.currency(difference.abs())}'
                  : 'গত মাসের মতোই খরচ',
              style: TextStyle(
                color: difference.isNegative
                    ? const Color(0xFFC8FACC)
                    : const Color(0xFFFFD2D2),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
          child: _StatCard(
            icon: Icons.today_rounded,
            label: 'আজকে',
            value: BanglaFormatters.currency(todayTotal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.view_week_rounded,
            label: 'এই সপ্তাহে',
            value: BanglaFormatters.currency(weekTotal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: '${BanglaFormatters.count(transactionCount)}টি',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTapCategory(category),
                  child: Ink(
                    width: 188,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: meta.color.withValues(alpha: 0.25),
                      ),
                    ),
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
                        Text(
                          BanglaFormatters.currency(amount),
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (budget > 0) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: context.borderColor.withValues(
                                alpha: 0.4,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
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
  final dynamic plan;

  @override
  Widget build(BuildContext context) {
    final totalBudget = plan.totalBudgeted <= 0 ? 1.0 : plan.totalBudgeted;
    final progress = (spent / totalBudget).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('বাজেট অগ্রগতি', style: AppTextStyles.titleMedium),
                const Spacer(),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: progress > 0.95
                  ? AppColors.error
                  : progress > 0.75
                  ? AppColors.warning
                  : AppColors.success,
              backgroundColor: context.borderColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 8),
            Text(
              '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(plan.totalBudgeted)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRecurringCard extends StatelessWidget {
  const _UpcomingRecurringCard({required this.patterns});

  final List<dynamic> patterns;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: patterns
              .take(3)
              .map((pattern) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: CategoryIcon.getColor(
                      pattern.category,
                    ).withValues(alpha: 0.12),
                    child: Icon(
                      CategoryIcon.getIcon(pattern.category),
                      color: CategoryIcon.getColor(pattern.category),
                    ),
                  ),
                  title: Text(pattern.description),
                  subtitle: Text(
                    pattern.nextExpected == null
                        ? 'তারিখ নেই'
                        : BanglaFormatters.fullDate(pattern.nextExpected!),
                  ),
                  trailing: Text(
                    '~${BanglaFormatters.currency(pattern.averageAmount)}',
                    style: AppTextStyles.bodySmall,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard({required this.goals});

  final List<GoalEntity> goals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
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
      ),
    );
  }
}

class _PredictionTeaserCard extends StatelessWidget {
  const _PredictionTeaserCard({required this.prediction});

  final PredictionEntity prediction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: AppShellNavigation.openAnalytics,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'মাস শেষের পূর্বাভাস',
                    style: AppTextStyles.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  Text(
                    '৳${_formatPredictionAmount(prediction.predictedTotal)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
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
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: context.secondaryTextColor,
                size: 18,
              ),
            ],
          ),
        ),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (highCount > 0 ? AppColors.error : AppColors.warning)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: highCount > 0 ? AppColors.error : AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${BanglaFormatters.count(count)}টি অস্বাভাবিক খরচ',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      highCount > 0
                          ? '$highCount টি উচ্চ ঝুঁকির'
                          : '${BanglaFormatters.count(count)} টি সামান্য অস্বাভাবিক',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: meta.color.withValues(alpha: 0.12),
            child: Icon(meta.icon, color: meta.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${BanglaFormatters.relativeDay(expense.date)} · ${expense.category}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            BanglaFormatters.currency(expense.amount),
            style: AppTextStyles.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: context.ragChipBackgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('এখনো কোনো খরচ নেই', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'চ্যাটে গিয়ে খরচ যোগ করুন',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onOpenChat,
              child: const Text('চ্যাটে যান'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onTap});

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const Spacer(),
        if (actionLabel != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
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
        ShimmerBox(height: 180, radius: 28),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 96)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 96)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 96)),
          ],
        ),
        SizedBox(height: 24),
        ShimmerBox(height: 28, width: 160),
        SizedBox(height: 12),
        SizedBox(
          height: 126,
          child: Row(
            children: [
              Expanded(child: ShimmerBox(height: 126)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 126)),
            ],
          ),
        ),
        SizedBox(height: 24),
        ShimmerBox(height: 28, width: 150),
        SizedBox(height: 12),
        ShimmerBox(height: 76),
        SizedBox(height: 12),
        ShimmerBox(height: 76),
        SizedBox(height: 12),
        ShimmerBox(height: 76),
      ],
    );
  }
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet({required this.onSaved});

  final Future<void> Function(ExpenseData expense) onSaved;

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  bool _saving = false;
  String _selectedCategory = 'Other';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final category = await AppPreferences.defaultCategory();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    if (!categoryNames.contains(_selectedCategory) &&
        categoryNames.isNotEmpty) {
      _selectedCategory = categoryNames.contains('Other')
          ? 'Other'
          : categoryNames.first;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Quick add', style: AppTextStyles.displayMedium),
            const SizedBox(height: 6),
            const Text(
              'দ্রুত নতুন খরচ যোগ করুন',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'কী কিনলেন?'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'পরিমাণ'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = categoryNames[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: categoryNames.length,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(BanglaFormatters.fullDate(_selectedDate)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সব তথ্য ঠিকভাবে দিন')));
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.onSaved(
      ExpenseData(
        amount: amount,
        category: _selectedCategory,
        description: description,
        date: _selectedDate.toIso8601String().split('T').first,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });
  }
}
