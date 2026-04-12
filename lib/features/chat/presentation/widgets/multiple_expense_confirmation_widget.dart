import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import 'chat_confirmation_primitives.dart';

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
  bool _isSaving = false;
  bool _isSaved = false;

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
    final orderedIndexes = groupedExpenses
        .expand((group) => group.indexes)
        .toList(growable: false);
    final totalAmount = _displayExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final selectedCount = _selectedExpenses.length;
    final selectedTotal = _selectedExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final hasFutureDates = _displayExpenses.any(
      (expense) => expense.isFutureDate,
    );
    final hasInvalidDates = _displayExpenses.any(
      (expense) => expense.hasInvalidDate,
    );

    return ChatConfirmationCardShell(
      accentColor: context.appColors.primary,
      maxWidthFactor: 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatConfirmationIconCircle(
                icon: Icons.list_alt_rounded,
                tintColor: context.appColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${BanglaFormatters.count(_displayExpenses.length)}টি খরচ পাওয়া গেছে',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppAmountText(
                amount: totalAmount,
                style: AppTextStyles.titleLarge,
                isExpense: true,
              ),
            ],
          ),
          if (_hasOverflow) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.info_outline_rounded,
              text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
              backgroundColor: Color(0xFFFFF7ED),
              borderColor: Color(0xFFFED7AA),
              foregroundColor: Color(0xFFB45309),
            ),
          ],
          if (hasInvalidDates) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
              backgroundColor: Color(0xFFF8FAFC),
              borderColor: Color(0xFFE2E8F0),
              foregroundColor: Color(0xFF475569),
            ),
          ],
          if (hasFutureDates) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.warning_amber_rounded,
              text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
              backgroundColor: Color(0xFFFFF7ED),
              borderColor: Color(0xFFFED7AA),
              foregroundColor: Color(0xFFB45309),
            ),
          ],
          if (groupedExpenses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in groupedExpenses)
                  AppChip(
                    label:
                        '${BanglaFormatters.fullDate(group.date)} • ${BanglaFormatters.count(group.indexes.length)}টি',
                    icon: Icons.calendar_month_rounded,
                    color: context.appColors.primary,
                    compact: true,
                    onTap: () => _pickDateForGroup(group),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                for (
                  var listIndex = 0;
                  listIndex < orderedIndexes.length;
                  listIndex++
                )
                  Column(
                    children: [
                      _ExpenseRow(
                        expense: _displayExpenses[orderedIndexes[listIndex]],
                        checked: _checked[orderedIndexes[listIndex]],
                        onTap: () {
                          setState(() {
                            _checked[orderedIndexes[listIndex]] =
                                !_checked[orderedIndexes[listIndex]];
                            _isSaved = false;
                          });
                        },
                      ),
                      if (listIndex != orderedIndexes.length - 1)
                        Divider(
                          height: 1,
                          color: context.borderColor.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ChatConfirmationMutedBox(
            child: Row(
              children: [
                Text(
                  '${BanglaFormatters.count(selectedCount)}টি নির্বাচিত',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'মোট:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                AppAmountText(
                  amount: selectedTotal,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  isExpense: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WalletSelectorWidget(
            label: null,
            selectedWalletId: effectiveWalletId,
            onChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
                _isSaved = false;
              });
            },
          ),
          const SizedBox(height: 12),
          ChatConfirmationActionSwitcher(
            isSaved: _isSaved,
            unsavedChild: ChatActionButton(
              label: 'সব সংরক্ষণ করুন',
              icon: Icons.check_rounded,
              variant: AppActionButtonVariant.primary,
              fullWidth: true,
              enabled: selectedCount > 0,
              isLoading: _isSaving,
              onPressed: () => _save(effectiveWalletId),
            ),
          ),
        ],
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
        groups.add(_ExpenseGroup(date: expense.parsedDate, indexes: [index]));
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
      _isSaved = false;
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

  Future<void> _save(int? walletId) async {
    if (_isSaving || _isSaved || _selectedExpenses.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.onSave(_selectedExpenses, walletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _ExpenseGroup {
  _ExpenseGroup({required this.date, required this.indexes});

  final DateTime date;
  final List<int> indexes;
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.checked,
    required this.onTap,
  });

  final ExpenseData expense;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryMeta = resolveExpenseCategory(expense.category);
    final description = expense.description.trim().isEmpty
        ? 'খরচ'
        : expense.description.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              ChatSelectionCheckbox(
                checked: checked,
                color: context.appColors.primary,
              ),
              const SizedBox(width: 12),
              ChatConfirmationIconCircle(
                icon: categoryMeta.icon,
                tintColor: categoryMeta.color,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.category} • ${BanglaFormatters.fullDate(expense.parsedDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppAmountText(
                amount: expense.amount,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                isExpense: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
