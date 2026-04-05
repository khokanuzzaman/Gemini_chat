import 'package:isar/isar.dart';

import '../../../../core/database/models/goal_model.dart';

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
}
