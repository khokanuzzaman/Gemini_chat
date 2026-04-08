import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A premium hero card for prominent dashboard metrics.
class AppHeroCard extends StatelessWidget {
  const AppHeroCard({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.icon,
    this.gradient,
    this.onTap,
    this.trailing,
    this.height = 140,
  });

  final String label;
  final String amount;
  final String? subtitle;
  final IconData? icon;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: context.heroCardDecoration(gradient: gradient),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.heroLabel.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    if (icon != null)
                      Icon(
                        icon,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 20,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amount,
                      style: AppTextStyles.heroAmount.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (trailing != null)
              Positioned(right: 0, bottom: 0, child: trailing!),
          ],
        ),
      ),
    );
  }
}
