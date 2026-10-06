import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/money/amount_input.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import 'amount_keypad.dart';
import 'entry_form_parts.dart';

/// The frame both edit sheets share (and that matches the add sheet): rounded
/// top, drag handle, a title, a scrolling body and a pinned footer. It stays
/// above the keyboard, so the primary button is always reachable.
class EntrySheetShell extends StatelessWidget {
  const EntrySheetShell({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
    this.onKeyEvent,
    this.focusNode,
  });

  final String title;
  final Widget body;
  final Widget footer;

  /// Hardware keyboard (digits / backspace / enter) while the keypad is open.
  final FocusOnKeyEventCallback? onKeyEvent;

  /// Lets the sheet hand keyboard focus back here (after a text field).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(
          constraints.maxHeight * 0.94,
          constraints.maxHeight - inset,
        );
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
                  focusNode: focusNode,
                  onKeyEvent: onKeyEvent,
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
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: tokens.ink,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: body,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          border: Border(top: BorderSide(color: tokens.line)),
                        ),
                        child: SafeArea(top: false, child: footer),
                      ),
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
}

/// The amount in an edit sheet: the figure (with a pencil) and, only once it is
/// tapped, the keypad. Collapsed by default so an edit that is "just change the
/// category" is not a wall of keys.
class EntryAmountEditor extends StatelessWidget {
  const EntryAmountEditor({
    super.key,
    required this.amount,
    required this.isIncome,
    required this.expanded,
    required this.error,
    required this.onToggle,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
  });

  final AmountInput amount;
  final bool isIncome;
  final bool expanded;
  final String? error;
  final VoidCallback onToggle;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryAmountDisplay(
          amount: amount,
          isIncome: isIncome,
          error: error,
          editable: !expanded,
          onTap: onToggle,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AmountKeypad(
                    keyHeight: 48,
                    onKey: onKey,
                    onBackspace: onBackspace,
                    onClear: onClear,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The delete confirmation both edit sheets (and the lists) use.
Future<bool> confirmDeleteEntry(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        AppActionButton(
          label: 'বাতিল',
          variant: AppActionButtonVariant.ghost,
          size: AppActionButtonSize.small,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AppActionButton(
          label: 'মুছুন',
          variant: AppActionButtonVariant.danger,
          size: AppActionButtonSize.small,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed == true;
}
