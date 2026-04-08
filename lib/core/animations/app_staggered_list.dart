import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_fade_slide_in.dart';

/// Wraps children and applies staggered entrance animations.
class AppStaggeredList extends StatelessWidget {
  const AppStaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = AppMotion.staggerDelay,
    this.itemDuration = AppMotion.normal,
    this.initialDelay = Duration.zero,
    this.offset = const Offset(0, 0.15),
    this.curve = AppMotion.standard,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Duration initialDelay;
  final Offset offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          AppFadeSlideIn(
            delay: initialDelay + (staggerDelay * i),
            duration: itemDuration,
            offset: offset,
            curve: curve,
            child: children[i],
          ),
      ],
    );
  }
}
