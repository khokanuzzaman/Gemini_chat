import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

class SmartSpendLogo extends StatelessWidget {
  const SmartSpendLogo({
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
            ? const [
                BoxShadow(
                  color: Color(0x221A73E8),
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
          color: Colors.white,
          fontSize: size * 0.52,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class SmartSpendWordmark extends StatelessWidget {
  const SmartSpendWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SmartSpendLogo(size: compact ? 28 : 36, showShadow: !compact),
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
                      .copyWith(fontWeight: FontWeight.w800),
            ),
            if (!compact)
              const Text(AppStrings.tagline, style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}
