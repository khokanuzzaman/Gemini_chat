import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';

/// 3×4 numeric keypad for whole-taka amounts: ১–৯, then ০০ · ০ · ⌫. There is no
/// decimal key (records are whole taka). Long-pressing ⌫ clears.
///
/// Every key is a labelled button (TalkBack reads "৫", "মুছুন"), >= 48dp tall, with a
/// light haptic tick. Hardware keyboards are handled by the sheet, not here.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    this.keyHeight = 52,
  });

  /// A digit `'0'`–`'9'`, or `'00'`.
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final double keyHeight;

  static const _bengaliDigits = [
    '০',
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
  ];

  @override
  Widget build(BuildContext context) {
    Widget digit(String ascii) => _Key(
      height: keyHeight,
      label: ascii == '00' ? '০০' : _bengaliDigits[int.parse(ascii)],
      semanticLabel: ascii == '00'
          ? 'দুটি শূন্য'
          : _bengaliDigits[int.parse(ascii)],
      onTap: () => onKey(ascii),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _Row(children: [for (final d in row) digit(d)]),
        _Row(
          children: [
            digit('00'),
            digit('0'),
            _Key(
              height: keyHeight,
              icon: Icons.backspace_outlined,
              semanticLabel: 'মুছুন',
              onTap: onBackspace,
              onLongPress: onClear,
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.height,
    required this.semanticLabel,
    required this.onTap,
    this.label,
    this.icon,
    this.onLongPress,
  });

  final double height;
  final String semanticLabel;
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onLongPress: onLongPress,
      child: Material(
        color: tokens.surface2,
        // surface2 is almost the sheet colour in light mode: the hairline is what
        // makes each key readable as a key.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          child: SizedBox(
            height: height,
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: AppTextStyles.displayMedium.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Icon(icon, color: tokens.ink, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
