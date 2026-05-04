import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatDataCardShell extends StatelessWidget {
  const ChatDataCardShell({
    super.key,
    required this.accentColor,
    required this.child,
    this.maxWidthFactor = 0.88,
    this.padding = const EdgeInsets.all(16),
  });

  final Color accentColor;
  final Widget child;
  final double maxWidthFactor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: context.isDarkMode ? 0.16 : 0.08),
                context.cardBackgroundColor,
                context.cardBackgroundColor,
              ],
              stops: const [0, 0.24, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(
                alpha: context.isDarkMode ? 0.34 : 0.18,
              ),
            ),
            boxShadow: context.elevationLevel(2),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class ChatCardHeader extends StatelessWidget {
  const ChatCardHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.accentColor,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: context.isDarkMode ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class ChatStatChip extends StatelessWidget {
  const ChatStatChip({
    super.key,
    required this.label,
    required this.accentColor,
    this.icon,
  });

  final String label;
  final Color accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accentColor.withValues(alpha: context.isDarkMode ? 0.26 : 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSectionSurface extends StatelessWidget {
  const ChatSectionSurface({
    super.key,
    required this.child,
    this.accentColor,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accentColor;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (resolvedAccent == null
                ? context.mutedSurfaceColor
                : resolvedAccent.withValues(
                    alpha: context.isDarkMode ? 0.12 : 0.06,
                  )),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              borderColor ??
              (resolvedAccent == null
                  ? context.borderColor
                  : resolvedAccent.withValues(
                      alpha: context.isDarkMode ? 0.26 : 0.14,
                    )),
        ),
      ),
      child: child,
    );
  }
}

class ChatInfoBanner extends StatelessWidget {
  const ChatInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
