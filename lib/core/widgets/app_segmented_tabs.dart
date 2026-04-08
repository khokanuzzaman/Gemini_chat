import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A premium segmented tab bar for compact multi-tab screens.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.compact = false,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: const BorderRadius.all(AppRadius.chip),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  padding: EdgeInsets.symmetric(
                    vertical: compact ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? context.appColors.primary
                        : Colors.transparent,
                    borderRadius: const BorderRadius.all(AppRadius.chip),
                    boxShadow: i == selectedIndex
                        ? context.elevationLevel(1)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tabs[i],
                    style: AppTextStyles.chipLabel.copyWith(
                      color: i == selectedIndex
                          ? Colors.white
                          : context.secondaryTextColor,
                      fontWeight: i == selectedIndex
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
