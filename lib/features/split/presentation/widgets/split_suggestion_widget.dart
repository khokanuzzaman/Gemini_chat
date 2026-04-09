import 'package:flutter/material.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/split_bill_entity.dart';

class SplitSuggestionWidget extends StatelessWidget {
  const SplitSuggestionWidget({
    super.key,
    required this.expense,
    required this.personCount,
    required this.onSaveOnly,
    required this.onOpenSplit,
  });

  final ExpenseData expense;
  final int personCount;
  final Future<void> Function() onSaveOnly;
  final VoidCallback onOpenSplit;

  @override
  Widget build(BuildContext context) {
    final normalizedCount = personCount < 2 ? 2 : personCount;
    final perPerson = normalizedCount == 0
        ? 0.0
        : expense.amount / normalizedCount;

    return AppCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_split_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Bill split করবেন?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'মোট ${BanglaFormatters.preciseCurrency(expense.amount)} · ${BanglaFormatters.count(normalizedCount)} জন · জনপ্রতি ${BanglaFormatters.preciseCurrency(perPerson)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppActionButton(
                  label: 'শুধু save করুন',
                  variant: AppActionButtonVariant.ghost,
                  onPressed: () {
                    onSaveOnly();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppActionButton(
                  label: 'Split করুন',
                  icon: Icons.call_split_rounded,
                  onPressed: onOpenSplit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SplitSuggestionCard extends StatelessWidget {
  const SplitSuggestionCard({super.key, required this.settlement});

  final SettlementSuggestion settlement;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Row(
        children: [
          Expanded(
            child: Text(
              settlement.from,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: context.secondaryTextColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              settlement.to,
              textAlign: TextAlign.right,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            BanglaFormatters.preciseCurrency(settlement.amount),
            style: AppTextStyles.titleMedium.copyWith(
              color: context.appColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
