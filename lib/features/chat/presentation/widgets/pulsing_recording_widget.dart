import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PulsingRecordingWidget extends StatefulWidget {
  const PulsingRecordingWidget({
    super.key,
    this.color,
    this.pulseColor,
    this.size = 24,
    this.dotSize = 12,
  });

  final Color? color;
  final Color? pulseColor;
  final double size;
  final double dotSize;

  @override
  State<PulsingRecordingWidget> createState() => _PulsingRecordingWidgetState();
}

class _PulsingRecordingWidgetState extends State<PulsingRecordingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.4,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.16,
    end: 0.42,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppColors.error;
    final pulseColor =
        widget.pulseColor ??
        AppColors.error.withValues(alpha: context.isDarkMode ? 0.3 : 0.18);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: widget.size - 2,
                    height: widget.size - 2,
                    decoration: BoxDecoration(
                      color: pulseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: widget.dotSize,
          height: widget.dotSize,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.32),
                blurRadius: 8,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
