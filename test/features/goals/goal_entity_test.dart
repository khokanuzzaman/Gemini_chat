import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/goals/domain/entities/goal_entity.dart';

void main() {
  group('GoalEntity', () {
    test('calculates progress, remaining amount, and monthly saving', () {
      final now = DateTime.now();
      final goal = GoalEntity(
        id: 1,
        title: 'Emergency Fund',
        emoji: '💰',
        targetAmount: 50000,
        savedAmount: 10000,
        targetDate: now.add(const Duration(days: 300)),
        createdAt: now.subtract(const Duration(days: 30)),
        status: GoalStatus.active,
      );

      expect(goal.progressPercentage, 20);
      expect(goal.remainingAmount, 40000);
      expect(goal.requiredMonthlySaving, greaterThan(3900));
      expect(goal.requiredMonthlySaving, lessThan(4100));
    });

    test('reports on-track and behind-track states', () {
      final now = DateTime.now();
      final createdAt = now.subtract(const Duration(days: 180));
      final targetDate = now.add(const Duration(days: 180));

      final onTrackGoal = GoalEntity(
        id: 1,
        title: 'Trip',
        emoji: '✈️',
        targetAmount: 12000,
        savedAmount: 7000,
        targetDate: targetDate,
        createdAt: createdAt,
        status: GoalStatus.active,
      );

      final behindGoal = GoalEntity(
        id: 2,
        title: 'Laptop',
        emoji: '💻',
        targetAmount: 12000,
        savedAmount: 3000,
        targetDate: targetDate,
        createdAt: createdAt,
        status: GoalStatus.active,
      );

      expect(onTrackGoal.isOnTrack, isTrue);
      expect(behindGoal.isOnTrack, isFalse);
    });
  });
}
