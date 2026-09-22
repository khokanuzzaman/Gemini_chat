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
import '../../../recurring/presentation/screens/recurring_screen.dart';

/// প্ল্যান tab — a hub for the planning surfaces (Budget · Goals · Debt ·
/// Recurring). Each entry pushes an existing screen; no feature logic lives here.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPageScaffold(
      title: 'প্ল্যান',
      showBackButton: false,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              AppListTile(
                leadingIcon: Icons.pie_chart_rounded,
                leadingColor: context.appColors.primary,
                title: 'বাজেট',
                subtitle: 'মাসিক বাজেট পরিকল্পনা ও ট্র্যাক',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref
                      .read(usageAnalyticsProvider)
                      .featureOpen(AnalyticsFeature.budget);
                  Navigator.of(context).push(
                    AppSlideRoute(builder: (_) => const BudgetPlannerScreen()),
                  );
                },
              ),
              AppListTile(
                leadingIcon: Icons.flag_rounded,
                leadingColor: AppColors.warning,
                title: 'লক্ষ্য',
                subtitle: 'সঞ্চয়ের লক্ষ্য নির্ধারণ ও অগ্রগতি',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref
                      .read(usageAnalyticsProvider)
                      .featureOpen(AnalyticsFeature.goals);
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const GoalsScreen()));
                },
              ),
              AppListTile(
                leadingIcon: Icons.handshake_rounded,
                leadingColor: context.appColors.primary,
                title: 'দেনা-পাওনা',
                subtitle: 'ঋণ ও কিস্তি ব্যবস্থাপনা',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref
                      .read(usageAnalyticsProvider)
                      .featureOpen(AnalyticsFeature.debt);
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const DebtListScreen()));
                },
              ),
              AppListTile(
                leadingIcon: Icons.repeat_rounded,
                leadingColor: AppColors.success,
                title: 'নিয়মিত খরচ',
                subtitle: 'পুনরাবৃত্ত খরচ চিহ্নিত করুন',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref
                      .read(usageAnalyticsProvider)
                      .featureOpen(AnalyticsFeature.recurring);
                  Navigator.of(
                    context,
                  ).push(buildAppRoute(const RecurringScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
