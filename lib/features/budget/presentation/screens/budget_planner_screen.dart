import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/budget_plan_entity.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_dashboard.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() =>
      _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  final TextEditingController _incomeController = TextEditingController();
  bool _showGenerationForm = false;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final activeBudget = budgetState.activeBudget;
    final showForm = activeBudget == null || _showGenerationForm;

    _syncIncomeInput(budgetState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Budget Planner'),
        actions: [
          if (activeBudget != null && !budgetState.isGenerating)
            IconButton(
              onPressed: budgetState.allBudgets.isEmpty
                  ? null
                  : () => _showHistorySheet(context, budgetState),
              icon: const Icon(Icons.history),
              tooltip: 'Budget history',
            ),
          if (activeBudget != null && !budgetState.isGenerating)
            IconButton(
              onPressed: () {
                ref
                    .read(budgetProvider.notifier)
                    .setIncome(activeBudget.monthlyIncome);
                ref
                    .read(budgetProvider.notifier)
                    .setRule(activeBudget.budgetRule);
                setState(() {
                  _incomeController.text = activeBudget.monthlyIncome
                      .toStringAsFixed(0);
                  _showGenerationForm = true;
                });
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Re-generate',
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: budgetState.isGenerating
            ? _GeneratingView(streamingText: budgetState.streamingText)
            : budgetState.isLoading && activeBudget == null && !showForm
            ? const Center(child: CircularProgressIndicator())
            : showForm
            ? _BudgetSetupForm(
                key: const ValueKey('budget_form'),
                incomeController: _incomeController,
                selectedRule: budgetState.selectedRule,
                incomeInput: budgetState.incomeInput,
                error: budgetState.error,
                hasExistingBudget: activeBudget != null,
                onSelectRule: (rule) {
                  ref.read(budgetProvider.notifier).setRule(rule);
                },
                onGenerate: _handleGenerate,
                onCancel: activeBudget == null
                    ? null
                    : () {
                        setState(() {
                          _showGenerationForm = false;
                        });
                      },
                onIncomeChanged: (value) {
                  ref
                      .read(budgetProvider.notifier)
                      .setIncome(double.tryParse(value.trim()));
                },
                onSelectPreset: (amount) {
                  _incomeController.text = amount.toStringAsFixed(0);
                  ref.read(budgetProvider.notifier).setIncome(amount);
                },
              )
            : _BudgetDashboardView(
                key: ValueKey('budget_dashboard_${activeBudget.id}'),
                budget: activeBudget,
                onRegenerate: () async {
                  final confirmed = await _showRegenerateConfirm(context);
                  if (confirmed != true || !mounted) {
                    return;
                  }
                  ref
                      .read(budgetProvider.notifier)
                      .setIncome(activeBudget.monthlyIncome);
                  ref
                      .read(budgetProvider.notifier)
                      .setRule(activeBudget.budgetRule);
                  setState(() {
                    _incomeController.text = activeBudget.monthlyIncome
                        .toStringAsFixed(0);
                    _showGenerationForm = true;
                  });
                },
              ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    await ref.read(budgetProvider.notifier).generateBudget();
    final updatedState = ref.read(budgetProvider);
    if (!mounted) {
      return;
    }
    if (updatedState.activeBudget != null && updatedState.error == null) {
      setState(() {
        _showGenerationForm = false;
      });
    }
  }

  void _syncIncomeInput(BudgetState state) {
    final income = state.incomeInput ?? state.activeBudget?.monthlyIncome;
    if (income == null) {
      return;
    }
    final text = income == income.roundToDouble()
        ? income.toStringAsFixed(0)
        : income.toStringAsFixed(2);
    if (_incomeController.text == text) {
      return;
    }
    _incomeController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _showHistorySheet(
    BuildContext context,
    BudgetState budgetState,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget ইতিহাস',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: budgetState.allBudgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final budget = budgetState.allBudgets[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: budget.isActive
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12)
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.18),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: budget.isActive
                                ? Theme.of(context).colorScheme.primary
                                : context.secondaryTextColor,
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${BanglaFormatters.currency(budget.monthlyIncome)} আয়',
                              ),
                            ),
                            if (budget.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'চলমান',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${budget.budgetRule.label} · ${DateFormat('dd MMM yyyy').format(budget.createdAt)}',
                        ),
                        trailing: budget.isActive
                            ? null
                            : TextButton(
                                onPressed: () async {
                                  await ref
                                      .read(budgetProvider.notifier)
                                      .restoreBudget(budget.id);
                                  if (!sheetContext.mounted) {
                                    return;
                                  }
                                  Navigator.of(sheetContext).pop();
                                },
                                child: const Text('পুনরায় চালু'),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showRegenerateConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('নতুন Budget তৈরি করবেন?'),
          content: const Text(
            'নতুন AI budget তৈরি হলে আগের plan history-তে থাকবে, কিন্তু active plan বদলে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('বাদ দিন'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('চালিয়ে যান'),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetSetupForm extends StatelessWidget {
  const _BudgetSetupForm({
    super.key,
    required this.incomeController,
    required this.selectedRule,
    required this.incomeInput,
    required this.error,
    required this.onSelectRule,
    required this.onGenerate,
    required this.onIncomeChanged,
    required this.onSelectPreset,
    required this.hasExistingBudget,
    this.onCancel,
  });

  final TextEditingController incomeController;
  final BudgetRule selectedRule;
  final double? incomeInput;
  final String? error;
  final ValueChanged<BudgetRule> onSelectRule;
  final VoidCallback onGenerate;
  final ValueChanged<String> onIncomeChanged;
  final ValueChanged<double> onSelectPreset;
  final bool hasExistingBudget;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final presets = const [15000, 25000, 35000, 50000, 75000];

    return SingleChildScrollView(
      key: const ValueKey('budget_setup_form'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AI Budget Planner',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'আপনার আয় দিন, AI আপনার খরচের ধরন\nবিশ্লেষণ করে সেরা budget বানাবে।',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.secondaryTextColor),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'আপনার মাসিক আয়',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: incomeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'আয়ের পরিমাণ',
                      prefixText: '৳ ',
                    ),
                    onChanged: onIncomeChanged,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets
                        .map(
                          (amount) => OutlinedButton(
                            onPressed: () => onSelectPreset(amount.toDouble()),
                            child: Text('৳${amount ~/ 1000}K'),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget নিয়ম',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ...BudgetRule.values.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => onSelectRule(rule),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selectedRule == rule
                                  ? Theme.of(context).colorScheme.primary
                                  : context.borderColor,
                            ),
                            color: selectedRule == rule
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.06)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedRule == rule
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selectedRule == rule
                                    ? Theme.of(context).colorScheme.primary
                                    : context.secondaryTextColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rule.label),
                                    const SizedBox(height: 2),
                                    Text(
                                      rule.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: incomeInput != null && incomeInput! > 0
                ? onGenerate
                : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI দিয়ে Budget বানান'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          if (hasExistingBudget && onCancel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onCancel,
              child: const Text('চলমান Budget এ ফিরে যান'),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  const _GeneratingView({required this.streamingText});

  final String streamingText;

  @override
  Widget build(BuildContext context) {
    final preview = streamingText.length > 220
        ? '${streamingText.substring(0, 220)}...'
        : streamingText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'AI বিশ্লেষণ করছে...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার খরচের ধরন দেখে\nসেরা budget তৈরি হচ্ছে',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  preview,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetDashboardView extends StatelessWidget {
  const _BudgetDashboardView({
    super.key,
    required this.budget,
    required this.onRegenerate,
  });

  final BudgetPlanEntity budget;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return BudgetDashboard(budget: budget, onRegenerate: onRegenerate);
  }
}
