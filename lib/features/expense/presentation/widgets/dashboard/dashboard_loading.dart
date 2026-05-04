import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        const ShimmerBox(height: 176, radius: 24),
        const SizedBox(height: AppSpacing.cardGap),
        const ShimmerBox(height: 16, radius: 8),
        const SizedBox(height: AppSpacing.sectionGap),
        const _QuickActionLoadingGrid(),
        const SizedBox(height: AppSpacing.cardGap),
        const ShimmerBox(height: 72, radius: 20),
        const SizedBox(height: AppSpacing.cardGap),
        const ShimmerBox(height: 320, radius: 20),
        const SizedBox(height: AppSpacing.cardGap),
        const ShimmerBox(height: 224, radius: 20),
        const SizedBox(height: AppSpacing.cardGap),
        SizedBox(
          height: 188,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                child: const ShimmerBox(height: 188, width: 188, radius: 20),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _QuickActionLoadingGrid extends StatelessWidget {
  const _QuickActionLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCountForWidth(constraints.maxWidth);
        final spacing = AppSpacing.tightGap;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(5, (_) {
            return SizedBox(
              width: itemWidth,
              child: const ShimmerBox(height: 48, radius: 100),
            );
          }),
        );
      },
    );
  }

  int _columnCountForWidth(double width) {
    if (width >= 720) return 5;
    if (width >= 540) return 4;
    if (width >= 400) return 3;
    return 2;
  }
}
