import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/models/goal_model.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/datasources/goal_local_datasource.dart';
import '../../domain/entities/goal_entity.dart';

final goalLocalDataSourceProvider = Provider<GoalLocalDataSource>((ref) {
  return GoalLocalDataSource(ref.watch(isarProvider));
});

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<GoalEntity>>(
  GoalsNotifier.new,
);

class GoalsNotifier extends AsyncNotifier<List<GoalEntity>> {
  @override
  Future<List<GoalEntity>> build() async {
    return _loadGoals();
  }

  Future<void> addGoal(GoalEntity goal) async {
    await ref
        .read(goalLocalDataSourceProvider)
        .saveGoal(GoalModel.fromEntity(goal));
    state = AsyncData(await _loadGoals());
  }

  Future<void> updateGoal(GoalEntity goal) async {
    await ref
        .read(goalLocalDataSourceProvider)
        .saveGoal(GoalModel.fromEntity(goal));
    state = AsyncData(await _loadGoals());
  }

  Future<void> addSaving(int goalId, double amount) async {
    final goals = await _loadGoals();
    final goal = goals.where((item) => item.id == goalId).firstOrNull;
    if (goal == null) {
      return;
    }
    final updated = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
      status: goal.savedAmount + amount >= goal.targetAmount
          ? GoalStatus.achieved
          : goal.status,
    );
    await updateGoal(updated);
  }

  Future<List<GoalEntity>> _loadGoals() async {
    final models = await ref.read(goalLocalDataSourceProvider).getAllGoals();
    return models.map((model) => model.toEntity()).toList(growable: false);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
