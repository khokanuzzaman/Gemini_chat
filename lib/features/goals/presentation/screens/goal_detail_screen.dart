// Feature: Goals
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/goal_saving.dart';
import '../providers/goal_provider.dart';
import '../widgets/add_edit_goal_sheet.dart';
import '../widgets/add_saving_sheet.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final int goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalState = ref.watch(goalProvider);
    final goal = goalState.goals.where((item) => item.id == goalId).firstOrNull;

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('লক্ষ্য')),
        body: goalState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('লক্ষ্যটি পাওয়া যায়নি')),
      );
    }

    final savingsAsync = ref.watch(goalSavingsProvider(goal.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            onPressed: goal.status == GoalStatus.cancelled
                ? null
                : () => showAddEditGoalSheet(context, existingGoal: goal),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'cancel') {
                final confirmed = await _confirmAction(
                  context,
                  title: 'লক্ষ্য বাতিল করবেন?',
                  message: 'এই লক্ষ্যটি বাতিল করা হবে।',
                );
                if (confirmed != true) {
                  return;
                }
                await ref.read(goalProvider.notifier).cancelGoal(goal.id);
              } else if (value == 'delete') {
                final confirmed = await _confirmAction(
                  context,
                  title: 'লক্ষ্য মুছবেন?',
                  message: 'লক্ষ্য এবং saving history মুছে যাবে।',
                );
                if (confirmed != true) {
                  return;
                }
                await ref.read(goalProvider.notifier).deleteGoal(goal.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (_) => [
              if (goal.status == GoalStatus.active)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('Cancel goal'),
                ),
              const PopupMenuItem(value: 'delete', child: Text('Delete goal')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.05),
              child: Column(
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text(
                    goal.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: goal.progressPercentage / 100,
                          strokeWidth: 12,
                          backgroundColor: context.borderColor.withValues(
                            alpha: 0.3,
                          ),
                          color: goal.statusColor,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${goal.progressPercentage.toStringAsFixed(0)}%',
                                style: AppTextStyles.displayMedium.copyWith(
                                  color: goal.statusColor,
                                ),
                              ),
                              Text(
                                'সম্পন্ন',
                                style: AppTextStyles.caption.copyWith(
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _StatCard(
                    icon: Icons.savings_outlined,
                    label: 'সংরক্ষিত',
                    value: BanglaFormatters.currency(goal.savedAmount),
                    color: AppColors.success,
                  ),
                  _StatCard(
                    icon: Icons.flag_outlined,
                    label: 'বাকি',
                    value: BanglaFormatters.currency(goal.remainingAmount),
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    icon: Icons.calendar_today_outlined,
                    label: 'দিন বাকি',
                    value: '${goal.daysRemaining} দিন',
                    color: goal.daysRemaining < 30
                        ? AppColors.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    icon: Icons.trending_up_outlined,
                    label: 'মাসিক লক্ষ্য',
                    value: '৳${goal.requiredMonthlySaving.toStringAsFixed(0)}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        goal.isOnTrack
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_outlined,
                        color: goal.isOnTrack
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.isOnTrack
                              ? 'আপনি সঠিক পথে আছেন! এই গতিতে চলতে থাকুন।'
                              : 'একটু পিছিয়ে আছেন। মাসে ৳${goal.requiredMonthlySaving.toStringAsFixed(0)} save করলে লক্ষ্যে পৌঁছাবেন।',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (goal.status == GoalStatus.active) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: () => showAddSavingSheet(context, goal),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('টাকা যোগ করুন'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'সংরক্ষণের ইতিহাস',
                    style: AppTextStyles.titleMedium,
                  ),
                  const Spacer(),
                  savingsAsync.maybeWhen(
                    data: (items) => Text(
                      '${items.length}টি',
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: savingsAsync.when(
                data: (savings) {
                  if (savings.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'এখনো কোনো সংরক্ষণ নেই',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    );
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < savings.length;
                          index++
                        ) ...[
                          _SavingTile(saving: savings[index]),
                          if (index != savings.length - 1)
                            Divider(height: 1, color: context.borderColor),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$error'),
                ),
              ),
            ),
            if (goal.notes != null && goal.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.note_outlined,
                      color: context.secondaryTextColor,
                      size: 20,
                    ),
                    title: Text(goal.notes!, style: AppTextStyles.bodyMedium),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('হ্যাঁ'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingTile extends StatelessWidget {
  const _SavingTile({required this.saving});

  final GoalSaving saving;

  @override
  Widget build(BuildContext context) {
    final subtitle = saving.note?.trim().isNotEmpty == true
        ? saving.note!
        : BanglaFormatters.fullDate(saving.date);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.success.withValues(alpha: 0.1),
        child: const Icon(Icons.add, color: AppColors.success, size: 18),
      ),
      title: Text(
        BanglaFormatters.currency(saving.amount),
        style: AppTextStyles.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: context.secondaryTextColor,
        ),
      ),
      trailing: Text(
        BanglaFormatters.dayMonth(saving.date),
        style: AppTextStyles.caption.copyWith(
          color: context.secondaryTextColor,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
