import 'package:isar_community/isar.dart';

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

  /// Source wallet this deposit debited. Legacy rows deserialize to null (never
  /// wallet-debited, never refunded on goal deletion).
  int? walletId;

  GoalSaving toEntity() {
    return GoalSaving(
      id: id,
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
      walletId: walletId,
    );
  }

  static GoalSavingModel fromEntity(GoalSaving entity) {
    final model = GoalSavingModel()
      ..goalId = entity.goalId
      ..amount = entity.amount
      ..date = entity.date
      ..note = entity.note
      ..walletId = entity.walletId;
    if (entity.id > 0) {
      model.id = entity.id;
    }
    return model;
  }
}
