import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class PocketPilotLogo extends StatelessWidget {
  const PocketPilotLogo({
    super.key,
    this.size = 44,
    this.showShadow = false,
    this.borderRadius,
  });

  final double size;
  final bool showShadow;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);
    final shadowColor = context.isDarkMode
        ? AppColors.darkPrimary.withValues(alpha: 0.28)
        : AppColors.primary.withValues(alpha: 0.14);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '৳',
        style: TextStyle(
          color: AppColors.userBubbleTextLight,
          fontSize: size * 0.52,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class PocketPilotWordmark extends StatelessWidget {
  const PocketPilotWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PocketPilotLogo(size: compact ? 28 : 36, showShadow: !compact),
        SizedBox(width: compact ? 8 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName,
              style:
                  (compact
                          ? AppTextStyles.titleMedium
                          : AppTextStyles.titleLarge)
                      .copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.primaryTextColor,
                      ),
            ),
            if (!compact)
              Text(
                AppStrings.tagline,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
