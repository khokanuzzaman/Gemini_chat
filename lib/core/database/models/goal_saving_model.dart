import 'package:isar/isar.dart';

import '../../../features/goals/domain/entities/goal_saving.dart';

part 'goal_saving_model.g.dart';

@collection
class GoalSavingModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int goalId;
  late double amount;
  @Index()
  late DateTime date;
  String? note;

  GoalSaving toEntity() {
    return GoalSaving(
      id: id,
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
    );
  }

  static GoalSavingModel fromEntity(GoalSaving entity) {
    final model = GoalSavingModel()
      ..goalId = entity.goalId
      ..amount = entity.amount
      ..date = entity.date
      ..note = entity.note;
    if (entity.id > 0) {
      model.id = entity.id;
    }
    return model;
  }
}
