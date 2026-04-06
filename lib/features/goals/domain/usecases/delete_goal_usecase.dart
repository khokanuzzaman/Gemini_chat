// Feature: Goals
// Layer: Domain

import '../repositories/goal_repository.dart';

class DeleteGoalUseCase {
  const DeleteGoalUseCase(this._repository);

  final GoalRepository _repository;

  Future<void> call(int id) => _repository.deleteGoal(id);
}
