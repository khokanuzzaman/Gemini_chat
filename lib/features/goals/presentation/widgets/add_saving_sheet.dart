import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goal_provider.dart';

Future<void> showAddSavingSheet(BuildContext context, GoalEntity goal) async {
  final achieved = await AppBottomSheet.show<bool>(
    context: context,
    title: 'সঞ্চয় যোগ করুন',
    subtitle: goal.title,
    child: AddSavingSheet(goal: goal),
  );

  if (achieved == true && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('অভিনন্দন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: AppSpacing.md),
              Text(
                '"${goal.title}" লক্ষ্য পূরণ হয়েছে!',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge,
              ),
            ],
          ),
          actions: [
            AppActionButton(
              label: 'দারুণ',
              onPressed: () => Navigator.of(dialogContext).pop(),
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
    final presets = [
      500,
      1000,
      2000,
      5000,
    ].where((amount) => amount <= remainingAmount).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${BanglaFormatters.currency(widget.goal.savedAmount)} / ${BanglaFormatters.currency(widget.goal.targetAmount)}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.goal.progressPercentage.toStringAsFixed(0)}%',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: widget.goal.statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppProgressBar(
                value: widget.goal.progressPercentage / 100,
                color: widget.goal.statusColor,
                showLabel: true,
                label: 'অগ্রগতি',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        if (presets.isNotEmpty) ...[
          const AppSectionHeader(
            padding: EdgeInsets.zero,
            title: 'দ্রুত বেছে নিন',
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...presets.map(
                (amount) => AppChip(
                  label: BanglaFormatters.currency(amount.toDouble()),
                  onTap: () {
                    _amountController.text = amount.toString();
                  },
                ),
              ),
              if (remainingAmount > 0)
                AppChip(
                  label: 'বাকি সব',
                  onTap: () {
                    _amountController.text = remainingAmount.toStringAsFixed(0);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: AppTextStyles.heroAmount.copyWith(color: AppColors.success),
          decoration: InputDecoration(
            labelText: 'পরিমাণ',
            prefixText: '৳ ',
            filled: true,
            fillColor: AppColors.success.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'নোট (ঐচ্ছিক)',
            hintText: 'কোথা থেকে save করলেন?',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (willAchieve)
          AppCard(
            elevation: 1,
            child: Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'এই amount দিলে লক্ষ্য পূরণ হবে',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppActionButton(
          label: 'সংরক্ষণ করুন',
          icon: Icons.check_rounded,
          fullWidth: true,
          onPressed: () async {
            final navigator = Navigator.of(context);
            final amount = double.tryParse(_amountController.text.trim()) ?? 0;
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
              widget.goal.savedAmount + amount >= widget.goal.targetAmount,
            );
          },
        ),
      ],
    );
  }
}
