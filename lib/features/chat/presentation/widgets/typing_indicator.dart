import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({super.key});

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.aiBubbleColor;
    final dotColor = context.secondaryTextColor;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final offset = (_controller.value - (index * 0.18) + 1) % 1;
                    final opacity =
                        0.25 + (1 - (offset - 0.5).abs() * 2) * 0.75;

                    return Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                      child: Opacity(
                        opacity: opacity.clamp(0.25, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(height: 8, width: 8),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
