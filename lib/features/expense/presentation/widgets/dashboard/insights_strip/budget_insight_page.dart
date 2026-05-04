import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/navigation/app_page_route.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/bangla_formatters.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../budget/domain/entities/budget_plan_entity.dart';
import '../../../../../budget/presentation/screens/budget_planner_screen.dart';
import '../../../providers/expense_providers.dart' as expense_providers;

class BudgetInsightPage extends ConsumerWidget {
  const BudgetInsightPage({super.key, required this.plan});

  final BudgetPlanEntity plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(expense_providers.dashboardControllerProvider);
    final spent = dashboard.valueOrNull?.thisMonthTotal ?? 0.0;
    final totalBudget = plan.totalBudgeted <= 0 ? 1.0 : plan.totalBudgeted;
    final progress = (spent / totalBudget).clamp(0.0, 1.0);
    final progressColor = progress >= 1
        ? AppColors.error
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.success;

    return AppCard(
      onTap: () {
        Navigator.of(context).push(buildAppRoute(const BudgetPlannerScreen()));
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text('মাসিক বাজেট', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${BanglaFormatters.currency(spent)} / ${BanglaFormatters.currency(plan.totalBudgeted)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.titleMedium.copyWith(color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: progress,
            color: progressColor,
            backgroundColor: context.borderColor.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 6),
          Text(
            'সঞ্চয় লক্ষ্য: ${BanglaFormatters.currency(plan.savingsAmount)} (${plan.savingsPercentage.toStringAsFixed(0)}%)',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
