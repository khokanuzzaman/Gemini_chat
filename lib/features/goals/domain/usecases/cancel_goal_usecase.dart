// Feature: Goals
// Layer: Domain

import '../repositories/goal_repository.dart';

class CancelGoalUseCase {
  const CancelGoalUseCase(this._repository);

  final GoalRepository _repository;

  Future<void> call(int id) => _repository.cancelGoal(id);
}
