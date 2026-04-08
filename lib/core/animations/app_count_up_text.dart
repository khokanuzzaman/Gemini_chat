import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/bangla_formatters.dart';
import 'app_animated_value.dart';

/// Counts up from previous value to a target integer.
class AppCountUpText extends StatelessWidget {
  const AppCountUpText({
    super.key,
    required this.value,
    this.style,
    this.duration = AppMotion.slow,
    this.useBanglaDigits = true,
    this.suffix = '',
    this.prefix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final bool useBanglaDigits;
  final String suffix;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return AppAnimatedValue(
      value: value.toDouble(),
      duration: duration,
      curve: AppMotion.emphasized,
      builder: (context, animatedValue) {
        final intValue = animatedValue.round();
        final formatted = useBanglaDigits
            ? BanglaFormatters.count(intValue)
            : intValue.toString();
        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}
