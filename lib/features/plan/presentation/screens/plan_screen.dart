import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_providers.dart';
import '../../../../core/analytics/usage_analytics.dart';
import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../debt/presentation/screens/debt_list_screen.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../obligations/presentation/screens/upcoming_obligations_screen.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../domain/plan_status.dart';
import '../providers/plan_status_provider.dart';

/// প্ল্যান tab (DESIGN_SPEC §3.4): four cards — বাজেট · লক্ষ্য · দেনা-পাওনা ·
/// নিয়মিত খরচ — each with a one-line LIVE status from the providers that already
/// exist, and (only when something is due) a strip that opens the full
/// "আসন্ন পরিশোধ" list. Each card pushes an existing screen; no feature logic
/// lives here.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(planHubStatusProvider);

    void open(AnalyticsFeature feature, Widget screen, {bool slide = false}) {
      ref.read(usageAnalyticsProvider).featureOpen(feature);
      Navigator.of(context).push(
        slide ? AppSlideRoute(builder: (_) => screen) : buildAppRoute(screen),
      );
    }

    return AppPageScaffold(
      title: 'প্ল্যান',
      showBackButton: false,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status.upcoming != null) ...[
              _UpcomingStrip(
                status: status.upcoming!,
                onTap: () => Navigator.of(
                  context,
                ).push(buildAppRoute(const UpcomingObligationsScreen())),
              ),
              const SizedBox(height: AppSpacing.cardGap),
            ],
            _PlanCard(
              icon: Icons.pie_chart_rounded,
              title: 'বাজেট',
              status: status.budget,
              onTap: () => open(
                AnalyticsFeature.budget,
                const BudgetPlannerScreen(),
                slide: true,
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _PlanCard(
              icon: Icons.flag_rounded,
              title: 'লক্ষ্য',
              status: status.goals,
              onTap: () => open(AnalyticsFeature.goals, const GoalsScreen()),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _PlanCard(
              icon: Icons.handshake_rounded,
              title: 'দেনা-পাওনা',
              // Debt and EMI are the brass marker everywhere else in the app.
              accent: HubAccent.brass,
              status: status.debt,
              onTap: () => open(AnalyticsFeature.debt, const DebtListScreen()),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            _PlanCard(
              icon: Icons.repeat_rounded,
              title: 'নিয়মিত খরচ',
              status: status.recurring,
              onTap: () =>
                  open(AnalyticsFeature.recurring, const RecurringScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
    this.accent = HubAccent.primary,
  });

  final IconData icon;
  final String title;
  final HubStatus? status;
  final HubAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: HubTile(
        icon: icon,
        title: title,
        accent: accent,
        status: status?.text,
        statusIsAttention: status?.tone == StatusTone.attention,
        onTap: onTap,
      ),
    );
  }
}

/// "আগামী ৩০ দিনে ৩টি পরিশোধ · ৳X" — a slim, tappable summary above the cards.
class _UpcomingStrip extends StatelessWidget {
  const _UpcomingStrip({required this.status, required this.onTap});

  final HubStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final attention = status.tone == StatusTone.attention;
    return Semantics(
      button: true,
      label: status.text,
      excludeSemantics: true,
      child: Material(
        color: attention ? tokens.dangerSoft : tokens.primarySoft,
        borderRadius: AppRadius.cardAll,
        child: InkWell(
          borderRadius: AppRadius.cardAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 20,
                  color: attention ? tokens.dangerText : tokens.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: attention ? tokens.dangerText : tokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: attention ? tokens.dangerText : tokens.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
