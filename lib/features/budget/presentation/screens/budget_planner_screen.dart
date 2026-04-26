import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
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

    return AppPageScaffold(
      title: 'বাজেট প্ল্যানার',
      actions: [
        if (activeBudget != null && !budgetState.isGenerating)
          IconButton(
            onPressed: budgetState.allBudgets.isEmpty
                ? null
                : () => _showHistorySheet(context, budgetState),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'বাজেট ইতিহাস',
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
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'নতুন প্ল্যান',
          ),
      ],
      body: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: budgetState.isGenerating
            ? _GeneratingView(streamingText: budgetState.streamingText)
            : budgetState.isLoading && activeBudget == null && !showForm
            ? const SingleChildScrollView(
                key: ValueKey('budget-loading'),
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: AppLoadingState.card(height: 240),
              )
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
    final liveCategoryNames = ref
        .read(categoryProvider)
        .map((category) => category.name.trim().toLowerCase())
        .toSet();
    await AppBottomSheet.show<void>(
      context: context,
      title: 'বাজেট ইতিহাস',
      child: Column(
        children: [
          for (
            var index = 0;
            index < budgetState.allBudgets.length;
            index++
          ) ...[
            AppCard(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: EdgeInsets.zero,
              child: AppListTile(
                leadingIcon: Icons.account_balance_wallet_outlined,
                leadingColor: budgetState.allBudgets[index].isActive
                    ? context.appColors.primary
                    : context.secondaryTextColor,
                title:
                    '${budgetState.allBudgets[index].budgetRule.label} · ${DateFormat('dd MMM yyyy').format(budgetState.allBudgets[index].createdAt)}',
                subtitle:
                    '${BanglaFormatters.currency(budgetState.allBudgets[index].monthlyIncome)} আয়',
                trailing: budgetState.allBudgets[index].isActive
                    ? AppChip(
                        label: 'চলমান',
                        color: context.appColors.primary,
                        compact: true,
                      )
                    : AppActionButton(
                        label: 'চালু করুন',
                        size: AppActionButtonSize.small,
                        onPressed: () async {
                          final plan = budgetState.allBudgets[index];
                          final orphanedCategories = plan.categoryBudgets.keys
                              .where(
                                (name) => !liveCategoryNames.contains(
                                  name.trim().toLowerCase(),
                                ),
                              )
                              .toList(growable: false);
                          if (orphanedCategories.isNotEmpty) {
                            final confirmed = await _showRestoreCleanupWarning(
                              context,
                              orphanedCategories,
                            );
                            if (confirmed != true || !context.mounted) {
                              return;
                            }
                          }
                          await ref
                              .read(budgetProvider.notifier)
                              .restoreBudget(
                                plan.id,
                                liveCategoryNames: liveCategoryNames,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showRestoreCleanupWarning(
    BuildContext context,
    List<String> orphanedCategories,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('পুরোনো ক্যাটাগরি আছে'),
          content: Text(
            'এই প্ল্যানে মুছে ফেলা ক্যাটাগরি আছে: ${orphanedCategories.join(', ')}। চালু করলে এগুলো সরিয়ে দেওয়া হবে।',
          ),
          actions: [
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'চালু করুন',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showRegenerateConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('নতুন বাজেট তৈরি করবেন?'),
          content: const Text(
            'নতুন AI বাজেট তৈরি হলে আগের প্ল্যান history-তে থাকবে, কিন্তু active plan বদলে যাবে।',
          ),
          actions: [
            AppActionButton(
              label: 'বাদ দিন',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'চালিয়ে যান',
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: AppStaggeredList(
        children: [
          AppHeroCard(
            label: 'AI বাজেট প্ল্যানার',
            amount: incomeInput != null && incomeInput! > 0
                ? '৳ ${incomeInput!.toStringAsFixed(0)}'
                : '৳ ০',
            subtitle: 'আয় দিন, নিয়ম বেছে নিন, তারপর AI বাজেট বানান',
            icon: Icons.auto_awesome_rounded,
            gradient: AppGradients.primary,
          ),
          AppCard(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(
                  padding: EdgeInsets.zero,
                  title: 'মাসিক আয়',
                  subtitle: 'আপনার মাসিক ইনকাম লিখুন',
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: incomeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroAmount.copyWith(
                    color: context.primaryTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: '৳ ৩০,০০০',
                    prefixText: '৳ ',
                    filled: true,
                    fillColor: context.mutedSurfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(AppRadius.input),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onIncomeChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: presets
                      .map(
                        (amount) => AppChip(
                          label: '৳${(amount / 1000).toStringAsFixed(0)}K',
                          selected: incomeInput == amount,
                          onTap: () => onSelectPreset(amount.toDouble()),
                        ),
                      )
                      .toList(growable: false),
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
                  title: 'বাজেট নিয়ম',
                  subtitle: 'কোন rule দিয়ে ভাগ করবেন তা বেছে নিন',
                ),
                const SizedBox(height: AppSpacing.md),
                Column(
                  children: BudgetRule.values
                      .map(
                        (rule) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppCard(
                            elevation: 1,
                            padding: EdgeInsets.zero,
                            child: AppListTile(
                              leadingIcon: selectedRule == rule
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              leadingColor: selectedRule == rule
                                  ? context.appColors.primary
                                  : context.secondaryTextColor,
                              title: rule.label,
                              subtitle: rule.description,
                              trailing: selectedRule == rule
                                  ? AppChip(
                                      label: 'নির্বাচিত',
                                      color: context.appColors.primary,
                                      compact: true,
                                    )
                                  : null,
                              onTap: () => onSelectRule(rule),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          if (error != null)
            AppErrorState(
              title: 'বাজেট তৈরি করা যাচ্ছে না',
              message: error,
              compact: true,
            ),
          AppActionButton(
            label: 'বাজেট সেভ করুন',
            icon: Icons.auto_awesome_rounded,
            fullWidth: true,
            onPressed: incomeInput != null && incomeInput! > 0
                ? onGenerate
                : null,
          ),
          if (hasExistingBudget && onCancel != null)
            AppActionButton(
              label: 'চলমান বাজেটে ফিরে যান',
              variant: AppActionButtonVariant.ghost,
              fullWidth: true,
              onPressed: onCancel,
            ),
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

    return SingleChildScrollView(
      key: const ValueKey('budget-generating'),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          AppCard(
            elevation: 2,
            child: Column(
              children: [
                AppPulse(
                  minScale: 0.9,
                  maxScale: 1.05,
                  duration: const Duration(milliseconds: 900),
                  child: const AppLoadingState.card(height: 180),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'AI বাজেট তৈরি করছে...',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'আপনার খরচের ধরন বিশ্লেষণ করে প্ল্যান বানানো হচ্ছে',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              elevation: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.appColors.primary.withValues(alpha: 0.12),
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
                    child: Text(
                      preview,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
