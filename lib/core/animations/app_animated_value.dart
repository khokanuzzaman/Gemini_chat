import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Smoothly animates between numeric values.
class AppAnimatedValue extends StatefulWidget {
  const AppAnimatedValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppMotion.normal,
    this.curve = AppMotion.standard,
  });

  final double value;
  final Widget Function(BuildContext context, double animatedValue) builder;
  final Duration duration;
  final Curve curve;

  @override
  State<AppAnimatedValue> createState() => _AppAnimatedValueState();
}

class _AppAnimatedValueState extends State<AppAnimatedValue> {
  late double _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(AppAnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween<double>(begin: _previousValue, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, animatedValue, _) {
        return widget.builder(context, animatedValue);
      },
    );
  }
}
