import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../domain/entities/budget_plan_entity.dart';

class BudgetDashboard extends ConsumerWidget {
  const BudgetDashboard({
    super.key,
    required this.budget,
    required this.onRegenerate,
  });

  final BudgetPlanEntity budget;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(expenseRefreshTokenProvider);
    return FutureBuilder<List<ExpenseEntity>>(
      future: ref.read(expenseRepositoryProvider).getThisMonthExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: AppLoadingState.card(height: 220),
          );
        }

        final expenses = snapshot.data ?? const <ExpenseEntity>[];
        final totalSpent = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );
        final totalBudget = budget.totalBudgeted <= 0
            ? 1.0
            : budget.totalBudgeted;
        final usage = budget.totalBudgeted <= 0
            ? 0.0
            : totalSpent / totalBudget;
        final liveCategoryNames = ref
            .watch(categoryProvider)
            .map((category) => category.name.trim().toLowerCase())
            .toSet();
        final validEntries = <MapEntry<String, double>>[];
        final orphanedEntries = <MapEntry<String, double>>[];
        for (final entry in budget.categoryBudgets.entries) {
          if (entry.value <= 0) {
            continue;
          }
          if (liveCategoryNames.contains(entry.key.trim().toLowerCase())) {
            validEntries.add(entry);
          } else {
            orphanedEntries.add(entry);
          }
        }
        validEntries.sort(
          (first, second) => second.value.compareTo(first.value),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: AppStaggeredList(
            children: [
              AppHeroCard(
                label: 'এই মাসের বাজেট',
                amount: BanglaFormatters.currency(budget.totalBudgeted),
                subtitle:
                    'খরচ ${BanglaFormatters.currency(totalSpent)} · ${budget.budgetRule.label}',
                icon: Icons.auto_awesome_rounded,
                gradient: usage > 1
                    ? AppGradients.danger
                    : AppGradients.primary,
                trailing: AppChip(
                  label:
                      '${usage.isFinite ? (usage * 100).clamp(0, 999).toStringAsFixed(0) : '0'}%',
                  color: usage > 1 ? AppColors.error : Colors.white,
                  compact: true,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      label: 'মাসিক আয়',
                      value: BanglaFormatters.currency(budget.monthlyIncome),
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: context.appColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppStatCard(
                      label: 'সঞ্চয় লক্ষ্য',
                      value: BanglaFormatters.currency(budget.savingsAmount),
                      icon: Icons.savings_outlined,
                      iconColor: AppColors.success,
                      valueColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              AppCard(
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      padding: EdgeInsets.zero,
                      title: 'ব্যবহারের সারাংশ',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'খরচ: ${BanglaFormatters.currency(totalSpent)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.primaryTextColor,
                            ),
                          ),
                        ),
                        Text(
                          'বাকি: ${BanglaFormatters.currency(max(0, budget.totalBudgeted - totalSpent))}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppProgressBar(
                      value: usage.isFinite ? usage : 0,
                      color: usage > 1
                          ? AppColors.error
                          : context.appColors.primary,
                      showLabel: true,
                      label: 'ব্যবহার',
                    ),
                  ],
                ),
              ),
              AppCard(
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      padding: EdgeInsets.zero,
                      title: 'ক্যাটাগরি বাজেট',
                      subtitle: 'খরচ বনাম বরাদ্দ',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (orphanedEntries.isNotEmpty) ...[
                      AppCard(
                        elevation: 0,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning.withValues(alpha: 0.14),
                            AppColors.warning.withValues(alpha: 0.05),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${orphanedEntries.length}টি মুছে ফেলা ক্যাটাগরি লুকানো আছে। Budget health check থেকে দেখে নিন।',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.primaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (validEntries.isEmpty)
                      const AppEmptyState(
                        icon: Icons.savings_outlined,
                        title: 'কোনো ক্যাটাগরি বাজেট নেই',
                        subtitle:
                            'নতুন বাজেট তৈরি করলে এখানে ক্যাটাগরি অনুযায়ী সীমা দেখাবে',
                        compact: true,
                      )
                    else
                      Column(
                        children: [
                          for (
                            var index = 0;
                            index < validEntries.length;
                            index++
                          ) ...[
                            _BudgetCategoryRow(
                              budget: budget,
                              category: validEntries[index].key,
                              budgetAmount: validEntries[index].value,
                              expenses: expenses,
                            ),
                            if (index != validEntries.length - 1)
                              const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (budget.aiExplanation.trim().isNotEmpty)
                AppCard(
                  elevation: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.ragChipBackgroundColor,
                      borderRadius: AppRadius.cardAll,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.appColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: context.appColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI এর পরামর্শ',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: context.primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                budget.aiExplanation,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              AppActionButton(
                label: 'নতুন বাজেট তৈরি করুন',
                icon: Icons.refresh_rounded,
                variant: AppActionButtonVariant.secondary,
                fullWidth: true,
                onPressed: onRegenerate,
              ),
              Text(
                'তৈরি হয়েছে: ${DateFormat('dd MMM yyyy').format(budget.createdAt)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetCategoryRow extends ConsumerWidget {
  const _BudgetCategoryRow({
    required this.budget,
    required this.category,
    required this.budgetAmount,
    required this.expenses,
  });

  final BudgetPlanEntity budget;
  final String category;
  final double budgetAmount;
  final List<ExpenseEntity> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = budget.getSpentForCategory(category, expenses);
    final pct = budget.getUsagePercentage(category, expenses) / 100;
    final status = budget.getCategoryStatus(category, expenses);
    final iconColor = CategoryIcon.getColor(category);
    final progressColor = spent > budgetAmount ? AppColors.error : iconColor;

    return AppCard(
      elevation: 1,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CategoryIcon.getIcon(category),
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(budgetAmount)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(label: status.label, color: status.color, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: pct.isFinite ? pct : 0,
            color: progressColor,
            showLabel: true,
            label: 'অগ্রগতি',
          ),
        ],
      ),
    );
  }
}
