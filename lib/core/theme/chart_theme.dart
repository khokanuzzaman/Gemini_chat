import 'package:flutter/material.dart';

import 'app_theme.dart';

class ChartTheme {
  const ChartTheme._();

  static Color gridLine(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkText.withValues(alpha: 0.1)
        : AppColors.lightText.withValues(alpha: 0.08);
  }

  static Color tooltipBackground(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color tooltipText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color barBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkText.withValues(alpha: 0.06)
        : AppColors.lightText.withValues(alpha: 0.04);
  }
}
