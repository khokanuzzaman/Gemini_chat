import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_shimmer.dart';

/// A reusable shimmer loading placeholder for common layouts.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState.card({
    super.key,
    this.height = 140,
  }) : type = AppLoadingType.card;

  const AppLoadingState.list({
    super.key,
    this.height = 72,
  }) : type = AppLoadingType.list;

  const AppLoadingState.heroCard({super.key})
      : type = AppLoadingType.heroCard,
        height = 140;

  const AppLoadingState.statRow({super.key})
      : type = AppLoadingType.statRow,
        height = 100;

  final AppLoadingType type;
  final double height;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      AppLoadingType.card => _shimmerBox(context, height),
      AppLoadingType.heroCard =>
        _shimmerBox(context, 140, radius: AppRadius.heroCardAll),
      AppLoadingType.list => Column(
          children: List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _shimmerBox(context, 72),
            ),
          ),
        ),
      AppLoadingType.statRow => Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                child: _shimmerBox(context, 100),
              ),
            ),
          ),
        ),
    };
  }

  Widget _shimmerBox(BuildContext context, double h, {BorderRadius? radius}) {
    return AppShimmer(
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: radius ?? AppRadius.cardAll,
        ),
      ),
    );
  }
}

enum AppLoadingType { card, heroCard, list, statRow }
