// Feature: Goals
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';

Future<void> showAddSavingSheet(BuildContext context, GoalEntity goal) async {
  final achieved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddSavingSheet(goal: goal),
  );

  if (achieved == true && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('অভিনন্দন!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                '"${goal.title}" লক্ষ্য পূরণ হয়েছে!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('দারুণ!'),
            ),
          ],
        );
      },
    );
  }
}

class AddSavingSheet extends ConsumerStatefulWidget {
  const AddSavingSheet({super.key, required this.goal});

  final GoalEntity goal;

  @override
  ConsumerState<AddSavingSheet> createState() => _AddSavingSheetState();
}

class _AddSavingSheetState extends ConsumerState<AddSavingSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _amountController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_handleChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final willAchieve =
        enteredAmount > 0 &&
        widget.goal.savedAmount + enteredAmount >= widget.goal.targetAmount;
    final remainingAmount = widget.goal.remainingAmount;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final presets = [
      500,
      1000,
      2000,
      5000,
    ].where((amount) => amount <= remainingAmount).toList(growable: false);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomInset + 16,
          top: 16,
        ),
        child: Material(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('টাকা যোগ করুন', style: AppTextStyles.titleLarge),
                const SizedBox(height: 2),
                Text(
                  widget.goal.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      BanglaFormatters.currency(widget.goal.savedAmount),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      ' / ${BanglaFormatters.currency(widget.goal.targetAmount)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${widget.goal.progressPercentage.toStringAsFixed(0)}%',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: widget.goal.statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: widget.goal.progressPercentage / 100,
                    minHeight: 4,
                    backgroundColor: context.borderColor.withValues(alpha: 0.3),
                    color: widget.goal.statusColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'দ্রুত বেছে নিন',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...presets.map(
                      (amount) => OutlinedButton(
                        onPressed: () {
                          _amountController.text = amount.toString();
                        },
                        child: Text('৳$amount'),
                      ),
                    ),
                    if (remainingAmount > 0)
                      OutlinedButton(
                        onPressed: () {
                          _amountController.text = remainingAmount
                              .toStringAsFixed(0);
                        },
                        child: Text(
                          'বাকি সব (৳${remainingAmount.toStringAsFixed(0)})',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'পরিমাণ',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'নোট (optional)',
                    hintText: 'কোথা থেকে save করলেন?',
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: willAchieve
                      ? Container(
                          key: const ValueKey('goal-achievement-preview'),
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'এই amount দিলে লক্ষ্য পূরণ হবে!',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final amount =
                          double.tryParse(_amountController.text.trim()) ?? 0;
                      if (amount <= 0) {
                        return;
                      }
                      await ref
                          .read(goalProvider.notifier)
                          .addSaving(
                            goalId: widget.goal.id,
                            amount: amount,
                            note: _noteController.text.trim().isEmpty
                                ? null
                                : _noteController.text.trim(),
                          );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop(
                        widget.goal.savedAmount + amount >=
                            widget.goal.targetAmount,
                      );
                    },
                    child: const Text('Save করুন'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
