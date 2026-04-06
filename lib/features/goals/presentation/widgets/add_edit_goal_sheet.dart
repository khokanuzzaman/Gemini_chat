// Feature: Goals
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';

Future<void> showAddEditGoalSheet(
  BuildContext context, {
  GoalEntity? existingGoal,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEditGoalSheet(existingGoal: existingGoal),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canSave =
        _titleController.text.trim().isNotEmpty &&
        targetAmount > 0 &&
        _targetDate != null;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: context.cardBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'লক্ষ্য সম্পাদনা' : 'নতুন লক্ষ্য',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Center(
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _selectedEmoji,
                                    key: ValueKey(_selectedEmoji),
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _titleController.text.trim().isEmpty
                                      ? 'লক্ষ্যের নাম'
                                      : _titleController.text.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ইমোজি বেছে নিন',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _emojis
                                .map((emoji) {
                                  final isSelected = _selectedEmoji == emoji;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedEmoji = emoji),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.15)
                                            : context.surfaceColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : context.borderColor,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  );
                                })
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            maxLength: 30,
                            decoration: const InputDecoration(
                              labelText: 'লক্ষ্যের নাম',
                              hintText: 'যেমন: Emergency Fund, বিদেশ ভ্রমণ',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _targetAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'লক্ষ্যমাত্রা',
                              prefixText: '৳ ',
                            ),
                          ),
                          if (!isEditing) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _alreadySavedController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'ইতিমধ্যে সংরক্ষিত (optional)',
                                prefixText: '৳ ',
                                hintText: 'আগে থেকে কিছু save থাকলে',
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final initialDate =
                                  _targetDate ??
                                  DateTime.now().add(const Duration(days: 180));
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (picked != null && mounted) {
                                setState(() => _targetDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.borderColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'লক্ষ্য তারিখ',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color:
                                                    context.secondaryTextColor,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _targetDate != null
                                              ? BanglaFormatters.fullDate(
                                                  _targetDate!,
                                                )
                                              : 'তারিখ বেছে নিন',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_targetDate != null)
                                    Text(
                                      '${_targetDate!.difference(DateTime.now()).inDays} দিন',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (targetAmount > 0 && _targetDate != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calculate_outlined,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'প্রতি মাসে ৳${_calcMonthly(targetAmount, alreadySaved).toStringAsFixed(0)} save করতে হবে',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'নোট (optional)',
                              hintText: 'এই লক্ষ্য কেন গুরুত্বপূর্ণ?',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
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
                                  createdAt:
                                      widget.existingGoal?.createdAt ??
                                      DateTime.now(),
                                  status:
                                      (isEditing
                                              ? widget.existingGoal!.savedAmount
                                              : alreadySaved) >=
                                          targetAmount
                                      ? GoalStatus.achieved
                                      : (widget.existingGoal?.status ??
                                            GoalStatus.active),
                                  notes: _notesController.text.trim().isEmpty
                                      ? null
                                      : _notesController.text.trim(),
                                );
                                if (isEditing) {
                                  await ref
                                      .read(goalProvider.notifier)
                                      .updateGoal(goal);
                                } else {
                                  await ref
                                      .read(goalProvider.notifier)
                                      .addGoal(goal);
                                }
                                if (!mounted) {
                                  return;
                                }
                                navigator.pop();
                              }
                            : null,
                        child: Text(
                          isEditing ? 'Update করুন' : 'লক্ষ্য যোগ করুন',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
