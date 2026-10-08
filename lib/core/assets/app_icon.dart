import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

/// The PocketPilot mark, drawn from the brand SVG (assets/brand/icon_rounded.svg —
/// the source of truth; do not redraw it). The rounded corners are part of the art.
class PocketPilotLogo extends StatelessWidget {
  const PocketPilotLogo({super.key, this.size = 44, this.showShadow = false});

  static const assetPath = 'assets/brand/icon_rounded.svg';

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      semanticsLabel: AppStrings.appName,
    );
    if (!showShadow) {
      return mark;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: context.elevationLevel(2),
      ),
      child: mark,
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
