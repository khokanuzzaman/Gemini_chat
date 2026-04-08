import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A reusable card container with consistent styling and optional tap handling.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.elevation = 2,
    this.onTap,
    this.gradient,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final int elevation;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.cardAll;
    final decoration = BoxDecoration(
      gradient: gradient,
      color: gradient == null ? context.cardBackgroundColor : null,
      borderRadius: radius,
      boxShadow: context.elevationLevel(elevation),
      border: gradient == null
          ? Border.all(
              color: context.borderColor.withValues(
                alpha: context.isDarkMode ? 0.4 : 0.6,
              ),
              width: 0.5,
            )
          : null,
    );

    return Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
