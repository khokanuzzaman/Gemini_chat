// Feature: Goals
// Layer: Presentation

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../data/datasources/goal_local_datasource.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_saving.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/usecases/add_saving_usecase.dart';
import '../../domain/usecases/cancel_goal_usecase.dart';
import '../../domain/usecases/delete_goal_usecase.dart';
import '../../domain/usecases/get_all_goals_usecase.dart';
import '../../domain/usecases/get_goal_savings_usecase.dart';
import '../../domain/usecases/mark_achieved_usecase.dart';
import '../../domain/usecases/save_goal_usecase.dart';
import '../../domain/usecases/update_goal_usecase.dart';

final goalLocalDataSourceProvider = Provider<GoalLocalDataSource>((ref) {
  return GoalLocalDataSource(ref.watch(isarProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(
    localDataSource: ref.watch(goalLocalDataSourceProvider),
  );
});

final getAllGoalsUseCaseProvider = Provider<GetAllGoalsUseCase>((ref) {
  return GetAllGoalsUseCase(ref.watch(goalRepositoryProvider));
});

final saveGoalUseCaseProvider = Provider<SaveGoalUseCase>((ref) {
  return SaveGoalUseCase(ref.watch(goalRepositoryProvider));
});

final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>((ref) {
  return UpdateGoalUseCase(ref.watch(goalRepositoryProvider));
});

final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>((ref) {
  return DeleteGoalUseCase(ref.watch(goalRepositoryProvider));
});

final addSavingUseCaseProvider = Provider<AddSavingUseCase>((ref) {
  return AddSavingUseCase(ref.watch(goalRepositoryProvider));
});

final getGoalSavingsUseCaseProvider = Provider<GetGoalSavingsUseCase>((ref) {
  return GetGoalSavingsUseCase(ref.watch(goalRepositoryProvider));
});

final markAchievedUseCaseProvider = Provider<MarkAchievedUseCase>((ref) {
  return MarkAchievedUseCase(ref.watch(goalRepositoryProvider));
});

final cancelGoalUseCaseProvider = Provider<CancelGoalUseCase>((ref) {
  return CancelGoalUseCase(ref.watch(goalRepositoryProvider));
});

class GoalState {
  const GoalState({required this.goals, required this.isLoading});

  final List<GoalEntity> goals;
  final bool isLoading;

  GoalState copyWith({List<GoalEntity>? goals, bool? isLoading}) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  List<GoalEntity> get activeGoals => goals
      .where((goal) => goal.status == GoalStatus.active)
      .toList(growable: false);

  List<GoalEntity> get achievedGoals => goals
      .where((goal) => goal.status == GoalStatus.achieved)
      .toList(growable: false);

  List<GoalEntity> get cancelledGoals => goals
      .where((goal) => goal.status == GoalStatus.cancelled)
      .toList(growable: false);
}

final goalProvider = NotifierProvider<GoalNotifier, GoalState>(
  GoalNotifier.new,
);

final goalsProvider = goalProvider;

final goalSavingsProvider = FutureProvider.family<List<GoalSaving>, int>((
  ref,
  goalId,
) async {
  return ref.read(goalProvider.notifier).getSavingsForGoal(goalId);
});

class GoalNotifier extends Notifier<GoalState> {
  bool _loadScheduled = false;

  @override
  GoalState build() {
    if (!_loadScheduled) {
      _loadScheduled = true;
      Future<void>.microtask(_load);
    }
    return const GoalState(goals: [], isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final goals = await ref.read(getAllGoalsUseCaseProvider).call();

    var hasStatusChange = false;
    for (final goal in goals) {
      if (goal.isAchieved && goal.status == GoalStatus.active) {
        await ref.read(markAchievedUseCaseProvider).call(goal.id);
        await NotificationService.cancelGoalReminder(_goalReminderId(goal));
        hasStatusChange = true;
      }
    }

    final refreshedGoals = hasStatusChange
        ? await ref.read(getAllGoalsUseCaseProvider).call()
        : goals;
    state = GoalState(goals: refreshedGoals, isLoading: false);
  }

  Future<void> addGoal(GoalEntity goal) async {
    final normalizedGoal = goal.copyWith(
      status: goal.isAchieved ? GoalStatus.achieved : GoalStatus.active,
    );
    await ref.read(saveGoalUseCaseProvider).call(normalizedGoal);
    if (normalizedGoal.status == GoalStatus.active) {
      await NotificationService.scheduleGoalReminder(
        notificationId: _goalReminderId(normalizedGoal),
        goalTitle: normalizedGoal.title,
        monthlyNeeded: normalizedGoal.requiredMonthlySaving,
      );
    }
    await _load();
  }

  Future<void> updateGoal(GoalEntity goal) async {
    final normalizedGoal = goal.copyWith(
      status: goal.isAchieved ? GoalStatus.achieved : goal.status,
    );
    await ref.read(updateGoalUseCaseProvider).call(normalizedGoal);
    if (normalizedGoal.status == GoalStatus.active) {
      await NotificationService.scheduleGoalReminder(
        notificationId: _goalReminderId(normalizedGoal),
        goalTitle: normalizedGoal.title,
        monthlyNeeded: normalizedGoal.requiredMonthlySaving,
      );
    } else {
      await NotificationService.cancelGoalReminder(
        _goalReminderId(normalizedGoal),
      );
    }
    await _load();
  }

  Future<void> deleteGoal(int id) async {
    final goal = state.goals.where((item) => item.id == id).firstOrNull;
    if (goal != null) {
      await NotificationService.cancelGoalReminder(_goalReminderId(goal));
    }
    await ref.read(deleteGoalUseCaseProvider).call(id);
    ref.invalidate(goalSavingsProvider(id));
    await _load();
  }

  Future<void> addSaving({
    required int goalId,
    required double amount,
    String? note,
  }) async {
    final goal = state.goals.where((item) => item.id == goalId).firstOrNull;
    if (goal == null) {
      return;
    }

    final saving = GoalSaving(
      id: DateTime.now().microsecondsSinceEpoch,
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );
    await ref.read(addSavingUseCaseProvider).call(saving);

    final updated = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
      status: goal.savedAmount + amount >= goal.targetAmount
          ? GoalStatus.achieved
          : goal.status,
    );
    await ref.read(updateGoalUseCaseProvider).call(updated);
    if (updated.status == GoalStatus.achieved) {
      await NotificationService.cancelGoalReminder(_goalReminderId(updated));
    }
    ref.invalidate(goalSavingsProvider(goalId));
    await _load();
  }

  Future<void> cancelGoal(int id) async {
    final goal = state.goals.where((item) => item.id == id).firstOrNull;
    if (goal != null) {
      await NotificationService.cancelGoalReminder(_goalReminderId(goal));
    }
    await ref.read(cancelGoalUseCaseProvider).call(id);
    await _load();
  }

  Future<void> markAchieved(int id) async {
    final goal = state.goals.where((item) => item.id == id).firstOrNull;
    if (goal != null) {
      await NotificationService.cancelGoalReminder(_goalReminderId(goal));
    }
    await ref.read(markAchievedUseCaseProvider).call(id);
    await _load();
  }

  Future<List<GoalSaving>> getSavingsForGoal(int goalId) {
    return ref.read(getGoalSavingsUseCaseProvider).call(goalId);
  }

  List<GoalEntity> get activeGoals => state.activeGoals;

  List<GoalEntity> get achievedGoals => state.achievedGoals;

  List<GoalEntity> get cancelledGoals => state.cancelledGoals;

  int _goalReminderId(GoalEntity goal) {
    final stableValue = goal.createdAt.microsecondsSinceEpoch.abs() % 1000000;
    return 5000 + stableValue;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
