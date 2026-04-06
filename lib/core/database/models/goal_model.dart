import 'package:isar/isar.dart';

import '../../../features/goals/domain/entities/goal_entity.dart';

part 'goal_model.g.dart';

@collection
class GoalModel {
  Id id = Isar.autoIncrement;

  late String title;
  late String emoji;
  late double targetAmount;
  late double savedAmount;
  @Index()
  late DateTime targetDate;
  late DateTime createdAt;
  @enumerated
  late GoalStatus status;
  String? notes;

  GoalEntity toEntity() {
    return GoalEntity(
      id: id,
      title: title,
      emoji: emoji,
      targetAmount: targetAmount,
      savedAmount: savedAmount,
      targetDate: targetDate,
      createdAt: createdAt,
      status: status,
      notes: notes,
    );
  }

  static GoalModel fromEntity(GoalEntity entity) {
    final model = GoalModel()
      ..title = entity.title
      ..emoji = entity.emoji
      ..targetAmount = entity.targetAmount
      ..savedAmount = entity.savedAmount
      ..targetDate = entity.targetDate
      ..createdAt = entity.createdAt
      ..status = entity.status
      ..notes = entity.notes;
    if (entity.id > 0) {
      model.id = entity.id;
    }
    return model;
  }
}
