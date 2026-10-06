import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/analytics/analytics_providers.dart';
import '../../../../../core/analytics/usage_analytics.dart';
import '../../../../../core/money/amount_input.dart';
import '../../../../../core/money/whole_taka.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../category/presentation/providers/category_provider.dart';
import '../../../../recurring/presentation/providers/recurring_provider.dart';
import '../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../providers/expense_providers.dart';
import '../../utils/expense_category_meta.dart';
import '../add_entry/add_entry_sheet.dart' show categoryDisplayName;
import '../add_entry/entry_choice_chips.dart';
import '../add_entry/entry_edit_shell.dart';
import '../add_entry/entry_form_parts.dart';

/// Opens the expense edit sheet. Resolves to what happened ([EntryEditResult]) or
/// null if it was dismissed / marked recurring (which reports itself).
Future<EntryEditResult?> showEditExpenseSheet(
  BuildContext context,
  ExpenseEntity expense,
) {
  return showModalBottomSheet<EntryEditResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditExpenseSheet(expense: expense),
  );
}

/// Edit an expense with the same pieces as the add sheet: the amount (keypad
/// opens on tap), category chips, wallet and date — plus the time row, a
/// "নিয়মিত খরচ" shortcut and delete. Saves through the EXISTING
/// `ExpenseListController.updateExpense` (whole taka, ledger amend); delete goes
/// through `deleteExpense` (ledger reverse). Both refuse EMI/goal rows, which
/// never reach this sheet.
class EditExpenseSheet extends ConsumerStatefulWidget {
  const EditExpenseSheet({super.key, required this.expense});

  final ExpenseEntity expense;

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  late AmountInput _amount;
  late String _category;
  late DateTime _date;
  int? _walletId;
  bool _keypadOpen = false;
  bool _isBusy = false;
  String? _amountError;
  String? _formError;

  final _description = TextEditingController();
  final _descriptionFocus = FocusNode();
  final _shellFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    // A legacy fractional amount (e.g. ৳120.50 from before whole-taka) is shown,
    // and saved if the user saves, rounded — the same rounding the record and the
    // wallet delta use, so they cannot disagree.
    _amount = AmountInput.fromValue(wholeTaka(expense.amount).toInt());
    _category = expense.category;
    _date = expense.date;
    _walletId = expense.walletId;
    _description.text = expense.description;
    _descriptionFocus.addListener(() {
      if (!mounted) return;
      setState(() {
        if (_descriptionFocus.hasFocus) _keypadOpen = false;
      });
    });
  }

  @override
  void dispose() {
    _description.dispose();
    _descriptionFocus.dispose();
    _shellFocus.dispose();
    super.dispose();
  }

  void _onKey(String key) => setState(() {
    _amount = _amount.append(key);
    _amountError = null;
    _formError = null;
  });

  void _onBackspace() => setState(() {
    _amount = _amount.backspace();
    _amountError = null;
  });

  void _onClear() => setState(() {
    _amount = _amount.clear();
    _amountError = null;
  });

  void _toggleKeypad() {
    // Leave any text field, then keep hardware-keyboard focus on the sheet so the
    // open keypad also answers the physical keys.
    FocusScope.of(context).unfocus();
    _shellFocus.requestFocus();
    setState(() => _keypadOpen = !_keypadOpen);
  }

  KeyEventResult _onHardwareKey(FocusNode node, KeyEvent event) {
    if (!_keypadOpen || _descriptionFocus.hasFocus || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final digit = amountDigitForKey(key);
    if (digit != null) {
      _onKey(digit);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _onClear();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (!_isBusy) _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    // Editing keeps the time of day (only the day changes).
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final amount = _amount.value.toDouble();
    final walletId = _walletId ?? ref.read(activeWalletProvider)?.id;
    if (amount < 1) {
      setState(() => _amountError = 'সঠিক পরিমাণ লিখুন');
      return;
    }
    if (_category.trim().isEmpty) {
      setState(() => _formError = 'একটি ক্যাটাগরি বেছে নিন');
      return;
    }
    if (walletId == null) {
      setState(() => _formError = 'একটি ওয়ালেট বেছে নিন');
      return;
    }

    setState(() {
      _isBusy = true;
      _formError = null;
    });
    final error = await ref
        .read(expenseListControllerProvider.notifier)
        .updateExpense(
          widget.expense.copyWith(
            amount: amount,
            category: _category,
            // Empty is fine: the list shows the category name instead.
            description: _description.text.trim(),
            date: _date,
            walletId: walletId,
          ),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isBusy = false;
        _formError = error;
      });
      return;
    }
    Navigator.of(context).pop(EntryEditResult.updated);
  }

  Future<void> _delete() async {
    final expense = widget.expense;
    final confirmed = await confirmDeleteEntry(
      context,
      title: 'খরচ মুছে ফেলবেন?',
      body:
          '${expense.description.trim().isEmpty ? categoryDisplayName(expense.category) : expense.description.trim()}\n${BanglaFormatters.currency(expense.amount)}',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isBusy = true;
      _formError = null;
    });
    final error = await ref
        .read(expenseListControllerProvider.notifier)
        .deleteExpense(expense);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isBusy = false;
        _formError = error;
      });
      return;
    }
    Navigator.of(context).pop(EntryEditResult.deleted);
  }

  Future<void> _markRecurring() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // A recurring pattern needs a name: an expense saved without a description
    // is listed under its category.
    final expense = widget.expense.description.trim().isEmpty
        ? widget.expense.copyWith(
            description: categoryDisplayName(widget.expense.category),
          )
        : widget.expense;
    final result = await ref
        .read(recurringProvider.notifier)
        .markExpenseAsRecurring(expense);
    if (!mounted) return;
    final added = result == MarkRecurringResult.added;
    if (added) {
      ref
          .read(usageAnalyticsProvider)
          .entryMethodUsed(AnalyticsEntryMethod.markRecurring);
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'নিয়মিত খরচ হিসেবে চিহ্নিত হয়েছে'
                : 'এই খরচ আগে থেকেই নিয়মিত হিসেবে চিহ্নিত আছে',
          ),
          backgroundColor: added ? AppColors.success : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final names = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    // The expense's own category stays selectable even if it was since removed,
    // so opening and saving never silently re-files it.
    final categoryIds = names.contains(_category)
        ? names
        : [_category, ...names];

    return EntrySheetShell(
      title: 'খরচ সম্পাদনা',
      onKeyEvent: _onHardwareKey,
      focusNode: _shellFocus,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntryAmountEditor(
            amount: _amount,
            isIncome: false,
            expanded: _keypadOpen,
            error: _amountError,
            onToggle: _toggleKeypad,
            onKey: _onKey,
            onBackspace: _onBackspace,
            onClear: _onClear,
          ),
          const SizedBox(height: 12),
          EntryChoiceChips(
            choices: [
              for (final name in categoryIds)
                EntryChoice(
                  id: name,
                  label: categoryDisplayName(name),
                  icon: resolveExpenseCategory(name).icon,
                ),
            ],
            selectedId: _category,
            onSelected: (id) => setState(() {
              _category = id;
              _formError = null;
            }),
            selectedFill: tokens.primaryFill,
            softFill: tokens.primarySoft,
            softGlyph: tokens.primary,
          ),
          const SizedBox(height: 12),
          WalletSelectorWidget(
            label: null,
            selectedColor: tokens.primaryFill,
            selectedWalletId: _walletId ?? ref.watch(activeWalletProvider)?.id,
            onChanged: (id) => setState(() {
              _walletId = id;
              _formError = null;
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EntryDatePill(date: _date, onTap: _pickDate),
              EntryTimePill(date: _date, onTap: _pickTime),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            focusNode: _descriptionFocus,
            maxLength: 100,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.bodyLarge.copyWith(color: tokens.ink),
            decoration: entryTextDecoration(context, 'বিবরণ (ঐচ্ছিক)'),
          ),
          const SizedBox(height: 20),
          AppActionButton(
            label: 'নিয়মিত খরচ হিসেবে চিহ্নিত করুন',
            icon: Icons.repeat_rounded,
            variant: AppActionButtonVariant.ghost,
            fullWidth: true,
            onPressed: _isBusy ? null : _markRecurring,
          ),
          const SizedBox(height: 8),
          // Quiet on purpose: the primary action is "আপডেট করুন"; delete asks
          // for confirmation anyway.
          TextButton.icon(
            onPressed: _isBusy ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('মুছুন'),
            style: TextButton.styleFrom(
              foregroundColor: tokens.dangerText,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formError!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: tokens.dangerText,
                ),
              ),
            ),
          AppActionButton(
            label: 'আপডেট করুন',
            icon: Icons.check_rounded,
            fullWidth: true,
            isLoading: _isBusy,
            onPressed: _isBusy ? null : _save,
          ),
        ],
      ),
    );
  }
}
