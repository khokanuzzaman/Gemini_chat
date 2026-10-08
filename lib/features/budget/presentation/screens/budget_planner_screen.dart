import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/feature_flags.dart';
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
  String? _incomeErrorText;

  @override
  void initState() {
    super.initState();
    _incomeController.addListener(_syncIncomeValidation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncIncomeInput(ref.read(budgetProvider));
    });
  }

  @override
  void dispose() {
    _incomeController.removeListener(_syncIncomeValidation);
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BudgetState>(budgetProvider, (previous, next) {
      _syncIncomeInput(next);
    });

    final budgetState = ref.watch(budgetProvider);
    final activeBudget = budgetState.activeBudget;
    final showForm = activeBudget == null || _showGenerationForm;

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
        // "নতুন প্ল্যান" with a sparkle is the AI entry point — with AI off the
        // dashboard's own "নতুন বাজেট তৈরি করুন" button is the only way in.
        if (FeatureFlags.aiEnabled &&
            activeBudget != null &&
            !budgetState.isGenerating)
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
                incomeErrorText: _incomeErrorText,
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
                      .setIncome(_parseIncomeInput(value));
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

  void _syncIncomeValidation() {
    final nextError = _validateIncome(_incomeController.text);
    if (nextError == _incomeErrorText) {
      return;
    }

    setState(() {
      _incomeErrorText = nextError;
    });
  }

  String? _validateIncome(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }

    final parsedIncome = _parseIncomeInput(raw);
    if (parsedIncome == null || parsedIncome <= 0) {
      return 'সঠিক আয়ের পরিমাণ লিখুন';
    }

    return null;
  }

  double? _parseIncomeInput(String raw) => BanglaFormatters.parseAmount(raw);

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
                    '${budgetState.allBudgets[index].budgetRule.label} · ${BanglaFormatters.fullDate(budgetState.allBudgets[index].createdAt)}',
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
          content: Text(
            FeatureFlags.aiEnabled
                ? 'নতুন AI বাজেট তৈরি হলে আগের প্ল্যান ইতিহাসে থাকবে, কিন্তু চলমান প্ল্যান বদলে যাবে।'
                : 'নতুন বাজেট তৈরি হলে আগের প্ল্যান ইতিহাসে থাকবে, কিন্তু চলমান প্ল্যান বদলে যাবে।',
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
    required this.incomeErrorText,
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
  final String? incomeErrorText;
  final ValueChanged<BudgetRule> onSelectRule;
  final VoidCallback onGenerate;
  final ValueChanged<String> onIncomeChanged;
  final ValueChanged<double> onSelectPreset;
  final bool hasExistingBudget;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final presets = const [15000, 25000, 35000, 50000, 75000];
    final hasIncome = incomeInput != null && incomeInput! > 0;

    final sections = <Widget>[
      AppHeroCard(
        label: FeatureFlags.aiEnabled
            ? 'AI বাজেট প্ল্যানার'
            : 'বাজেট প্ল্যানার',
        amount: BanglaFormatters.currency(hasIncome ? incomeInput! : 0),
        subtitle: FeatureFlags.aiEnabled
            ? 'আয় দিন, নিয়ম বেছে নিন, তারপর AI বাজেট বানান'
            : 'আয় দিন, নিয়ম বেছে নিন, তারপর বাজেট বানান',
        icon: FeatureFlags.aiEnabled
            ? Icons.auto_awesome_rounded
            : Icons.account_balance_wallet_rounded,
        gradient: context.primaryGradient,
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
              style: AppTextStyles.heroAmount.copyWith(color: tokens.ink),
              decoration: InputDecoration(
                hintText:
                    '${BanglaFormatters.currencySymbol} ${BanglaFormatters.count(30000)}',
                prefixText: '${BanglaFormatters.currencySymbol} ',
                filled: true,
                fillColor: tokens.surface2,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onIncomeChanged,
            ),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: incomeErrorText == null
                  ? const SizedBox(height: AppSpacing.sm)
                  : Padding(
                      key: const ValueKey('budget-income-error'),
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        incomeErrorText!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: tokens.dangerText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final amount in presets)
                  AppChip(
                    label: BanglaFormatters.currency(amount),
                    selected: incomeInput == amount,
                    onTap: () => onSelectPreset(amount.toDouble()),
                  ),
              ],
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
              subtitle: 'কোন নিয়মে ভাগ করবেন তা বেছে নিন',
            ),
            const SizedBox(height: AppSpacing.sm),
            // Flat rows with dividers — no card inside the card.
            for (var i = 0; i < BudgetRule.values.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: tokens.line),
              AppListTile(
                leadingIcon: selectedRule == BudgetRule.values[i]
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                leadingColor: selectedRule == BudgetRule.values[i]
                    ? tokens.primary
                    : tokens.muted,
                title: BudgetRule.values[i].label,
                subtitle: BudgetRule.values[i].description,
                trailing: selectedRule == BudgetRule.values[i]
                    ? AppChip(
                        label: 'নির্বাচিত',
                        color: tokens.primary,
                        compact: true,
                      )
                    : null,
                onTap: () => onSelectRule(BudgetRule.values[i]),
              ),
            ],
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
        icon: FeatureFlags.aiEnabled
            ? Icons.auto_awesome_rounded
            : Icons.check_rounded,
        fullWidth: true,
        onPressed: hasIncome ? onGenerate : null,
      ),
      if (hasExistingBudget && onCancel != null)
        AppActionButton(
          label: 'চলমান বাজেটে ফিরে যান',
          variant: AppActionButtonVariant.ghost,
          fullWidth: true,
          onPressed: onCancel,
        ),
    ];

    return SingleChildScrollView(
      key: const ValueKey('budget_setup_form'),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: AppStaggeredList(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            sections[i],
          ],
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
                  FeatureFlags.aiEnabled
                      ? 'AI বাজেট তৈরি করছে...'
                      : 'বাজেট তৈরি হচ্ছে...',
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
