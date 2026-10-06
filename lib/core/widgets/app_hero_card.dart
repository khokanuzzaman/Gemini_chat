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
        // `height` is a minimum: Bengali's taller line height and larger system
        // text sizes must grow the card, not overflow it.
        constraints: BoxConstraints(minHeight: height),
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
                  color: context.tokens.onHero.withValues(alpha: 0.08),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: height - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.heroLabel.copyWith(
                          color: context.tokens.onHeroMuted,
                        ),
                      ),
                      const Spacer(),
                      if (icon != null)
                        Icon(icon, color: context.tokens.onHeroMuted, size: 20),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          amount,
                          style: AppTextStyles.heroAmount.copyWith(
                            color: context.tokens.onHero,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.tokens.onHeroMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Positioned(right: 0, bottom: 0, child: trailing!),
          ],
        ),
      ),
    );
  }
}
