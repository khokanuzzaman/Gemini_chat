import 'package:isar/isar.dart';

import '../../../../core/database/models/goal_model.dart';
import '../../../../core/database/models/goal_saving_model.dart';

class GoalLocalDataSource {
  const GoalLocalDataSource(this._isar);

  final Isar _isar;

  Future<List<GoalModel>> getAllGoals() async {
    final goals = await _isar.goalModels.where().findAll();
    goals.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return goals;
  }

  Future<void> saveGoal(GoalModel model) async {
    await _isar.writeTxn(() async {
      await _isar.goalModels.put(model);
    });
  }

  Future<void> saveGoals(List<GoalModel> models) async {
    await _isar.writeTxn(() async {
      await _isar.goalModels.putAll(models);
    });
  }

  Future<GoalModel?> getGoalById(int id) {
    return _isar.goalModels.get(id);
  }

  Future<void> deleteGoal(int id) async {
    await _isar.writeTxn(() async {
      await _isar.goalModels.delete(id);
      await _isar.goalSavingModels.filter().goalIdEqualTo(id).deleteAll();
    });
  }

  Future<void> saveSaving(GoalSavingModel model) async {
    await _isar.writeTxn(() async {
      await _isar.goalSavingModels.put(model);
    });
  }

  Future<List<GoalSavingModel>> getSavingsForGoal(int goalId) async {
    final savings = await _isar.goalSavingModels
        .filter()
        .goalIdEqualTo(goalId)
        .findAll();
    savings.sort((first, second) => second.date.compareTo(first.date));
    return savings;
  }
}
