import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/export/export_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/global_settings_button.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/expense_list_filter.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseListControllerProvider);
    final currentState = state.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('খরচ'),
        actions: [
          IconButton(
            onPressed: currentState == null
                ? null
                : () => _quickExport(context, currentState),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
          ),
          const GlobalSettingsButton(),
        ],
      ),
      body: state.when(
        data: (data) {
          final visibleExpenses = data.expenses
              .where((expense) {
                if (_searchQuery.isEmpty) {
                  return true;
                }
                final needle = _searchQuery.toLowerCase();
                return expense.description.toLowerCase().contains(needle) ||
                    expense.category.toLowerCase().contains(needle);
              })
              .toList(growable: false);
          final groupedExpenses = _groupByDate(visibleExpenses);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(expenseListControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _MonthSelector(filter: data.filter),
                const SizedBox(height: 16),
                _WalletFilterBar(filter: data.filter),
                const SizedBox(height: 12),
                _FilterBar(filter: data.filter),
                const SizedBox(height: 16),
                if (visibleExpenses.isEmpty)
                  const _EmptyState()
                else
                  ...groupedExpenses.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ExpenseDateSection(
                        date: entry.key,
                        expenses: entry.value,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const _ExpenseListLoading(),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'খরচের তালিকা লোড করা যায়নি\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<ExpenseEntity>> _groupByDate(
    List<ExpenseEntity> expenses,
  ) {
    final sortedExpenses = [...expenses]
      ..sort((first, second) => second.date.compareTo(first.date));
    final grouped = <DateTime, List<ExpenseEntity>>{};
    for (final expense in sortedExpenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(expense);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((first, second) => second.date.compareTo(first.date));
    }

    return grouped;
  }

  Future<void> _quickExport(
    BuildContext context,
    ExpenseListState currentState,
  ) async {
    final visibleExpenses = currentState.expenses
        .where((expense) {
          if (_searchQuery.isEmpty) {
            return true;
          }
          final needle = _searchQuery.toLowerCase();
          return expense.description.toLowerCase().contains(needle) ||
              expense.category.toLowerCase().contains(needle);
        })
        .toList(growable: false);

    final filter = currentState.filter;
    final now = DateTime.now();
    final startDate = filter.startDate ?? DateTime(now.year, now.month, 1);
    final endDate = filter.endDate ?? now;

    final error = await ref
        .read(exportProvider.notifier)
        .exportExpenses(
          expenses: visibleExpenses,
          startDate: startDate,
          endDate: endDate,
          category: filter.category,
        );

    if (!context.mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'খরচ খুঁজুন...',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.filter});

  final ExpenseListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(expenseListControllerProvider.notifier);
    final referenceDate = filter.hasDateRange
        ? filter.startDate!
        : DateTime(DateTime.now().year, DateTime.now().month, 1);

    Future<void> selectMonth(DateTime month) async {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      await controller.setDateRange(start, end);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () async {
                final previousMonth = referenceDate.month == 1
                    ? DateTime(referenceDate.year - 1, 12, 1)
                    : DateTime(referenceDate.year, referenceDate.month - 1, 1);
                await selectMonth(previousMonth);
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: referenceDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (selected != null) {
                    await selectMonth(
                      DateTime(selected.year, selected.month, 1),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    BanglaFormatters.monthYear(referenceDate),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                final nextMonth = referenceDate.month == 12
                    ? DateTime(referenceDate.year + 1, 1, 1)
                    : DateTime(referenceDate.year, referenceDate.month + 1, 1);
                if (nextMonth.isAfter(DateTime.now())) {
                  return;
                }
                await selectMonth(nextMonth);
              },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final ExpenseListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(expenseListControllerProvider.notifier);
    final categories = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'সব',
              isSelected: filter.category == null,
              onTap: () => controller.setCategory(null),
            );
          }
          final category = categories[index - 1];
          return _FilterChip(
            label: category,
            isSelected: filter.category == category,
            onTap: () => controller.setCategory(category),
          );
        },
      ),
    );
  }
}

class _WalletFilterBar extends ConsumerWidget {
  const _WalletFilterBar({required this.filter});

  final ExpenseListFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(expenseListControllerProvider.notifier);
    final walletsAsync = ref.watch(walletProvider);

    return walletsAsync.when(
      data: (wallets) {
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: wallets.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _WalletFilterChip(
                  label: 'সব ওয়ালেট',
                  isSelected: filter.walletId == null,
                  onTap: () => controller.setWallet(null),
                );
              }

              final wallet = wallets[index - 1];
              return _WalletFilterChip(
                label: wallet.name,
                emoji: wallet.emoji,
                isSelected: filter.walletId == wallet.id,
                onTap: () => controller.setWallet(wallet.id),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Row(
          children: [
            ShimmerBox(height: 36, width: 104, radius: 999),
            SizedBox(width: 8),
            ShimmerBox(height: 36, width: 96, radius: 999),
            SizedBox(width: 8),
            ShimmerBox(height: 36, width: 112, radius: 999),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _ExpenseDateSection extends ConsumerWidget {
  const _ExpenseDateSection({required this.date, required this.expenses});

  final DateTime date;
  final List<ExpenseEntity> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayTotal = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${BanglaFormatters.relativeDay(date)} — ${BanglaFormatters.currency(dayTotal)}',
            style: AppTextStyles.titleMedium,
          ),
        ),
        ...expenses.map((expense) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey('expense-${expense.id}-${expense.date}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              confirmDismiss: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('খরচ মুছবেন?'),
                      content: const Text(
                        'এই খরচটি মুছে গেলে আর ফিরে পাবেন না।',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('না'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('মুছুন'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed != true) {
                  return false;
                }

                final error = await ref
                    .read(expenseListControllerProvider.notifier)
                    .deleteExpense(expense);
                if (context.mounted && error != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
                return error == null;
              },
              child: _ExpenseCard(expense: expense),
            ),
          );
        }),
      ],
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = resolveExpenseCategory(expense.category);
    final wallet = expense.walletId == null
        ? null
        : ref.watch(walletByIdProvider(expense.walletId!));

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: context.cardBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (sheetContext) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: _EditExpenseSheet(expense: expense),
          ),
        );
        if (updated == true && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('খরচ আপডেট হয়েছে')));
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ExpenseMetaPill(
                          label: expense.category,
                          icon: meta.icon,
                          color: meta.color,
                        ),
                        if (wallet != null)
                          _WalletMetaPill(
                            emoji: wallet.emoji,
                            label: wallet.name,
                            onTap: () async {
                              final controller = ref.read(
                                expenseListControllerProvider.notifier,
                              );
                              await controller.clearFilters();
                              await controller.setWallet(wallet.id);
                            },
                          ),
                        if (expense.isManual)
                          const _ExpenseMetaPill(
                            label: 'Manual',
                            icon: Icons.edit_note_rounded,
                            color: AppColors.grey600,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      BanglaFormatters.time(expense.date),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                BanglaFormatters.currency(expense.amount),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletMetaPill extends StatelessWidget {
  const _WalletMetaPill({required this.emoji, required this.label, this.onTap});

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: context.mutedSurfaceColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletFilterChip extends StatelessWidget {
  const _WalletFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.emoji,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
        ],
        Text(label),
      ],
    );

    return ChoiceChip(
      label: labelWidget,
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: context.mutedSurfaceColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : context.primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : context.borderColor,
      ),
    );
  }
}

class _ExpenseMetaPill extends StatelessWidget {
  const _ExpenseMetaPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  const _EditExpenseSheet({required this.expense});

  final ExpenseEntity expense;

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late String _selectedCategory;
  int? _selectedWalletId;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _amountController = TextEditingController(
      text: widget.expense.amount.round().toString(),
    );
    _selectedCategory = widget.expense.category;
    _selectedWalletId =
        widget.expense.walletId ?? ref.read(activeWalletProvider)?.id;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final categories = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.contains('Other')
          ? 'Other'
          : categories.first;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('খরচ সম্পাদনা করুন', style: AppTextStyles.displayMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'বর্ণনা'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'পরিমাণ'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: const InputDecoration(labelText: 'ক্যাটাগরি'),
            ),
            const SizedBox(height: 12),
            WalletSelectorWidget(
              selectedWalletId: effectiveWalletId,
              onChanged: (walletId) {
                setState(() {
                  _selectedWalletId = walletId;
                });
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(BanglaFormatters.fullDate(_selectedDate)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time_rounded),
              label: Text(BanglaFormatters.time(_selectedDate)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('আপডেট করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final selectedWalletId =
        _selectedWalletId ?? ref.read(activeWalletProvider)?.id;

    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সব তথ্য ঠিকভাবে দিন')));
      return;
    }

    if (selectedWalletId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('একটি ওয়ালেট বেছে নিন')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await ref
        .read(expenseListControllerProvider.notifier)
        .updateExpense(
          widget.expense.copyWith(
            amount: amount,
            category: _selectedCategory,
            description: description,
            date: _selectedDate,
            walletId: selectedWalletId,
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.of(context).pop(true);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: context.mutedSurfaceColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : context.primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : context.borderColor,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.mutedSurfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 38,
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'কোনো খরচ পাওয়া যায়নি',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'অন্য filter বা তারিখ চেষ্টা করুন',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseListLoading extends StatelessWidget {
  const _ExpenseListLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        ShimmerBox(height: 54),
        SizedBox(height: 12),
        ShimmerBox(height: 64),
        SizedBox(height: 16),
        ShimmerBox(height: 40, width: 260),
        SizedBox(height: 16),
        ShimmerBox(height: 96),
        SizedBox(height: 12),
        ShimmerBox(height: 96),
        SizedBox(height: 12),
        ShimmerBox(height: 96),
        SizedBox(height: 12),
        ShimmerBox(height: 96),
      ],
    );
  }
}
