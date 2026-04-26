import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/budget_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bangla_formatters.dart';
import '../../core/widgets/widgets.dart';
import '../budget/presentation/providers/budget_provider.dart';
import '../category/presentation/providers/category_provider.dart';
import '../expense/presentation/utils/expense_category_meta.dart';

class BudgetSettingsScreen extends ConsumerStatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  ConsumerState<BudgetSettingsScreen> createState() =>
      _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  late final Map<String, TextEditingController> _controllers;
  late Map<String, double> _draftBudgets;

  @override
  void initState() {
    super.initState();
    _draftBudgets = {};
    _controllers = {};
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBudget = ref.watch(budgetProvider).activeBudget;
    final healthReport = ref.watch(budgetHealthReportProvider).valueOrNull;
    final usingActiveBudget = activeBudget != null;
    final sourceBudgets = ref.watch(effectiveBudgetLimitsProvider);
    final categories = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    _syncCategoryControllers(categories, sourceBudgets);

    final totalBudget = categories.fold<double>(
      0,
      (sum, category) => sum + (_draftBudgets[category] ?? 0),
    );

    return AppPageScaffold(
      title: 'বাজেট সেটিংস',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppStaggeredList(
          children: [
            AppHeroCard(
              label: 'মাসিক মোট বাজেট',
              amount: BanglaFormatters.currency(totalBudget),
              subtitle: usingActiveBudget
                  ? '${categories.length.toString()}টি ক্যাটাগরি · active budget plan'
                  : 'Active budget না থাকলে এগুলো fallback limit হিসেবে থাকবে',
              icon: Icons.savings_outlined,
              gradient: AppGradients.primary,
            ),
            if (healthReport?.hasIssues ?? false)
              _BudgetHealthCard(report: healthReport!),
            AppCard(
              elevation: 1,
              child: Column(
                children: [
                  AppSectionHeader(
                    padding: EdgeInsets.zero,
                    title: 'ক্যাটাগরি অনুযায়ী সীমা',
                    subtitle: usingActiveBudget
                        ? 'এখানকার পরিবর্তন active budget plan-এ সরাসরি সেভ হবে'
                        : 'Active budget না থাকলে notification/dashboard fallback হিসেবে ব্যবহার হবে',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (var index = 0; index < categories.length; index++) ...[
                    _BudgetLimitRow(
                      category: categories[index],
                      controller: _controllers[categories[index]]!,
                      onChanged: (value) =>
                          _handleBudgetChange(categories[index], value),
                    ),
                    if (index != categories.length - 1)
                      Divider(
                        height: AppSpacing.lg,
                        color: context.borderColor.withValues(alpha: 0.3),
                      ),
                  ],
                ],
              ),
            ),
            AppActionButton(
              label: 'সংরক্ষণ করুন',
              icon: Icons.check_rounded,
              fullWidth: true,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final budgetsToSave = <String, double>{
                  for (final category in categories)
                    category: _draftBudgets[category] ?? 0,
                };
                if (usingActiveBudget) {
                  await ref
                      .read(budgetProvider.notifier)
                      .saveCategoryBudgets(budgetsToSave);
                } else {
                  await ref
                      .read(budgetSettingsProvider.notifier)
                      .saveBudgets(budgetsToSave);
                }
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      usingActiveBudget
                          ? 'Active budget আপডেট হয়েছে'
                          : 'বাজেট সীমা সংরক্ষণ হয়েছে',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBudgetChange(String category, String rawValue) async {
    final parsedValue = double.tryParse(rawValue.trim()) ?? 0;
    setState(() {
      _draftBudgets[category] = parsedValue;
    });
  }

  void _syncCategoryControllers(
    List<String> categories,
    Map<String, double> sourceBudgets,
  ) {
    for (final category in categories) {
      _draftBudgets.putIfAbsent(category, () => sourceBudgets[category] ?? 0);
      _controllers.putIfAbsent(
        category,
        () => TextEditingController(
          text: _formatBudgetValue(_draftBudgets[category] ?? 0),
        ),
      );
    }

    final removedCategories = _controllers.keys
        .where((category) => !categories.contains(category))
        .toList(growable: false);
    for (final category in removedCategories) {
      _controllers.remove(category)?.dispose();
      _draftBudgets.remove(category);
    }
  }

  String _formatBudgetValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.report});

  final BudgetHealthReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      gradient: LinearGradient(
        colors: [
          AppColors.warning.withValues(alpha: 0.14),
          AppColors.warning.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            title: 'Budget health check',
            subtitle: 'পুরোনো ক্যাটাগরি রেফারেন্স আছে কিনা দেখুন',
          ),
          if (report.activeBudgetOrphans.isNotEmpty)
            Text(
              'Active budget: ${report.activeBudgetOrphans.join(', ')}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          if (report.historicalPlansWithOrphans > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'History: ${report.historicalPlansWithOrphans}টি প্ল্যানে পুরোনো ক্যাটাগরি আছে (${report.historicalOrphans.join(', ')})',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
          if (report.expenseHistoryOrphans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Expense history: ${report.expenseHistoryOrphans.join(', ')}',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetLimitRow extends StatelessWidget {
  const _BudgetLimitRow({
    required this.category,
    required this.controller,
    required this.onChanged,
  });

  final String category;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(category);

    return AppListTile(
      leadingIcon: meta.icon,
      leadingColor: meta.color,
      title: category,
      subtitle: 'মাসিক সীমা নির্ধারণ করুন',
      trailing: SizedBox(
        width: 124,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            isDense: true,
            prefixText: '৳ ',
            filled: true,
            fillColor: context.mutedSurfaceColor,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.input),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.input),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.input),
              borderSide: BorderSide(color: meta.color),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
