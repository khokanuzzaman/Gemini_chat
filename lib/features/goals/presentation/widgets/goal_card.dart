import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
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
    final statusColor = cancelled
        ? context.secondaryTextColor
        : achieved
        ? AppColors.success
        : context.appColors.primary;
    final statusLabel = cancelled
        ? 'বাতিল'
        : achieved
        ? 'সম্পন্ন'
        : 'চলমান';

    return AppCard(
      elevation: 2,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(goal.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${BanglaFormatters.count(goal.daysRemaining)} দিন বাকি',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: goal.daysRemaining < 30
                            ? AppColors.warning
                            : context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip(label: statusLabel, color: statusColor, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: goal.progressPercentage / 100,
            color: statusColor,
            showLabel: true,
            label: 'অগ্রগতি',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.secondaryTextColor,
                    ),
                    children: [
                      TextSpan(
                        text: BanglaFormatters.currency(goal.savedAmount),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' / ${BanglaFormatters.currency(goal.targetAmount)}',
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'মাসে ${BanglaFormatters.currency(goal.requiredMonthlySaving)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (!achieved && !cancelled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppActionButton(
                    label: 'সঞ্চয় যোগ',
                    icon: Icons.add_rounded,
                    variant: AppActionButtonVariant.secondary,
                    onPressed: onAddSaving,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppActionButton(
                    label: 'সম্পাদনা',
                    icon: Icons.edit_outlined,
                    variant: AppActionButtonVariant.ghost,
                    onPressed: onEdit,
                  ),
                ),
                if (onCancel != null || onDelete != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'cancel') {
                        onCancel?.call();
                      }
                      if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (_) => [
                      if (onCancel != null)
                        const PopupMenuItem<String>(
                          value: 'cancel',
                          child: Text('লক্ষ্য বাতিল করুন'),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('মুছুন'),
                        ),
                    ],
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.mutedSurfaceColor,
                        borderRadius: AppRadius.buttonAll,
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (achieved) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.cardAll,
              ),
              child: Text(
                'লক্ষ্য পূরণ হয়েছে',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (cancelled && onDelete != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: AppActionButton(
                label: 'মুছুন',
                icon: Icons.delete_outline_rounded,
                size: AppActionButtonSize.small,
                variant: AppActionButtonVariant.danger,
                onPressed: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
