import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

Future<void> showManualAddSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => const _ManualAddSheet(),
  );

  if (saved != true || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('Expense save হয়েছে'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
}

class _ManualAddSheet extends ConsumerStatefulWidget {
  const _ManualAddSheet();

  @override
  ConsumerState<_ManualAddSheet> createState() => _ManualAddSheetState();
}

class _ManualAddSheetState extends ConsumerState<_ManualAddSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoryProvider);
    final categoryNames = categories
        .map((category) => category.name)
        .toList(growable: false);
    if (!categoryNames.contains(_selectedCategory) &&
        categoryNames.isNotEmpty) {
      _selectedCategory = categoryNames.contains('Other')
          ? 'Other'
          : categoryNames.first;
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Expense add করুন',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Offline mode — সরাসরি যোগ করা হচ্ছে',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: context.borderColor),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'পরিমাণ (টাকা)',
                prefixText: '৳ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'বিবরণ',
                hintText: 'কী কিনলেন বা কোথায় খরচ হলো?',
              ),
            ),
            const SizedBox(height: 8),
            const Text('Category', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryNames
                  .map((category) {
                    final meta = resolveExpenseCategory(category);
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      avatar: Icon(
                        meta.icon,
                        size: 14,
                        color: isSelected ? Colors.white : meta.color,
                      ),
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: meta.color,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? meta.color
                            : theme.dividerColor.withValues(alpha: 0.6),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(BanglaFormatters.fullDate(_selectedDate)),
                    const Spacer(),
                    Text(
                      'পরিবর্তন করুন',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save করুন'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('সঠিক পরিমাণ লিখুন')));
      return;
    }

    if (_selectedCategory.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('একটি category বেছে নিন')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final expense = ExpenseEntity(
      amount: amount,
      category: _selectedCategory,
      description: description,
      date: _selectedDate,
      isManual: true,
    );

    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveManualExpense(expense);

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
