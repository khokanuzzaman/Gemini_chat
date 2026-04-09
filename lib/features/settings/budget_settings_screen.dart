import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/budget_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bangla_formatters.dart';
import '../../core/widgets/widgets.dart';
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
    _draftBudgets = Map<String, double>.from(
      ref.read(budgetSettingsProvider).categoryBudgets,
    );
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
    final categories = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    _syncCategoryControllers(categories);

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
              subtitle: '${categories.length.toString()}টি ক্যাটাগরি সীমা',
              icon: Icons.savings_outlined,
              gradient: AppGradients.primary,
            ),
            AppCard(
              elevation: 1,
              child: Column(
                children: [
                  const AppSectionHeader(
                    padding: EdgeInsets.zero,
                    title: 'ক্যাটাগরি অনুযায়ী সীমা',
                    subtitle: 'প্রতি ক্যাটাগরির জন্য মাসিক বাজেট ঠিক করুন',
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
                await ref
                    .read(budgetSettingsProvider.notifier)
                    .saveBudgets(budgetsToSave);
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(
                  const SnackBar(content: Text('বাজেট সংরক্ষণ হয়েছে')),
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
    await ref
        .read(budgetSettingsProvider.notifier)
        .updateBudget(category, parsedValue);
  }

  void _syncCategoryControllers(List<String> categories) {
    for (final category in categories) {
      _draftBudgets.putIfAbsent(
        category,
        () => ref.read(budgetSettingsProvider).categoryBudgets[category] ?? 0,
      );
      _controllers.putIfAbsent(
        category,
        () => TextEditingController(
          text: (_draftBudgets[category] ?? 0).round().toString(),
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
