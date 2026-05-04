import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/add_saving_sheet.dart';
import '../widgets/goal_card.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);
    final tabs = const ['চলমান', 'সম্পন্ন', 'বাতিল'];

    return AppPageScaffold(
      title: 'লক্ষ্য',
      floatingActionButton: IgnorePointer(
        ignoring: _selectedIndex != 0,
        child: AnimatedScale(
          scale: _selectedIndex == 0 ? 1 : 0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: FloatingActionButton(
            onPressed: () => showAddEditGoalSheet(context),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              0,
            ),
            child: AppSegmentedTabs(
              tabs: tabs,
              selectedIndex: _selectedIndex,
              onChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: goalState.isLoading
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(AppSpacing.screenPadding),
                    child: AppLoadingState.list(),
                  )
                : AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: _GoalsTab(
                      key: ValueKey('goal-tab-$_selectedIndex'),
                      goals: switch (_selectedIndex) {
                        0 => goalState.activeGoals,
                        1 => goalState.achievedGoals,
                        _ => goalState.cancelledGoals,
                      },
                      emptyIcon: switch (_selectedIndex) {
                        0 => Icons.flag_rounded,
                        1 => Icons.emoji_events_outlined,
                        _ => Icons.archive_outlined,
                      },
                      emptyTitle: switch (_selectedIndex) {
                        0 => 'কোনো লক্ষ্য নেই',
                        1 => 'এখনো কোনো লক্ষ্য পূরণ হয়নি',
                        _ => 'কোনো বাতিল লক্ষ্য নেই',
                      },
                      emptySubtitle: switch (_selectedIndex) {
                        0 => 'একটি সঞ্চয় লক্ষ্য নির্ধারণ করুন',
                        1 => 'লক্ষ্য পূরণ হলে এখানে দেখাবে',
                        _ => 'বাতিল করা লক্ষ্যগুলো এখানে থাকবে',
                      },
                      actionLabel: _selectedIndex == 0
                          ? 'লক্ষ্য যোগ করুন'
                          : null,
                      onAction: _selectedIndex == 0
                          ? () => showAddEditGoalSheet(context)
                          : null,
                      itemBuilder: (goal) => GoalCard(
                        goal: goal,
                        achieved: _selectedIndex == 1,
                        cancelled: _selectedIndex == 2,
                        onTap: () => _openDetail(goal.id),
                        onAddSaving: _selectedIndex == 0
                            ? () => showAddSavingSheet(context, goal)
                            : null,
                        onEdit: _selectedIndex == 0
                            ? () => showAddEditGoalSheet(
                                context,
                                existingGoal: goal,
                              )
                            : null,
                        onCancel: _selectedIndex == 0
                            ? () => _confirmCancel(goal)
                            : null,
                        onDelete: () => _confirmDelete(goal),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(int goalId) {
    Navigator.of(
      context,
    ).push(AppSlideRoute(builder: (_) => GoalDetailScreen(goalId: goalId)));
  }

  Future<void> _confirmCancel(GoalEntity goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('লক্ষ্য বাতিল করবেন?'),
          content: Text(
            '"${goal.title}" বাতিল করলে এটি বাতিল তালিকায় চলে যাবে।',
          ),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'বাতিল করুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(goalProvider.notifier).cancelGoal(goal.id);
    }
  }

  Future<void> _confirmDelete(GoalEntity goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('লক্ষ্য মুছবেন?'),
          content: Text('"${goal.title}" এবং এর saving history মুছে যাবে।'),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(goalProvider.notifier).deleteGoal(goal.id);
    }
  }
}

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({
    super.key,
    required this.goals,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.itemBuilder,
    this.actionLabel,
    this.onAction,
  });

  final List<GoalEntity> goals;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(GoalEntity goal) itemBuilder;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        100,
      ),
      itemCount: goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => itemBuilder(goals[index]),
    );
  }
}
