import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A polished hero card for prominent dashboard metrics.
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
        // The decorative circle bleeds off the corner: clip it to the card's own
        // rounded shape (a bare Container does not clip its child).
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Stack(
          // The circle bleeds past the padding box on purpose; the card's own
          // antiAlias clip (above) is what rounds it, not the Stack's.
          clipBehavior: Clip.none,
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
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heroLabel.copyWith(
                            color: context.tokens.onHeroMuted,
                          ),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, color: context.tokens.onHeroMuted, size: 20),
                      ],
                    ],
                  ),
                  // Amount + subtitle on the left, the optional badge on the right IN
                  // THE SAME ROW — so the badge can never sit on top of the text,
                  // whatever the text scale.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing!,
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
