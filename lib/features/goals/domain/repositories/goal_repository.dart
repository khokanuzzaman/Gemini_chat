// Feature: Goals
// Layer: Domain

import '../entities/goal_entity.dart';
import '../entities/goal_saving.dart';

abstract class GoalRepository {
  Future<List<GoalEntity>> getAllGoals();

  Future<GoalEntity?> getGoalById(int id);

  Future<void> saveGoal(GoalEntity goal);

  Future<void> updateGoal(GoalEntity goal);

  // Goal deletion is owned by the wallet ledger (single authority: it refunds
  // each source wallet and removes the goal + savings atomically), not by this
  // repository. See GoalNotifier.deleteGoal.

  Future<void> addSaving(GoalSaving saving);

  Future<List<GoalSaving>> getSavingsForGoal(int goalId);

  Future<void> markAchieved(int id);

  Future<void> cancelGoal(int id);
}
