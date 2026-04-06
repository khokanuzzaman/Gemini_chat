// Feature: Goals
// Layer: Presentation

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/goal_entity.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.onAddSaving,
    this.onEdit,
    this.onCancel,
    this.onDelete,
    this.achieved = false,
    this.cancelled = false,
  });

  final GoalEntity goal;
  final VoidCallback onTap;
  final VoidCallback? onAddSaving;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final bool achieved;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final badgeColor = goal.isOnTrack ? AppColors.success : AppColors.warning;
    final badgeLabel = goal.isOnTrack ? '✓ ঠিকঠাক' : '⚠ পিছিয়ে';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.title, style: AppTextStyles.titleMedium),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: context.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${goal.daysRemaining} দিন বাকি',
                              style: AppTextStyles.caption.copyWith(
                                color: goal.daysRemaining < 30
                                    ? AppColors.warning
                                    : context.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!achieved && !cancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (cancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.borderColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'বাতিল',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'সংরক্ষিত',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      Text(
                        BanglaFormatters.currency(goal.savedAmount),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'লক্ষ্যমাত্রা',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      Text(
                        BanglaFormatters.currency(goal.targetAmount),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: context.borderColor.withValues(alpha: 0.3),
                  color: goal.statusColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: goal.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'মাসে ৳${goal.requiredMonthlySaving.toStringAsFixed(0)} দরকার',
                    style: AppTextStyles.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!achieved && !cancelled)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddSaving,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('টাকা যোগ করুন'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: context.borderColor),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'cancel') {
                          onCancel?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (_) => [
                        if (onCancel != null)
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text('লক্ষ্য বাতিল করুন'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('মুছুন'),
                          ),
                      ],
                    ),
                  ],
                ),
              if (achieved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎉 লক্ষ্য পূরণ হয়েছে!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (cancelled)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('মুছুন'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
