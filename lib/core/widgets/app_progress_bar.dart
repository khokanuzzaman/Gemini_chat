import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A reusable progress bar with animated fill and optional label.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.showLabel = false,
    this.label,
  });

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final fillColor = color ?? context.appColors.primary;
    final bgColor = backgroundColor ??
        fillColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              Text(
                '${(clamped * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.chipLabel.copyWith(color: fillColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              Container(
                height: height,
                color: bgColor,
              ),
              AnimatedFractionallySizedBox(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                widthFactor: clamped,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        fillColor.withValues(alpha: 0.85),
                        fillColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
