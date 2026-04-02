import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseColor = context.isDarkMode
        ? AppColors.darkSurface
        : AppColors.grey100;
    final highlightColor = context.isDarkMode
        ? AppColors.darkCard
        : AppColors.lightBackground;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 16,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: context.isDarkMode ? AppColors.darkSurface : AppColors.grey100,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
