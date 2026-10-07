import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_page_route.dart';
import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../anomaly/presentation/providers/anomaly_provider.dart';
import '../../../../budget/domain/entities/budget_plan_entity.dart';
import '../../../../budget/presentation/providers/budget_provider.dart';
import '../../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../../obligations/domain/upcoming_obligation.dart';
import '../../../../obligations/presentation/screens/upcoming_obligations_screen.dart';
import '../../../../obligations/presentation/providers/upcoming_obligations_provider.dart';
import '../../../../prediction/presentation/providers/prediction_provider.dart';
import '../../../../recurring/presentation/screens/recurring_screen.dart';
import '../../providers/expense_providers.dart';

/// "ইনসাইট": one calm card, one row per thing worth knowing, only the rows that
/// have something to say — budget · upcoming obligations · month-end prediction ·
/// unusual spending. Renders nothing when there is nothing to show.
class HomeInsightsCard extends ConsumerWidget {
  const HomeInsightsCard({super.key, this.maxUpcoming = 2});

  /// How many upcoming obligations the row lists (the next 1–2).
  final int maxUpcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent =
        ref.watch(dashboardControllerProvider).valueOrNull?.thisMonthTotal ?? 0;
    final budget = ref.watch(budgetProvider).activeBudget;
    final upcoming = ref.watch(upcomingObligationsProvider);
    final prediction = ref.watch(predictionProvider).prediction;
    final alerts = ref.watch(anomalyProvider).activeAlerts;

    final rows = <Widget>[
      if (budget != null) BudgetInsightRow(plan: budget, spent: spent),
      if (!upcoming.isEmpty)
        UpcomingInsightRow(items: upcoming.items.take(maxUpcoming).toList()),
      if (prediction != null)
        InsightRow(
          icon: Icons.trending_up_rounded,
          title: 'মাস শেষে আনুমানিক খরচ',
          subtitle: BanglaFormatters.currency(prediction.predictedTotal),
          subtitleStrong: true,
          onTap: AppShellNavigation.openAnalytics,
        ),
      if (alerts.isNotEmpty)
        AnomalyInsightRow(
          count: alerts.length,
          highCount: ref.watch(anomalyProvider).highSeverityCount,
        ),
    ];
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sectionGap),
        const AppSectionHeader(title: 'ইনসাইট'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.tokens.line,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable insight row: icon chip · title (+ subtitle) · value · chevron.
class InsightRow extends StatelessWidget {
  const InsightRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleStrong = false,
    this.trailing,
    this.bottom,
    this.onTap,
    this.chip = InsightChip.primary,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Emphasise the subtitle as the row's value (ink, bold) instead of a caption.
  final bool subtitleStrong;
  final String? trailing;
  final Widget? bottom;
  final VoidCallback? onTap;
  final InsightChip chip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InsightIconChip(icon: icon, chip: chip),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: tokens.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: subtitleStrong
                          ? AppTextStyles.bodyMedium.copyWith(
                              color: tokens.ink,
                              fontWeight: FontWeight.w700,
                            )
                          : AppTextStyles.bodySmall.copyWith(
                              color: tokens.muted,
                            ),
                    ),
                  if (bottom != null) ...[const SizedBox(height: 8), bottom!],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: AppTextStyles.titleMedium.copyWith(color: tokens.ink),
              ),
            ],
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Icon(Icons.chevron_right_rounded, color: tokens.muted),
              ),
          ],
        ),
      ),
    );
  }
}

enum InsightChip { primary, brass, danger }

class InsightIconChip extends StatelessWidget {
  const InsightIconChip({super.key, required this.icon, required this.chip});

  final IconData icon;
  final InsightChip chip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Brass is only ever a soft background with the dark on-brass glyph (an
    // icon in brass itself fails contrast on light surfaces).
    final (background, foreground) = switch (chip) {
      InsightChip.primary => (tokens.primarySoft, tokens.primary),
      InsightChip.brass => (tokens.brassSoft, context.brassGlyph),
      InsightChip.danger => (tokens.dangerSoft, tokens.dangerText),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: foreground),
    );
  }
}

class BudgetInsightRow extends StatelessWidget {
  const BudgetInsightRow({super.key, required this.plan, required this.spent});

  final BudgetPlanEntity plan;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final total = plan.totalBudgeted <= 0 ? 1.0 : plan.totalBudgeted;
    final ratio = spent / total;
    final fill = ratio >= 1
        ? tokens.dangerFill
        : ratio >= 0.8
        ? tokens.warning
        : tokens.primary;
    return InsightRow(
      icon: Icons.pie_chart_outline_rounded,
      title: 'মাসিক বাজেট',
      subtitle:
          '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(plan.totalBudgeted)}',
      bottom: AppProgressBar(
        value: ratio.clamp(0.0, 1.0),
        color: fill,
        backgroundColor: tokens.line,
        height: 6,
      ),
      onTap: () => Navigator.of(
        context,
      ).push(buildAppRoute(const BudgetPlannerScreen())),
    );
  }
}

class AnomalyInsightRow extends StatelessWidget {
  const AnomalyInsightRow({
    super.key,
    required this.count,
    required this.highCount,
  });

  final int count;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    return InsightRow(
      icon: Icons.warning_amber_rounded,
      chip: InsightChip.danger,
      title: '${BanglaFormatters.count(count)}টি অস্বাভাবিক খরচ',
      subtitle: highCount > 0
          ? '${BanglaFormatters.count(highCount)}টি গুরুত্বপূর্ণ — দেখে নিন'
          : 'একবার দেখে নিন',
      onTap: () => AppShellNavigation.openAnalytics(tab: AnalyticsTab.anomaly),
    );
  }
}

/// The next 1–2 obligations (G4). Each line deep-links to its source: a debt to
/// the debt, a recurring entry to the recurring list.
class UpcomingInsightRow extends StatelessWidget {
  const UpcomingInsightRow({super.key, required this.items});

  final List<UpcomingObligation> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasDebt = items.any((item) => item.kind == ObligationKind.debt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InsightIconChip(
            icon: Icons.event_rounded,
            chip: hasDebt ? InsightChip.brass : InsightChip.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'আসছে',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: tokens.ink,
                        ),
                      ),
                    ),
                    // The full list (PLAN strip opens the same screen).
                    InkWell(
                      key: const Key('home-upcoming-see-all'),
                      onTap: () => Navigator.of(
                        context,
                      ).push(buildAppRoute(const UpcomingObligationsScreen())),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'সব দেখুন',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: tokens.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: tokens.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                for (final item in items) _ObligationLine(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationLine extends StatelessWidget {
  const _ObligationLine({required this.item});

  final UpcomingObligation item;

  void _open(BuildContext context) {
    if (item.kind == ObligationKind.debt) {
      AppShellNavigation.openDebtDetail(item.sourceId);
    } else {
      Navigator.of(context).push(buildAppRoute(const RecurringScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final when = item.isOverdue
        ? 'মেয়াদ পেরিয়েছে'
        : BanglaFormatters.dayMonthLong(item.dueDate);
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: when,
                      style: TextStyle(
                        color: item.isOverdue
                            ? tokens.dangerText
                            : tokens.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' · ${item.title}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(color: tokens.ink),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              BanglaFormatters.currency(item.amount),
              style: AppTextStyles.bodySmall.copyWith(
                color: tokens.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
