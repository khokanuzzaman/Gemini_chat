import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/analytics/analytics_providers.dart';
import '../../../../../core/analytics/usage_analytics.dart';
import '../../../../../core/money/amount_input.dart';
import '../../../../../core/providers/shared_preferences_provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../category/presentation/providers/category_provider.dart';
import '../../../../income/domain/entities/income_entity.dart';
import '../../../../income/domain/entities/income_source.dart';
import '../../../../income/presentation/providers/income_providers.dart';
import '../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../providers/expense_providers.dart';
import '../../utils/expense_category_meta.dart';
import 'amount_keypad.dart';
import 'entry_choice_chips.dart';
import 'entry_form_parts.dart';
import 'entry_type.dart';
import 'entry_type_toggle.dart';
import 'last_used_choice.dart';
import '../../../../../core/utils/category_display_name.dart';

export '../../../../../core/utils/category_display_name.dart'
    show categoryDisplayName;

/// Opens the add sheet (খরচ | আয়) and, when something was saved, shows the matching
/// confirmation. The ONE way to add an expense or income by hand: Home FAB, the
/// খরচ tab, the empty state, the offline banner, chat and the income list all come
/// through here.
Future<void> showAddEntrySheet(
  BuildContext context, {
  EntryType initialType = EntryType.expense,
}) async {
  final saved = await showModalBottomSheet<EntryType>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEntrySheet(initialType: initialType),
  );
  if (saved == null || !context.mounted) {
    return;
  }
  final tokens = context.tokens;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: tokens.successFill,
        content: Text(
          saved == EntryType.expense
              ? 'খরচ সংরক্ষণ হয়েছে'
              : 'আয় সংরক্ষণ হয়েছে',
          style: TextStyle(color: tokens.onFill),
        ),
      ),
    );
}

/// The add sheet's body. Public for tests; open it with [showAddEntrySheet].
class AddEntrySheet extends ConsumerStatefulWidget {
  const AddEntrySheet({super.key, this.initialType = EntryType.expense});

  final EntryType initialType;

  @override
  ConsumerState<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<AddEntrySheet> {
  late EntryType _type = widget.initialType;
  AmountInput _amount = const AmountInput.empty();
  String? _expenseCategory;
  String? _incomeSource;
  int? _walletId;
  late DateTime _date = DateTime.now();
  bool _isRecurring = false;
  bool _isSaving = false;
  String? _amountError;
  String? _formError;

  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    final categoryNames = _categoryNames;
    _expenseCategory = LastUsedEntryChoice.resolve(
      stored: LastUsedEntryChoice.read(prefs, EntryType.expense),
      available: categoryNames,
      fallback: LastUsedEntryChoice.defaultExpenseCategory(categoryNames),
    );
    _incomeSource = LastUsedEntryChoice.resolve(
      stored: LastUsedEntryChoice.read(prefs, EntryType.income),
      available: [for (final source in defaultIncomeSources) source.name],
      fallback: null, // income has never preselected a source
    );
    _noteFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  List<String> get _categoryNames => ref
      .read(categoryProvider)
      .map((category) => category.name)
      .toList(growable: false);

  bool get _isIncome => _type == EntryType.income;
  bool get _noteEditing => _noteFocus.hasFocus;

  // ── input ────────────────────────────────────────────────────────────────
  void _onKey(String key) {
    setState(() {
      _amount = _amount.append(key);
      _amountError = null;
      _formError = null;
    });
  }

  void _onBackspace() {
    setState(() {
      _amount = _amount.backspace();
      _amountError = null;
    });
  }

  void _onClear() {
    setState(() {
      _amount = _amount.clear();
      _amountError = null;
    });
  }

  KeyEventResult _onHardwareKey(FocusNode node, KeyEvent event) {
    // While typing a note the text field owns the keyboard.
    if (_noteEditing || event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final digit = _digitFor(key);
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
      if (!_isSaving) _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String? _digitFor(LogicalKeyboardKey key) => amountDigitForKey(key);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }
    final today = DateTime.now();
    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final pastDay = pickedDay.isBefore(todayDay);
    setState(() {
      // Same convention as before: a past day is stamped end-of-day so it sorts
      // after that day's other entries; today keeps the current time.
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pastDay ? 23 : _date.hour,
        pastDay ? 59 : _date.minute,
      );
    });
  }

  // ── save: the EXISTING controllers, unchanged ───────────────────────────
  Future<void> _save() async {
    final amount = _amount.value.toDouble();
    final walletId = _walletId ?? ref.read(activeWalletProvider)?.id;

    if (amount < 1) {
      setState(() => _amountError = 'সঠিক পরিমাণ লিখুন');
      return;
    }
    if (!_isIncome && (_expenseCategory ?? '').trim().isEmpty) {
      setState(() => _formError = 'একটি ক্যাটাগরি বেছে নিন');
      return;
    }
    if (_isIncome && (_incomeSource ?? '').trim().isEmpty) {
      setState(() => _formError = 'একটি উৎস নির্বাচন করুন');
      return;
    }
    if (walletId == null) {
      setState(() => _formError = 'একটি ওয়ালেট বেছে নিন');
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });

    final note = _noteController.text.trim();
    final String? error;
    if (_isIncome) {
      error = await ref
          .read(incomeMutationControllerProvider)
          .saveManualIncome(
            IncomeEntity(
              amount: amount,
              source: _incomeSource!,
              description: note,
              date: _date,
              walletId: walletId,
              isRecurring: _isRecurring,
              isManual: true,
              createdAt: DateTime.now(),
            ),
            walletId: walletId,
          );
    } else {
      error = await ref
          .read(expenseMutationControllerProvider)
          .saveManualExpense(
            ExpenseEntity(
              amount: amount,
              category: _expenseCategory!,
              description: note,
              date: _date,
              isManual: true,
            ),
            walletId: walletId,
          );
    }

    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() {
        _isSaving = false;
        _formError = error;
      });
      return;
    }

    ref
        .read(usageAnalyticsProvider)
        .entryMethodUsed(
          _isIncome
              ? AnalyticsEntryMethod.manualIncome
              : AnalyticsEntryMethod.manualExpense,
        );
    // Remember what was used, per type (preferences only).
    final prefs = ref.read(sharedPreferencesProvider);
    await LastUsedEntryChoice.write(
      prefs,
      _type,
      _isIncome ? _incomeSource! : _expenseCategory!,
    );
    if (mounted) {
      Navigator.of(context).pop(_type);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ~94% of the screen; shrinks above the keyboard when the note is open.
        final height = math.min(
          constraints.maxHeight * 0.94,
          constraints.maxHeight - inset,
        );
        final keyHeight = height < 560 ? 48.0 : 52.0;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: SizedBox(
              height: height,
              child: Material(
                color: tokens.surface,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: AppRadius.sheet),
                ),
                child: Focus(
                  autofocus: true,
                  onKeyEvent: _onHardwareKey,
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tokens.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: EntryTypeToggle(
                          type: _type,
                          onChanged: (type) => setState(() {
                            _type = type;
                            _formError = null;
                          }),
                        ),
                      ),
                      Expanded(
                        child: _buildScrollArea(context, short: height < 600),
                      ),
                      _buildFooter(context, keyHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollArea(BuildContext context, {required bool short}) {
    final tokens = context.tokens;
    final categories = _categoryNames;

    final choices = _isIncome
        ? [
            for (final source in defaultIncomeSources)
              EntryChoice(
                id: source.name,
                label: source.banglaLabel,
                emoji: source.emoji,
              ),
          ]
        : [
            for (final name in categories)
              EntryChoice(
                id: name,
                label: categoryDisplayName(name),
                icon: resolveExpenseCategory(name).icon,
              ),
          ];

    final editingNote = _noteEditing;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EntryAmountDisplay(
            amount: _amount,
            isIncome: _isIncome,
            error: _amountError,
            // With the system keyboard up (or on a short phone) there is little
            // room: the amount shrinks to one line; with the keyboard up the
            // chips/wallet also step aside until the note is done.
            compact: editingNote || short,
            onTap: () => FocusScope.of(context).unfocus(),
          ),
          if (!editingNote) ...[
            const SizedBox(height: 12),
            EntryChoiceChips(
              choices: choices,
              selectedId: _isIncome ? _incomeSource : _expenseCategory,
              onSelected: (id) => setState(() {
                if (_isIncome) {
                  _incomeSource = id;
                } else {
                  _expenseCategory = id;
                }
                _formError = null;
              }),
              selectedFill: _isIncome ? tokens.successFill : tokens.primaryFill,
              softFill: _isIncome ? tokens.successSoft : tokens.primarySoft,
              softGlyph: _isIncome ? tokens.successText : tokens.primary,
            ),
            const SizedBox(height: 12),
            WalletSelectorWidget(
              label: null,
              selectedColor: _isIncome
                  ? tokens.successFill
                  : tokens.primaryFill,
              selectedWalletId:
                  _walletId ?? ref.watch(activeWalletProvider)?.id,
              onChanged: (id) => setState(() {
                _walletId = id;
                _formError = null;
              }),
            ),
          ],
          const SizedBox(height: 12),
          // Date and note share a row so the whole form fits above the keypad.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntryDatePill(date: _date, onTap: _pickDate),
              const SizedBox(width: 8),
              Expanded(child: _noteField(tokens)),
            ],
          ),
          if (_isIncome && !editingNote) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: EntryRecurringSwitch(
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noteField(AppTokens tokens) {
    return TextField(
      controller: _noteController,
      focusNode: _noteFocus,
      maxLength: 100,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      style: AppTextStyles.bodyLarge.copyWith(color: tokens.ink),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'নোট (ঐচ্ছিক)',
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: tokens.muted),
        isDense: true,
        filled: true,
        fillColor: tokens.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.inputOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.inputOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, double keyHeight) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The keypad gives way to the system keyboard while a note is typed.
            if (!_noteEditing)
              AmountKeypad(
                keyHeight: keyHeight,
                onKey: _onKey,
                onBackspace: _onBackspace,
                onClear: _onClear,
              ),
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
              label: 'সেভ করুন',
              icon: Icons.check_rounded,
              variant: _isIncome
                  ? AppActionButtonVariant.success
                  : AppActionButtonVariant.primary,
              fullWidth: true,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
