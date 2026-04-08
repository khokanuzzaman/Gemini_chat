import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A consistent header for screen sections.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = <Widget>[];
    if (action != null) {
      actionWidgets.add(action!);
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.sectionSubtitle.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actionWidgets,
        ],
      ),
    );
  }
}
