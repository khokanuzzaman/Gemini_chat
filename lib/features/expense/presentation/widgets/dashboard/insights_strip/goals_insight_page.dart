import 'package:flutter/material.dart';

import '../../../../../../core/navigation/app_page_route.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../goals/domain/entities/goal_entity.dart';
import '../../../../../goals/presentation/screens/goals_screen.dart';

class GoalsInsightPage extends StatelessWidget {
  const GoalsInsightPage({super.key, required this.goals});

  final List<GoalEntity> goals;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {
        Navigator.of(context).push(buildAppRoute(const GoalsScreen()));
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        children: goals
            .map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(goal.emoji),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Text(
                          '${goal.progressPercentage.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppProgressBar(
                      value: goal.progressPercentage / 100,
                      backgroundColor: context.borderColor.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
