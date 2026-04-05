import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../settings/budget_settings_screen.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../domain/entities/budget_plan_entity.dart';
import '../providers/budget_plan_provider.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() =>
      _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  final TextEditingController _incomeController = TextEditingController();
  bool _isGenerating = false;
  String _streamedResponse = '';
  Map<String, double> _currentMonthTotals = const {};
  BudgetPlanEntity? _previewPlan;

  @override
  void initState() {
    super.initState();
    _loadCurrentMonthTotals();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentMonthTotals() async {
    final expenses = await ref
        .read(expenseRepositoryProvider)
        .getThisMonthExpenses();
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentMonthTotals = totals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedPlan = ref.watch(budgetPlanProvider).valueOrNull;
    final visiblePlan = _previewPlan ?? savedPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Budget Planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'আপনার মাসিক আয় কত?',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTextStyles.displayMedium,
                    decoration: const InputDecoration(
                      prefixText: '৳ ',
                      hintText: '30000',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generatePlan,
                      child: Text(
                        _isGenerating
                            ? 'Plan বানানো হচ্ছে...'
                            : 'AI দিয়ে plan বানান',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_streamedResponse.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_streamedResponse, style: AppTextStyles.bodyMedium),
              ),
            ),
          ],
          if (visiblePlan != null) ...[
            const SizedBox(height: 16),
            _PlanCard(
              plan: visiblePlan,
              currentMonthTotals: _currentMonthTotals,
              onApply: () async {
                await ref
                    .read(budgetPlanProvider.notifier)
                    .savePlan(visiblePlan);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI budget plan apply হয়েছে')),
                );
              },
              onAdjust: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BudgetSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generatePlan() async {
    final messenger = ScaffoldMessenger.of(context);
    final monthlyIncome = double.tryParse(_incomeController.text.trim());
    if (monthlyIncome == null || monthlyIncome <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('সঠিক মাসিক আয় দিন')),
      );
      return;
    }

    final categories = ref.read(categoryProvider);
    final expenses = await ref.read(expenseRepositoryProvider).getAllExpenses();
    final last3MonthsExpenses = expenses
        .where(
          (expense) => expense.date.isAfter(
            DateTime.now().subtract(const Duration(days: 90)),
          ),
        )
        .toList(growable: false);

    setState(() {
      _isGenerating = true;
      _streamedResponse = '';
    });

    try {
      await for (final chunk
          in ref
              .read(budgetPlannerDataSourceProvider)
              .generateBudgetPlan(
                monthlyIncome: monthlyIncome,
                last3MonthsExpenses: last3MonthsExpenses,
                categories: categories,
              )) {
        if (!mounted) {
          return;
        }
        setState(() {
          _streamedResponse = chunk;
        });
      }
      final parsed = ref
          .read(budgetPlanProvider.notifier)
          .parsePlanResponse(
            response: _streamedResponse,
            monthlyIncome: monthlyIncome,
          );
      if (!context.mounted) {
        return;
      }
      if (parsed != null) {
        setState(() {
          _previewPlan = parsed;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.currentMonthTotals,
    required this.onApply,
    required this.onAdjust,
  });

  final BudgetPlanEntity plan;
  final Map<String, double> currentMonthTotals;
  final VoidCallback onApply;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final entries = plan.categoryBudgets.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Budget Suggestion', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Monthly income: ${BanglaFormatters.currency(plan.monthlyIncome)}',
            ),
            Text(
              'Savings: ${BanglaFormatters.currency(plan.savingsAmount)} (${plan.savingsPercentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) {
              final current = currentMonthTotals[entry.key] ?? 0.0;
              final ratio = entry.value <= 0
                  ? 0.0
                  : (current / entry.value).clamp(0.0, 1.4).toDouble();
              final color = ratio < 0.8
                  ? AppColors.success
                  : ratio <= 1
                  ? AppColors.warning
                  : AppColors.error;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          CategoryIcon.getIcon(entry.key),
                          color: CategoryIcon.getColor(entry.key),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(BanglaFormatters.currency(entry.value)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ratio > 1 ? 1 : ratio,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(plan.aiSuggestion, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    child: const Text('Apply this plan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAdjust,
                    child: const Text('Adjust manually'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
