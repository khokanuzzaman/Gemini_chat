import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../../../budget/presentation/providers/budget_provider.dart';
import '../../../../../debt/presentation/providers/debt_providers.dart';
import '../../../../../goals/presentation/providers/goal_provider.dart';
import '../../../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../../../wallet/presentation/providers/wallet_provider.dart';
import 'anomaly_insight_page.dart';
import 'budget_insight_page.dart';
import 'debt_insight_page.dart';
import 'goals_insight_page.dart';
import 'prediction_insight_page.dart';
import 'wallets_insight_page.dart';

class InsightsStrip extends ConsumerStatefulWidget {
  const InsightsStrip({super.key});

  @override
  ConsumerState<InsightsStrip> createState() => _InsightsStripState();
}

class _InsightsStripState extends ConsumerState<InsightsStrip> {
  static const _insightHeight = 224.0;
  late final PageController _controller =
      PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[];

    final wallets = ref.watch(walletProvider).valueOrNull ?? const [];
    if (wallets.where((w) => !w.isArchived).isNotEmpty) {
      pages.add(const WalletsInsightPage());
    }

    final debtSummary = ref.watch(debtSummaryProvider);
    if (debtSummary.hasActiveDebts) {
      pages.add(const DebtInsightPage());
    }

    final prediction = ref.watch(predictionProvider).prediction;
    if (prediction != null) {
      pages.add(PredictionInsightPage(prediction: prediction));
    }

    final budgetPlan = ref.watch(budgetProvider).activeBudget;
    if (budgetPlan != null) {
      pages.add(BudgetInsightPage(plan: budgetPlan));
    }

    final activeGoals = ref.watch(goalProvider).activeGoals;
    if (activeGoals.isNotEmpty) {
      pages.add(
        GoalsInsightPage(goals: activeGoals.take(2).toList(growable: false)),
      );
    }

    final anomalyState = ref.watch(anomalyProvider);
    if (anomalyState.activeAlerts.isNotEmpty) {
      pages.add(
        AnomalyInsightPage(
          count: anomalyState.activeAlerts.length,
          highCount: anomalyState.highSeverityCount,
        ),
      );
    }

    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: _insightHeight,
          child: PageView(
            controller: _controller,
            padEnds: false,
            children: pages
                .map(
                  (page) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: page,
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PageDots(count: pages.length, controller: _controller),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.controller});

  final int count;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        var current = 0;
        if (controller.hasClients && controller.page != null) {
          current = controller.page!.round();
        } else if (controller.hasClients) {
          current = controller.initialPage;
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final active = index == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? context.appColors.primary
                    : context.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}
