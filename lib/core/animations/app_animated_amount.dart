import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_amount_text.dart';
import 'app_animated_value.dart';

/// Animated amount text for smooth currency transitions.
class AppAnimatedAmount extends StatelessWidget {
  const AppAnimatedAmount({
    super.key,
    required this.amount,
    this.style,
    this.isIncome = false,
    this.isExpense = false,
    this.showSign = false,
    this.duration = AppMotion.slow,
  });

  final double amount;
  final TextStyle? style;
  final bool isIncome;
  final bool isExpense;
  final bool showSign;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AppAnimatedValue(
      value: amount,
      duration: duration,
      curve: AppMotion.emphasized,
      builder: (context, animatedValue) {
        return AppAmountText(
          amount: animatedValue,
          style: style,
          isIncome: isIncome,
          isExpense: isExpense,
          showSign: showSign,
        );
      },
    );
  }
}
