import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';

Future<void> showAddEditGoalSheet(
  BuildContext context, {
  GoalEntity? existingGoal,
}) async {
  await AppBottomSheet.show<void>(
    context: context,
    title: existingGoal == null ? 'লক্ষ্য যোগ করুন' : 'লক্ষ্য সম্পাদনা করুন',
    subtitle: existingGoal == null
        ? 'একটি নতুন সঞ্চয় লক্ষ্য তৈরি করুন'
        : 'আপনার লক্ষ্য তথ্য আপডেট করুন',
    child: AddEditGoalSheet(existingGoal: existingGoal),
  );
}

class AddEditGoalSheet extends ConsumerStatefulWidget {
  const AddEditGoalSheet({super.key, this.existingGoal});

  final GoalEntity? existingGoal;

  @override
  ConsumerState<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends ConsumerState<AddEditGoalSheet> {
  static const _emojis = [
    '🏠',
    '🚗',
    '✈️',
    '📱',
    '💍',
    '🎓',
    '🏥',
    '💰',
    '🛒',
    '🎮',
    '📚',
    '🏋',
    '🌴',
    '🎨',
    '🍕',
    '👶',
    '🐶',
    '💻',
    '🎸',
    '🏖️',
    '🎯',
    '💪',
    '🌟',
    '🎪',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _alreadySavedController;
  late final TextEditingController _notesController;
  late String _selectedEmoji;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final existingGoal = widget.existingGoal;
    _titleController = TextEditingController(text: existingGoal?.title ?? '');
    _targetAmountController = TextEditingController(
      text: existingGoal == null
          ? ''
          : existingGoal.targetAmount.toStringAsFixed(0),
    );
    _alreadySavedController = TextEditingController(
      text: existingGoal == null
          ? ''
          : existingGoal.savedAmount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: existingGoal?.notes ?? '');
    _selectedEmoji = existingGoal?.emoji ?? _emojis.first;
    _targetDate =
        existingGoal?.targetDate ??
        DateTime.now().add(const Duration(days: 180));

    _titleController.addListener(_triggerRebuild);
    _targetAmountController.addListener(_triggerRebuild);
    _alreadySavedController.addListener(_triggerRebuild);
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_triggerRebuild)
      ..dispose();
    _targetAmountController
      ..removeListener(_triggerRebuild)
      ..dispose();
    _alreadySavedController
      ..removeListener(_triggerRebuild)
      ..dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _triggerRebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;
    final targetAmount =
        double.tryParse(_targetAmountController.text.trim()) ?? 0;
    final alreadySaved =
        double.tryParse(_alreadySavedController.text.trim()) ?? 0;
    final canSave =
        _titleController.text.trim().isNotEmpty &&
        targetAmount > 0 &&
        _targetDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.appColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _titleController.text.trim().isEmpty
                    ? 'নতুন লক্ষ্য'
                    : _titleController.text.trim(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: context.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                padding: EdgeInsets.zero,
                title: 'ইমোজি বেছে নিন',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _emojis
                    .map(
                      (emoji) => AppChip(
                        label: emoji,
                        selected: _selectedEmoji == emoji,
                        onTap: () => setState(() => _selectedEmoji = emoji),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        TextField(
          controller: _titleController,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'লক্ষ্যের নাম',
            hintText: 'যেমন: Emergency Fund, বিদেশ ভ্রমণ',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _targetAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: AppTextStyles.heroAmount.copyWith(
            color: context.primaryTextColor,
          ),
          decoration: InputDecoration(
            labelText: 'লক্ষ্যমাত্রা',
            prefixText: '৳ ',
            filled: true,
            fillColor: context.mutedSurfaceColor,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!isEditing) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _alreadySavedController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ইতিমধ্যে সঞ্চিত (ঐচ্ছিক)',
              prefixText: '৳ ',
              hintText: 'আগে থেকে কিছু save থাকলে দিন',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        InkWell(
          borderRadius: const BorderRadius.all(AppRadius.input),
          onTap: () async {
            final initialDate =
                _targetDate ?? DateTime.now().add(const Duration(days: 180));
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null && mounted) {
              setState(() => _targetDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.mutedSurfaceColor,
              borderRadius: const BorderRadius.all(AppRadius.input),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: context.appColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'লক্ষ্য তারিখ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _targetDate != null
                            ? BanglaFormatters.fullDate(_targetDate!)
                            : 'তারিখ বেছে নিন',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_targetDate != null)
                  Text(
                    '${BanglaFormatters.count(_targetDate!.difference(DateTime.now()).inDays)} দিন',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (targetAmount > 0 && _targetDate != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            elevation: 1,
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 18,
                  color: context.appColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'প্রতি মাসে ${BanglaFormatters.currency(_calcMonthly(targetAmount, alreadySaved))} জমাতে হবে',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.appColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'নোট (ঐচ্ছিক)',
            hintText: 'এই লক্ষ্য কেন গুরুত্বপূর্ণ?',
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppActionButton(
          label: isEditing ? 'আপডেট করুন' : 'সংরক্ষণ করুন',
          icon: Icons.check_rounded,
          fullWidth: true,
          onPressed: canSave
              ? () async {
                  final navigator = Navigator.of(context);
                  final goal = GoalEntity(
                    id: widget.existingGoal?.id ?? 0,
                    title: _titleController.text.trim(),
                    emoji: _selectedEmoji,
                    targetAmount: targetAmount,
                    savedAmount: isEditing
                        ? widget.existingGoal!.savedAmount
                        : alreadySaved,
                    targetDate: _targetDate!,
                    createdAt: widget.existingGoal?.createdAt ?? DateTime.now(),
                    status:
                        (isEditing
                                ? widget.existingGoal!.savedAmount
                                : alreadySaved) >=
                            targetAmount
                        ? GoalStatus.achieved
                        : (widget.existingGoal?.status ?? GoalStatus.active),
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );
                  if (isEditing) {
                    await ref.read(goalProvider.notifier).updateGoal(goal);
                  } else {
                    await ref.read(goalProvider.notifier).addGoal(goal);
                  }
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                }
              : null,
        ),
      ],
    );
  }

  double _calcMonthly(double targetAmount, double alreadySaved) {
    if (_targetDate == null) {
      return 0;
    }
    final remaining = (targetAmount - alreadySaved).clamp(0.0, double.infinity);
    final daysLeft = _targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) {
      return remaining;
    }
    final monthsLeft = daysLeft / 30.0;
    if (monthsLeft <= 0) {
      return remaining;
    }
    return remaining / monthsLeft;
  }
}
