import 'package:flutter/material.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';

class MultipleExpenseConfirmationWidget extends StatefulWidget {
  const MultipleExpenseConfirmationWidget({
    super.key,
    required this.expenses,
    required this.onSave,
    required this.onCancel,
  });

  final List<ExpenseData> expenses;
  final Future<void> Function(List<ExpenseData> selectedExpenses) onSave;
  final VoidCallback onCancel;

  @override
  State<MultipleExpenseConfirmationWidget> createState() =>
      _MultipleExpenseConfirmationWidgetState();
}

class _MultipleExpenseConfirmationWidgetState
    extends State<MultipleExpenseConfirmationWidget> {
  late final List<bool> _checked;
  late List<ExpenseData> _displayExpenses;

  bool get _hasOverflow => widget.expenses.length > 10;

  @override
  void initState() {
    super.initState();
    _displayExpenses = widget.expenses.take(10).toList(growable: true);
    _checked = List<bool>.filled(_displayExpenses.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final groupedExpenses = _buildGroups();
    final selectedTotal = _selectedExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final selectedDays = _selectedDistinctDays;
    final allSameDate = groupedExpenses.length <= 1;
    final hasFutureDates = _displayExpenses.any(
      (expense) => expense.isFutureDate,
    );
    final hasInvalidDates = _displayExpenses.any(
      (expense) => expense.hasInvalidDate,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        child: Card(
          elevation: 0,
          color: context.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: context.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasOverflow)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.info_outline_rounded,
                      text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
                      backgroundColor: Color(0xFFFFF7ED),
                      borderColor: Color(0xFFFED7AA),
                      textColor: Color(0xFFB45309),
                    ),
                  ),
                if (hasInvalidDates)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.info_outline_rounded,
                      text:
                          'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
                      backgroundColor: Color(0xFFF8FAFC),
                      borderColor: Color(0xFFE2E8F0),
                      textColor: Color(0xFF475569),
                    ),
                  ),
                if (hasFutureDates)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.warning_amber_rounded,
                      text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
                      backgroundColor: Color(0xFFFFF7ED),
                      borderColor: Color(0xFFFED7AA),
                      textColor: Color(0xFFB45309),
                    ),
                  ),
                if (allSameDate && groupedExpenses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GroupHeader(
                      label:
                          '${groupedExpenses.first.label} — ${BanglaFormatters.count(groupedExpenses.first.indexes.length)}টি খরচ',
                      isPastDate: groupedExpenses.first.isPastDate,
                      isFutureDate: groupedExpenses.first.isFutureDate,
                      onTap: () => _pickDateForGroup(groupedExpenses.first),
                    ),
                  )
                else
                  Text(
                    '${BanglaFormatters.count(_displayExpenses.length)}টি খরচ পাওয়া গেছে',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _displayExpenses.length > 4 ? 300 : 200,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final group in groupedExpenses) ...[
                          if (!allSameDate) ...[
                            _GroupHeader(
                              label: group.label,
                              isPastDate: group.isPastDate,
                              isFutureDate: group.isFutureDate,
                              onTap: () => _pickDateForGroup(group),
                            ),
                            const SizedBox(height: 10),
                          ],
                          for (final index in group.indexes) ...[
                            _ExpenseRow(
                              expense: _displayExpenses[index],
                              checked: _checked[index],
                              onChanged: (value) {
                                setState(() {
                                  _checked[index] = value ?? false;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        allSameDate
                            ? 'মোট: ${BanglaFormatters.currency(selectedTotal)}'
                            : 'মোট: ${BanglaFormatters.currency(selectedTotal)} — ${BanglaFormatters.count(selectedDays)}টি দিনের খরচ',
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text(AppStrings.cancelButton),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _selectedExpenses.isEmpty
                          ? null
                          : () => widget.onSave(_selectedExpenses),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text(AppStrings.saveButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_ExpenseGroup> _buildGroups() {
    final groups = <_ExpenseGroup>[];
    final indexes =
        List<int>.generate(_displayExpenses.length, (index) => index)..sort(
          (a, b) => _displayExpenses[a].parsedDate.compareTo(
            _displayExpenses[b].parsedDate,
          ),
        );

    for (final index in indexes) {
      final expense = _displayExpenses[index];
      final existingIndex = groups.indexWhere(
        (group) => ExpenseData.isSameDay(group.date, expense.parsedDate),
      );

      if (existingIndex == -1) {
        groups.add(
          _ExpenseGroup(
            date: expense.parsedDate,
            label: expense.displayDate,
            indexes: [index],
            isPastDate: expense.isPastDate,
            isFutureDate: expense.isFutureDate,
          ),
        );
      } else {
        groups[existingIndex].indexes.add(index);
      }
    }

    return groups;
  }

  Future<void> _pickDateForGroup(_ExpenseGroup group) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: group.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final isoDate = _formatIsoDate(pickedDate);
    setState(() {
      for (final index in group.indexes) {
        _displayExpenses[index] = _displayExpenses[index].copyWith(
          date: isoDate,
        );
      }
    });
  }

  List<ExpenseData> get _selectedExpenses {
    final selected = <ExpenseData>[];
    for (var index = 0; index < _displayExpenses.length; index++) {
      if (_checked[index]) {
        selected.add(_displayExpenses[index]);
      }
    }
    return selected;
  }

  int get _selectedDistinctDays {
    final uniqueDays = <String>{};
    for (final expense in _selectedExpenses) {
      uniqueDays.add(expense.isoDate);
    }
    return uniqueDays.length;
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _ExpenseGroup {
  _ExpenseGroup({
    required this.date,
    required this.label,
    required this.indexes,
    required this.isPastDate,
    required this.isFutureDate,
  });

  final DateTime date;
  final String label;
  final List<int> indexes;
  final bool isPastDate;
  final bool isFutureDate;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.isPastDate,
    required this.isFutureDate,
    required this.onTap,
  });

  final String label;
  final bool isPastDate;
  final bool isFutureDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.mutedSurfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: context.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isPastDate) ...[
              const _DateBadge(label: 'অতীত'),
              const SizedBox(width: 6),
            ],
            if (isFutureDate) ...[
              const _DateBadge(label: 'ভবিষ্যৎ'),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.edit_calendar_rounded,
              size: 16,
              color: context.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.checked,
    required this.onChanged,
  });

  final ExpenseData expense;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final categoryMeta = resolveExpenseCategory(expense.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Checkbox(value: checked, onChanged: onChanged),
            Icon(categoryMeta.icon, size: 18, color: categoryMeta.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description.trim().isEmpty
                        ? 'খরচ'
                        : expense.description,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.category,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              BanglaFormatters.currency(expense.amount),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.borderColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: context.secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
