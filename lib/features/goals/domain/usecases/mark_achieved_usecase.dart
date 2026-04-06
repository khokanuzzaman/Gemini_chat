// Feature: Goals
// Layer: Domain

import '../repositories/goal_repository.dart';

class MarkAchievedUseCase {
  const MarkAchievedUseCase(this._repository);

  final GoalRepository _repository;

  Future<void> call(int id) => _repository.markAchieved(id);
}
