// Feature: Goals
// Layer: Domain

import '../entities/goal_entity.dart';
import '../repositories/goal_repository.dart';

class GetAllGoalsUseCase {
  const GetAllGoalsUseCase(this._repository);

  final GoalRepository _repository;

  Future<List<GoalEntity>> call() => _repository.getAllGoals();
}
