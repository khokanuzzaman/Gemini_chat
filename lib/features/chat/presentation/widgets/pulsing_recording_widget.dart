// DEPRECATED: This widget has been replaced by recording_indicator.dart
// using the new design system. This file is kept for backward compatibility
// and should be removed in a future cleanup pass.
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
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1.55,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.28,
    end: 0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
    final secondaryPulse =
        widget.pulseColor ??
        AppColors.error.withValues(alpha: context.isDarkMode ? 0.18 : 0.1);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offsetPulse = ((_controller.value + 0.5) % 1);
          final offsetScale = 0.9 + (offsetPulse * 0.6);
          final offsetOpacity = (0.24 - (offsetPulse * 0.24)).clamp(0.0, 0.24);

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
              Opacity(
                opacity: offsetOpacity,
                child: Transform.scale(
                  scale: offsetScale,
                  child: Container(
                    width: widget.size - 6,
                    height: widget.size - 6,
                    decoration: BoxDecoration(
                      color: secondaryPulse,
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
                color: dotColor.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
