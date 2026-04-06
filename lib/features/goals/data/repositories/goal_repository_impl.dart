// Feature: Goals
// Layer: Data

import '../../../../core/database/models/goal_model.dart';
import '../../../../core/database/models/goal_saving_model.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_saving.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_local_datasource.dart';

class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl({required GoalLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final GoalLocalDataSource _localDataSource;

  @override
  Future<List<GoalEntity>> getAllGoals() async {
    final models = await _localDataSource.getAllGoals();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<GoalEntity?> getGoalById(int id) async {
    final model = await _localDataSource.getGoalById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveGoal(GoalEntity goal) {
    return _localDataSource.saveGoal(GoalModel.fromEntity(goal));
  }

  @override
  Future<void> updateGoal(GoalEntity goal) {
    return _localDataSource.saveGoal(GoalModel.fromEntity(goal));
  }

  @override
  Future<void> deleteGoal(int id) {
    return _localDataSource.deleteGoal(id);
  }

  @override
  Future<void> addSaving(GoalSaving saving) {
    return _localDataSource.saveSaving(GoalSavingModel.fromEntity(saving));
  }

  @override
  Future<List<GoalSaving>> getSavingsForGoal(int goalId) async {
    final models = await _localDataSource.getSavingsForGoal(goalId);
    return models.map((model) => model.toEntity()).toList(growable: false);
  }

  @override
  Future<void> markAchieved(int id) async {
    final goal = await _localDataSource.getGoalById(id);
    if (goal == null) {
      return;
    }
    final updated = goal.toEntity().copyWith(status: GoalStatus.achieved);
    await _localDataSource.saveGoal(GoalModel.fromEntity(updated));
  }

  @override
  Future<void> cancelGoal(int id) async {
    final goal = await _localDataSource.getGoalById(id);
    if (goal == null) {
      return;
    }
    final updated = goal.toEntity().copyWith(status: GoalStatus.cancelled);
    await _localDataSource.saveGoal(GoalModel.fromEntity(updated));
  }
}
