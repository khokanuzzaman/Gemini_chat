import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/global_settings_button.dart';
import '../../../../core/utils/bangla_formatters.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('খরচ'),
        actions: const [GlobalSettingsButton()],
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

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: expenseCategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'সব',
              isSelected: filter.category == null,
              onTap: () => controller.setCategory(null),
            );
          }
          final category = expenseCategories[index - 1];
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
                    Text(
                      '${expense.category} · ${BanglaFormatters.time(expense.date)}',
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
              items: expenseCategories
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

    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সব তথ্য ঠিকভাবে দিন')));
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
