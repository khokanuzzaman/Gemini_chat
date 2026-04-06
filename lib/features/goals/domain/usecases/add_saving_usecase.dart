// Feature: Goals
// Layer: Domain

import '../entities/goal_saving.dart';
import '../repositories/goal_repository.dart';

class AddSavingUseCase {
  const AddSavingUseCase(this._repository);

  final GoalRepository _repository;

  Future<void> call(GoalSaving saving) => _repository.addSaving(saving);
}
