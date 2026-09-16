import 'package:isar_community/isar.dart';

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

  // Public methods own the transaction; the `*InTxn` internals are the SINGLE
  // write path, callable by a caller that already holds a writeTxn (the ledger).

  Future<void> saveGoal(GoalModel model) async {
    await _isar.writeTxn(() => saveGoalInTxn(_isar, model));
  }

  /// Transaction-free goal write; assumes it is already inside a [Isar.writeTxn].
  Future<int> saveGoalInTxn(Isar isar, GoalModel model) {
    return isar.goalModels.put(model);
  }

  Future<void> saveGoals(List<GoalModel> models) async {
    await _isar.writeTxn(() async {
      await _isar.goalModels.putAll(models);
    });
  }

  Future<GoalModel?> getGoalById(int id) {
    return _isar.goalModels.get(id);
  }

  /// Transaction-free goal delete; assumes it is already inside a
  /// [Isar.writeTxn]. Lets the ledger delete the goal row inside the same op
  /// that refunds — the single write path.
  Future<void> deleteGoalInTxn(Isar isar, int id) async {
    await isar.goalModels.delete(id);
  }

  /// Transaction-free saving delete; assumes it is already inside a
  /// [Isar.writeTxn]. The ledger deletes a wallet's saving rows in the SAME op
  /// that refunds that wallet (never a delete without its refund).
  Future<void> deleteSavingInTxn(Isar isar, int id) async {
    await isar.goalSavingModels.delete(id);
  }

  Future<void> saveSaving(GoalSavingModel model) async {
    await _isar.writeTxn(() => saveSavingInTxn(_isar, model));
  }

  /// Transaction-free saving write; assumes it is already inside a
  /// [Isar.writeTxn]. Returns the record id.
  Future<int> saveSavingInTxn(Isar isar, GoalSavingModel model) {
    return isar.goalSavingModels.put(model);
  }

  /// Sum of goal deposits in [start, end] (inclusive) — the cash-flow savings
  /// figure. Reads GoalSaving directly; goal deposits have no expense record.
  Future<double> getTotalSavingsForRange(DateTime start, DateTime end) async {
    final savings = await _isar.goalSavingModels.where().findAll();
    return savings
        .where(
          (saving) =>
              !saving.date.isBefore(start) && !saving.date.isAfter(end),
        )
        .fold<double>(0, (sum, saving) => sum + saving.amount);
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
