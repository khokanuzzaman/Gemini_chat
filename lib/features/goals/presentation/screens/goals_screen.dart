// Feature: Goals
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
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

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('আমার লক্ষ্য'),
        actions: [
          IconButton(
            onPressed: () => showAddEditGoalSheet(context),
            icon: const Icon(Icons.add),
            tooltip: 'লক্ষ্য যোগ করুন',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'চলমান'),
            Tab(text: 'সম্পন্ন'),
            Tab(text: 'বাতিল'),
          ],
        ),
      ),
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _GoalsTab(
                  goals: goalState.activeGoals,
                  emptyEmoji: '🎯',
                  emptyTitle: 'কোনো লক্ষ্য নেই',
                  emptySubtitle: 'নতুন saving goal set করুন',
                  actionLabel: 'লক্ষ্য যোগ করুন',
                  onAction: () => showAddEditGoalSheet(context),
                  itemBuilder: (goal) => GoalCard(
                    goal: goal,
                    onTap: () => _openDetail(goal.id),
                    onAddSaving: () => showAddSavingSheet(context, goal),
                    onEdit: () =>
                        showAddEditGoalSheet(context, existingGoal: goal),
                    onCancel: () => _confirmCancel(goal),
                    onDelete: () => _confirmDelete(goal),
                  ),
                ),
                _GoalsTab(
                  goals: goalState.achievedGoals,
                  emptyEmoji: '🏆',
                  emptyTitle: 'এখনো কোনো লক্ষ্য পূরণ হয়নি',
                  emptySubtitle: 'নিয়মিত save করলে এখানে দেখাবে',
                  itemBuilder: (goal) => GoalCard(
                    goal: goal,
                    achieved: true,
                    onTap: () => _openDetail(goal.id),
                    onDelete: () => _confirmDelete(goal),
                  ),
                ),
                _GoalsTab(
                  goals: goalState.cancelledGoals,
                  emptyEmoji: '🗂️',
                  emptyTitle: 'কোনো বাতিল লক্ষ্য নেই',
                  emptySubtitle: 'বাতিল করা লক্ষ্য এখানে থাকবে',
                  itemBuilder: (goal) => GoalCard(
                    goal: goal,
                    cancelled: true,
                    onTap: () => _openDetail(goal.id),
                    onDelete: () => _confirmDelete(goal),
                  ),
                ),
              ],
            ),
    );
  }

  void _openDetail(int goalId) {
    Navigator.of(context).push(buildAppRoute(GoalDetailScreen(goalId: goalId)));
  }

  Future<void> _confirmCancel(GoalEntity goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('লক্ষ্য বাতিল করবেন?'),
          content: Text('"${goal.title}" বাতিল করলে এটি আলাদা tab-এ চলে যাবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('বাতিল করুন'),
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('মুছুন'),
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
    required this.goals,
    required this.emptyEmoji,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.itemBuilder,
    this.actionLabel,
    this.onAction,
  });

  final List<GoalEntity> goals;
  final String emptyEmoji;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(GoalEntity goal) itemBuilder;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emptyEmoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(emptyTitle, style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => itemBuilder(goals[index]),
    );
  }
}
