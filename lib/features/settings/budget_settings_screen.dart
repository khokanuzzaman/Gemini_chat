import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/budget_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bangla_formatters.dart';
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
      ref.read(budgetProvider).categoryBudgets,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Category Budget')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: categories
                    .map((category) {
                      final meta = resolveExpenseCategory(category);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: meta.color.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(meta.icon, color: meta.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                category,
                                style: AppTextStyles.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 130,
                              child: TextField(
                                controller: _controllers[category],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  prefixText: '৳ ',
                                  isDense: true,
                                ),
                                onChanged: (value) =>
                                    _handleBudgetChange(category, value),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'মাসিক মোট বাজেট: ${BanglaFormatters.currency(totalBudget)}',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final budgetsToSave = <String, double>{
                for (final category in categories)
                  category: _draftBudgets[category] ?? 0,
              };
              await ref
                  .read(budgetProvider.notifier)
                  .saveBudgets(budgetsToSave);
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Budget save হয়েছে')),
              );
            },
            child: const Text('Save budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBudgetChange(String category, String rawValue) async {
    final parsedValue = double.tryParse(rawValue.trim()) ?? 0;
    setState(() {
      _draftBudgets[category] = parsedValue;
    });
    await ref.read(budgetProvider.notifier).updateBudget(category, parsedValue);
  }

  void _syncCategoryControllers(List<String> categories) {
    for (final category in categories) {
      _draftBudgets.putIfAbsent(
        category,
        () => ref.read(budgetProvider).categoryBudgets[category] ?? 0,
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
