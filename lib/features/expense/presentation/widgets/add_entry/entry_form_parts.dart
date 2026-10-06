import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/money/amount_input.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';

/// Pieces the add sheet and the two edit sheets share, so an amount, a date or
/// the "প্রতি মাসে" switch looks and behaves the same everywhere.

/// What an edit sheet closes with.
enum EntryEditResult { updated, deleted }

final _amountDigitKeys = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.digit0: '0',
  LogicalKeyboardKey.digit1: '1',
  LogicalKeyboardKey.digit2: '2',
  LogicalKeyboardKey.digit3: '3',
  LogicalKeyboardKey.digit4: '4',
  LogicalKeyboardKey.digit5: '5',
  LogicalKeyboardKey.digit6: '6',
  LogicalKeyboardKey.digit7: '7',
  LogicalKeyboardKey.digit8: '8',
  LogicalKeyboardKey.digit9: '9',
  LogicalKeyboardKey.numpad0: '0',
  LogicalKeyboardKey.numpad1: '1',
  LogicalKeyboardKey.numpad2: '2',
  LogicalKeyboardKey.numpad3: '3',
  LogicalKeyboardKey.numpad4: '4',
  LogicalKeyboardKey.numpad5: '5',
  LogicalKeyboardKey.numpad6: '6',
  LogicalKeyboardKey.numpad7: '7',
  LogicalKeyboardKey.numpad8: '8',
  LogicalKeyboardKey.numpad9: '9',
};

/// "0"–"9" for a digit key (top row or numpad), else null.
String? amountDigitForKey(LogicalKeyboardKey key) => _amountDigitKeys[key];

/// "পরিমাণ" and the big ৳ figure, with live Bengali grouping.
class EntryAmountDisplay extends StatelessWidget {
  const EntryAmountDisplay({
    super.key,
    required this.amount,
    required this.isIncome,
    required this.error,
    required this.onTap,
    this.compact = false,
    this.editable = false,
  });

  final AmountInput amount;
  final bool isIncome;
  final String? error;
  final VoidCallback onTap;
  final bool compact;

  /// Shows a pencil: the figure is tapped to open the keypad (edit sheets).
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = amount.isEmpty
        ? tokens.muted
        : (isIncome ? tokens.successText : tokens.ink);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        liveRegion: true,
        label: amount.isEmpty
            ? 'পরিমাণ এখনো দেওয়া হয়নি'
            : 'পরিমাণ ${BanglaFormatters.currency(amount.value)}',
        excludeSemantics: true,
        child: Column(
          children: [
            if (!compact) ...[
              Text(
                'পরিমাণ',
                style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
              ),
              const SizedBox(height: 4),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${BanglaFormatters.currencySymbol} ${amount.display}',
                    maxLines: 1,
                    style:
                        (compact
                                ? AppTextStyles.displayMedium
                                : AppTextStyles.heroAmount)
                            .copyWith(color: color),
                  ),
                  if (editable) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.edit_rounded, size: 22, color: tokens.muted),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: compact ? 0 : 20,
              child: error == null || compact
                  ? null
                  : Text(
                      error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: tokens.dangerText,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryDatePill extends StatelessWidget {
  const EntryDatePill({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    return Semantics(
      button: true,
      label: 'তারিখ বদলান',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.inputOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: tokens.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isToday ? 'আজ' : BanglaFormatters.fullDate(date),
                style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryRecurringSwitch extends StatelessWidget {
  const EntryRecurringSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      toggled: value,
      label: 'প্রতি মাসে',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'প্রতি মাসে',
              style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: tokens.successFill,
                activeThumbColor: tokens.onFill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The time of day, next to [EntryDatePill] — kept from the old expense edit
/// (it had separate date and time rows).
class EntryTimePill extends StatelessWidget {
  const EntryTimePill({super.key, required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: 'সময় বদলান',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.inputOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: tokens.primary),
              const SizedBox(width: 8),
              Text(
                BanglaFormatters.time(date),
                style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, color: tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped single-line text field used for the edit sheets' description/note.
InputDecoration entryTextDecoration(BuildContext context, String hint) {
  final tokens = context.tokens;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    counterText: '',
    hintText: hint,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: tokens.muted),
    isDense: true,
    filled: true,
    fillColor: tokens.surface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: border(tokens.inputOutline),
    enabledBorder: border(tokens.inputOutline),
    focusedBorder: border(tokens.primary, 1.5),
  );
}
