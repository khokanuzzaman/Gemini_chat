import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/contrast.dart';

/// A reusable chip for filters, tags, and badges.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.selected = false,
    this.onTap,
    this.color,
    this.compact = false,
    this.enableHaptic = true,
    this.fullWidth = false,
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final bool compact;
  final bool enableHaptic;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // A custom [color] comes from DATA (category / wallet / status accents), so
    // the label colour is made readable here instead of at every call site:
    // - selected: primaryFill + onFill by default; a custom fill gets whichever
    //   of white / ink reads better.
    // - unselected: the accent as text on its own soft tint, nudged to >= 4.5:1.
    final accentColor = color ?? tokens.primary;
    final tint = accentColor.withValues(
      alpha: context.isDarkMode ? 0.15 : 0.08,
    );
    final tintOnSurface = Color.alphaBlend(tint, tokens.surface);
    final selectedFill = color ?? tokens.primaryFill;
    final bgColor = selected ? selectedFill : tint;
    final fgColor = selected
        ? (color == null ? tokens.onFill : labelOnFill(selectedFill))
        : readableOn(accentColor, tintOnSurface);
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: fullWidth ? TextAlign.center : TextAlign.start,
      style: AppTextStyles.chipLabel.copyWith(color: fgColor),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                if (enableHaptic) HapticFeedback.lightImpact();
                onTap!();
              },
        borderRadius: const BorderRadius.all(AppRadius.chip),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.all(AppRadius.chip),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : accentColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: fullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: fgColor),
                const SizedBox(width: 6),
              ],
              if (fullWidth) Flexible(child: labelWidget) else labelWidget,
            ],
          ),
        ),
      ),
    );
  }
}
