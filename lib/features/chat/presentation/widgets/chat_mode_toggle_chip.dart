import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatModeToggleChip extends StatelessWidget {
  const ChatModeToggleChip({
    super.key,
    required this.enabled,
    required this.isActive,
    required this.onTap,
  });

  final bool enabled;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.appColors.primary;
    final backgroundColor = isActive
        ? activeColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.14)
        : context.mutedSurfaceColor;
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.36)
        : context.borderColor;
    final contentColor = enabled
        ? (isActive ? activeColor : context.primaryTextColor)
        : context.secondaryTextColor.withValues(alpha: 0.72);

    return Tooltip(
      message: isActive ? 'স্মার্ট মোড চালু' : 'সাধারণ মোড চালু',
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: contentColor,
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      isActive ? 'স্মার্ট' : 'সাধারণ',
                      key: ValueKey(isActive),
                      style: AppTextStyles.chipLabel.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
