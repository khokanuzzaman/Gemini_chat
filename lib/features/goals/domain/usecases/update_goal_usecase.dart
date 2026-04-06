// Feature: Goals
// Layer: Domain

import '../entities/goal_entity.dart';
import '../repositories/goal_repository.dart';

class UpdateGoalUseCase {
  const UpdateGoalUseCase(this._repository);

  final GoalRepository _repository;

  Future<void> call(GoalEntity goal) => _repository.updateGoal(goal);
}
