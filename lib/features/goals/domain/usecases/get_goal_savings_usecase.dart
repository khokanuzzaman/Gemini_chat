// Feature: Goals
// Layer: Domain

import '../entities/goal_saving.dart';
import '../repositories/goal_repository.dart';

class GetGoalSavingsUseCase {
  const GetGoalSavingsUseCase(this._repository);

  final GoalRepository _repository;

  Future<List<GoalSaving>> call(int goalId) =>
      _repository.getSavingsForGoal(goalId);
}
