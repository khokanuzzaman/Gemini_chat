import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? context.appColors.primary;
    final bgColor = selected
        ? accentColor
        : accentColor.withValues(alpha: context.isDarkMode ? 0.15 : 0.08);
    final fgColor = selected ? Colors.white : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: fgColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.chipLabel.copyWith(color: fgColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
