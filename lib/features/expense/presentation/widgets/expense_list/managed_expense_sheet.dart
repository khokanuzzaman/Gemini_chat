import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/navigation/app_shell_navigation.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../domain/entities/expense_entity.dart';
import '../../../domain/entities/expense_source.dart';

/// Opens the read-only view for a row the খরচ list does not own (an EMI /
/// debt repayment, or a goal deposit). Editing or deleting the mirror row alone
/// would desync the debt (or goal), so the only way to change it is from the
/// owner's screen, where the payment, the debt and the wallet reverse together.
Future<void> showManagedExpenseSheet(
  BuildContext context,
  ExpenseEntity expense,
) {
  final isDebt = expense.sourceType == ExpenseSource.debtPayment;
  return AppBottomSheet.show<void>(
    context: context,
    title: isDebt ? 'দেনা-পাওনার পরিশোধ' : 'লক্ষ্যের জমা',
    child: ManagedExpenseDetails(expense: expense),
  );
}

class ManagedExpenseDetails extends ConsumerWidget {
  const ManagedExpenseDetails({super.key, required this.expense});

  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final isDebt = expense.sourceType == ExpenseSource.debtPayment;
    final wallet = expense.walletId == null
        ? null
        : ref.watch(walletByIdProvider(expense.walletId!));
    final title = expense.description.trim().isEmpty
        ? expense.category
        : expense.description.trim();
    final debtId = expense.sourceId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.brassSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDebt ? Icons.payments_rounded : Icons.savings_rounded,
                size: 22,
                color: context.brassGlyph,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BanglaFormatters.currency(expense.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(color: tokens.ink),
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(
          label: 'তারিখ ও সময়',
          value:
              '${BanglaFormatters.fullDate(expense.date)} · ${BanglaFormatters.time(expense.date)}',
        ),
        if (wallet != null)
          _DetailRow(label: 'ওয়ালেট', value: '${wallet.emoji} ${wallet.shownName}'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: tokens.brassSoft,
            borderRadius: AppRadius.cardAll,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: context.brassGlyph,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isDebt
                      ? 'এই খরচটি দেনা-পাওনার সাথে যুক্ত, তাই এখান থেকে বদলানো বা মুছা যায় না। দেনা-পাওনা থেকে বদলালে ওয়ালেট ও বাকি পরিমাণ একসাথে ঠিক থাকবে।'
                      : 'এই জমাটি লক্ষ্যের সাথে যুক্ত, তাই এখান থেকে বদলানো বা মুছা যায় না।',
                  style: AppTextStyles.bodyMedium.copyWith(color: tokens.ink),
                ),
              ),
            ],
          ),
        ),
        if (isDebt) ...[
          const SizedBox(height: AppSpacing.lg),
          AppActionButton(
            label: 'দেনা-পাওনা থেকে পরিবর্তন করুন',
            icon: Icons.open_in_new_rounded,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              if (debtId != null) {
                AppShellNavigation.openDebtDetail(debtId);
              } else {
                AppShellNavigation.openDebts();
              }
            },
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: tokens.muted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(color: tokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}
