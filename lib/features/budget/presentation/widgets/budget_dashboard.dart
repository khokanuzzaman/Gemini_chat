import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../expense/domain/entities/expense_entity.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../domain/entities/budget_plan_entity.dart';
import '../providers/budget_provider.dart';

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
        final percentageLabel = budget.totalBudgeted <= 0
            ? '0'
            : (usage * 100).toStringAsFixed(0);
        final entries =
            budget.categoryBudgets.entries
                .where((entry) => entry.value > 0)
                .toList(growable: false)
              ..sort((first, second) => second.value.compareTo(first.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'মাসিক আয়',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              BanglaFormatters.currency(budget.monthlyIncome),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'সঞ্চয় লক্ষ্য',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              BanglaFormatters.currency(budget.savingsAmount),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              '(${budget.savingsPercentage.toStringAsFixed(0)}%)',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'বাজেট: ${BanglaFormatters.currency(budget.totalBudgeted)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const Spacer(),
                        Text(
                          'খরচ: ${BanglaFormatters.currency(totalSpent)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: min(1.0, usage.isFinite ? usage : 0.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.28),
                        color: usage > 1 ? Colors.red.shade300 : Colors.white,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          budget.budgetRule.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const Spacer(),
                        Text(
                          '$percentageLabel% ব্যবহৃত',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Category বাজেট',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BudgetCategoryCard(
                  budget: budget,
                  category: entry.key,
                  budgetAmount: entry.value,
                  expenses: expenses,
                ),
              ),
            ),
            if (budget.aiExplanation.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI এর পরামর্শ',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        budget.aiExplanation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('নতুন Budget তৈরি করুন'),
            ),
            const SizedBox(height: 8),
            Text(
              'তৈরি হয়েছে: ${DateFormat('dd MMM yyyy').format(budget.createdAt)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetCategoryCard extends ConsumerWidget {
  const _BudgetCategoryCard({
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
    final pct = budget.getUsagePercentage(category, expenses);
    final status = budget.getCategoryStatus(category, expenses);
    final iconColor = CategoryIcon.getColor(category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CategoryIcon.getIcon(category),
                color: iconColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: status.color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: min(1.0, pct / 100),
                      backgroundColor: context.borderColor.withValues(
                        alpha: 0.4,
                      ),
                      color: status.color,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(budgetAmount)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showEditBudgetDialog(context, ref),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _EditBudgetDialog(category: category, currentBudget: budgetAmount),
    );
  }
}

class _EditBudgetDialog extends ConsumerStatefulWidget {
  const _EditBudgetDialog({
    required this.category,
    required this.currentBudget,
  });

  final String category;
  final double currentBudget;

  @override
  ConsumerState<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends ConsumerState<_EditBudgetDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentBudget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.category} বাজেট পরিবর্তন'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('বর্তমান: ${BanglaFormatters.currency(widget.currentBudget)}'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'নতুন বাজেট',
              prefixText: '৳ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('বাদ দিন'),
        ),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(_controller.text.trim());
            if (amount == null) {
              return;
            }
            await ref
                .read(budgetProvider.notifier)
                .updateCategoryBudget(widget.category, amount);
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
          child: const Text('Update করুন'),
        ),
      ],
    );
  }
}
