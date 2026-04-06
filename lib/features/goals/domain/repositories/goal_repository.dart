// Feature: Goals
// Layer: Domain

import '../entities/goal_entity.dart';
import '../entities/goal_saving.dart';

abstract class GoalRepository {
  Future<List<GoalEntity>> getAllGoals();

  Future<GoalEntity?> getGoalById(int id);

  Future<void> saveGoal(GoalEntity goal);

  Future<void> updateGoal(GoalEntity goal);

  Future<void> deleteGoal(int id);

  Future<void> addSaving(GoalSaving saving);

  Future<List<GoalSaving>> getSavingsForGoal(int goalId);

  Future<void> markAchieved(int id);

  Future<void> cancelGoal(int id);
}
