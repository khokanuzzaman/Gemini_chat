import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/bangla_formatters.dart';

/// A specialized Text widget for formatted financial amounts.
class AppAmountText extends StatelessWidget {
  const AppAmountText({
    super.key,
    required this.amount,
    this.style,
    this.showSign = false,
    this.isIncome = false,
    this.isExpense = false,
    this.compact = false,
  });

  final double amount;
  final TextStyle? style;
  final bool showSign;
  final bool isIncome;
  final bool isExpense;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color color = context.primaryTextColor;
    String prefix = '';

    if (isIncome) {
      color = context.incomeColor;
      if (showSign) {
        prefix = '+';
      }
    } else if (isExpense) {
      color = context.expenseColor;
      if (showSign) {
        prefix = '-';
      }
    }

    final formatted = BanglaFormatters.currency(amount.abs());
    final displayText = '$prefix$formatted';

    return Text(
      displayText,
      style: (style ?? AppTextStyles.statValue).copyWith(color: color),
    );
  }
}
