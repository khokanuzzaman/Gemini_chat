import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import 'chat_card_primitives.dart';

class MultipleExpenseConfirmationWidget extends ConsumerStatefulWidget {
  const MultipleExpenseConfirmationWidget({
    super.key,
    required this.expenses,
    required this.onSave,
    required this.onCancel,
  });

  final List<ExpenseData> expenses;
  final Future<void> Function(List<ExpenseData> selectedExpenses, int? walletId)
  onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<MultipleExpenseConfirmationWidget> createState() =>
      _MultipleExpenseConfirmationWidgetState();
}

class _MultipleExpenseConfirmationWidgetState
    extends ConsumerState<MultipleExpenseConfirmationWidget> {
  late final List<bool> _checked;
  late List<ExpenseData> _displayExpenses;
  int? _selectedWalletId;

  bool get _hasOverflow => widget.expenses.length > 10;

  @override
  void initState() {
    super.initState();
    _displayExpenses = widget.expenses.take(10).toList(growable: true);
    _checked = List<bool>.filled(_displayExpenses.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final groupedExpenses = _buildGroups();
    final selectedExpenses = _selectedExpenses;
    final selectedTotal = selectedExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final selectedDays = _selectedDistinctDays;
    final selectedCount = selectedExpenses.length;
    final allSameDate = groupedExpenses.length <= 1;
    final hasFutureDates = _displayExpenses.any(
      (expense) => expense.isFutureDate,
    );
    final hasInvalidDates = _displayExpenses.any(
      (expense) => expense.hasInvalidDate,
    );

    return ChatDataCardShell(
      accentColor: AppColors.primary,
      maxWidthFactor: 0.9,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChatCardHeader(
              icon: Icons.playlist_add_check_circle_rounded,
              title: 'গ্রুপ খরচ draft',
              subtitle: 'চাইলে item বাছাই বা তারিখ edit করুন',
              accentColor: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChatStatChip(
                  icon: Icons.receipt_long_rounded,
                  label:
                      '${BanglaFormatters.count(_displayExpenses.length)}টি খরচ',
                  accentColor: AppColors.primary,
                ),
                ChatStatChip(
                  icon: Icons.payments_rounded,
                  label: BanglaFormatters.currency(selectedTotal),
                  accentColor: AppColors.primary,
                ),
                if (!allSameDate)
                  ChatStatChip(
                    icon: Icons.calendar_month_rounded,
                    label:
                        '${BanglaFormatters.count(groupedExpenses.length)} দিন',
                    accentColor: AppColors.primary,
                  ),
              ],
            ),
            if (_hasOverflow) ...[
              const SizedBox(height: 12),
              const ChatInfoBanner(
                icon: Icons.info_outline_rounded,
                text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
                backgroundColor: Color(0xFFFFF7ED),
                borderColor: Color(0xFFFED7AA),
                textColor: Color(0xFFB45309),
              ),
            ],
            if (hasInvalidDates) ...[
              const SizedBox(height: 12),
              const ChatInfoBanner(
                icon: Icons.info_outline_rounded,
                text:
                    'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
                backgroundColor: Color(0xFFF8FAFC),
                borderColor: Color(0xFFE2E8F0),
                textColor: Color(0xFF475569),
              ),
            ],
            if (hasFutureDates) ...[
              const SizedBox(height: 12),
              const ChatInfoBanner(
                icon: Icons.warning_amber_rounded,
                text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
                backgroundColor: Color(0xFFFFF7ED),
                borderColor: Color(0xFFFED7AA),
                textColor: Color(0xFFB45309),
              ),
            ],
            const SizedBox(height: 14),
            if (allSameDate && groupedExpenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GroupHeader(
                  label:
                      '${groupedExpenses.first.label} — ${BanglaFormatters.count(groupedExpenses.first.indexes.length)}টি খরচ',
                  isPastDate: groupedExpenses.first.isPastDate,
                  isFutureDate: groupedExpenses.first.isFutureDate,
                  onTap: () => _pickDateForGroup(groupedExpenses.first),
                ),
              ),
            ChatSectionSurface(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _displayExpenses.length > 4 ? 320 : 220,
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
            ),
            const SizedBox(height: 14),
            ChatSectionSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'কোন wallet-এ যাবে',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  WalletSelectorWidget(
                    selectedWalletId: effectiveWalletId,
                    onChanged: (walletId) {
                      setState(() {
                        _selectedWalletId = walletId;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChatStatChip(
                  icon: Icons.checklist_rounded,
                  label: '${BanglaFormatters.count(selectedCount)}টি বাছাই',
                  accentColor: AppColors.primary,
                ),
                ChatStatChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: allSameDate
                      ? 'মোট ${BanglaFormatters.currency(selectedTotal)}'
                      : '${BanglaFormatters.count(selectedDays)} দিন • ${BanglaFormatters.currency(selectedTotal)}',
                  accentColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text(AppStrings.cancelButton),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: selectedExpenses.isEmpty
                        ? null
                        : () =>
                            widget.onSave(selectedExpenses, effectiveWalletId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text(AppStrings.saveButton),
                  ),
                ),
              ],
            ),
          ],
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
          color: AppColors.primary.withValues(
            alpha: context.isDarkMode ? 0.18 : 0.08,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: context.isDarkMode ? 0.28 : 0.14,
            ),
          ),
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
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: categoryMeta.color.withValues(
            alpha: context.isDarkMode ? 0.28 : 0.12,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: checked, onChanged: onChanged),
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: categoryMeta.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryMeta.icon, size: 18, color: categoryMeta.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          expense.description.trim().isEmpty
                              ? 'খরচ'
                              : expense.description,
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        BanglaFormatters.currency(expense.amount),
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: categoryMeta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          color: categoryMeta.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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
