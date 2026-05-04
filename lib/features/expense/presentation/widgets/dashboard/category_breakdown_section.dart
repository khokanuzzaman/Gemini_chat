import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../budget/presentation/providers/budget_provider.dart';
import '../../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../../category/presentation/providers/category_provider.dart';
import '../../providers/expense_providers.dart';
import '../../utils/expense_category_meta.dart';

class CategoryBreakdownSection extends ConsumerWidget {
  const CategoryBreakdownSection({super.key, required this.onTapCategory});

  final ValueChanged<String?> onTapCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);
    final data = dashboard.valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final categoryNames = ref
        .watch(categoryProvider)
        .map((category) => category.name)
        .toList(growable: false);
    final budgets = ref.watch(effectiveBudgetLimitsProvider);
    final totals = data.categoryTotals;

    final entries = <_CategoryEntry>[];
    for (var i = 0; i < categoryNames.length; i++) {
      final name = categoryNames[i];
      final amount = totals[name] ?? 0.0;
      final budget = budgets[name] ?? 0.0;
      final progress = budget > 0
          ? (amount / budget).clamp(0.0, 1.0).toDouble()
          : -1.0;
      entries.add(
        _CategoryEntry(
          name: name,
          amount: amount,
          budget: budget,
          progress: progress,
          originalIndex: i,
        ),
      );
    }
    int tier(_CategoryEntry e) {
      if (e.progress > 0.9) return 0;
      if (e.progress >= 0.7 && e.progress <= 0.9) return 1;
      return 2;
    }

    entries.sort((a, b) {
      final ta = tier(a);
      final tb = tier(b);
      if (ta != tb) return ta - tb;
      return a.originalIndex - b.originalIndex;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Category অনুযায়ী',
          action: TextButton(
            onPressed: () => onTapCategory(null),
            child: const Text('সব দেখুন →'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 188,
                  child: _CategoryCard(
                    entry: entry,
                    onTap: () {
                      if (entry.budget <= 0) {
                        Navigator.of(context).push(
                          AppSlideRoute(
                            builder: (_) => const BudgetPlannerScreen(),
                          ),
                        );
                      } else {
                        onTapCategory(entry.name);
                      }
                    },
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _CategoryEntry {
  const _CategoryEntry({
    required this.name,
    required this.amount,
    required this.budget,
    required this.progress,
    required this.originalIndex,
  });

  final String name;
  final double amount;
  final double budget;
  final double progress;
  final int originalIndex;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.entry, required this.onTap});

  final _CategoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = resolveExpenseCategory(entry.name);
    final hasBudget = entry.budget > 0;
    final progressColor = _progressColor(entry.progress);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: meta.color.withValues(alpha: 0.12),
            child: Icon(meta.icon, color: meta.color),
          ),
          const SizedBox(height: 12),
          Text(entry.name, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          AppAmountText(amount: entry.amount),
          const SizedBox(height: 12),
          if (hasBudget) ...[
            AppProgressBar(
              value: entry.progress,
              color: progressColor,
              backgroundColor: context.borderColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              '${BanglaFormatters.currency(entry.amount)} / ${BanglaFormatters.currency(entry.budget)}',
              style: AppTextStyles.caption,
            ),
          ] else
            _DottedBudgetPlaceholder(),
        ],
      ),
    );
  }

  Color _progressColor(double progress) {
    if (progress > 0.9) {
      return AppColors.error;
    }
    if (progress >= 0.7) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _DottedBudgetPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(color: context.borderColor),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Text(
            'বাজেট সেট করুন',
            style: AppTextStyles.caption.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const radius = 8.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final dashed = _dashedPath(path, dashLength: 4, gapLength: 3);
    canvas.drawPath(dashed, paint);
  }

  Path _dashedPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final to = distance + dashLength;
        dest.addPath(
          metric.extractPath(distance, to.clamp(0, metric.length).toDouble()),
          Offset.zero,
        );
        distance = to + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

