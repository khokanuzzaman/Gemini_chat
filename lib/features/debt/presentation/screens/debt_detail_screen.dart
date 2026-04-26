import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../providers/debt_providers.dart';
import '../utils/debt_ui.dart';
import '../widgets/add_edit_debt_sheet.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/record_installment_sheet.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final int debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(debtDetailProvider(debtId));

    return detailAsync.when(
      loading: () => const AppPageScaffold(
        title: 'ধার-দেনা',
        body: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: AppLoadingState.list(),
        ),
      ),
      error: (error, _) => AppPageScaffold(
        title: 'ধার-দেনা',
        body: AppErrorState(
          title: 'ধার-দেনা লোড করা যায়নি',
          message: '$error',
          onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
        ),
      ),
      data: (detail) {
        final debt = detail.debt;
        final status = resolveDebtStatus(debt);
        final wallets =
            ref.watch(walletProvider).valueOrNull ?? const <WalletEntity>[];
        final linkedWallet = _findWallet(wallets, debt.walletId);
        final bottomBar = _buildBottomBar(
          context: context,
          ref: ref,
          debt: debt,
          status: status,
        );

        return AppPageScaffold(
          title: debt.personName,
          actions: [
            IconButton(
              onPressed: () async {
                final result = await showAddEditDebtSheet(
                  context,
                  existingDebt: debt,
                );
                if (result != null && context.mounted) {
                  showDebtMutationResultSnackBar(context, result);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'সম্পাদনা',
            ),
            IconButton(
              onPressed: () => _confirmDelete(context, ref, debt),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'মুছুন',
            ),
          ],
          bottomNavigationBar: bottomBar,
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              bottomBar == null ? AppSpacing.xl : 140,
            ),
            children: [
              AppHeroCard(
                label: debt.detailLabelBn,
                amount: BanglaFormatters.currency(debt.remainingAmount),
                subtitle: debt.isEMI
                    ? 'মূল: ${BanglaFormatters.currency(debt.originalAmount)} · সুদসহ: ${BanglaFormatters.currency(debt.totalPayable)}'
                    : 'মূল: ${BanglaFormatters.currency(debt.originalAmount)}',
                icon: debt.type.directionIcon,
                gradient: debt.type.gradient,
                trailing: AppChip(
                  label: status.labelBn,
                  color: status.accentColor,
                  compact: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppProgressBar(
                value: (debt.progressPercentage / 100).clamp(0.0, 1.0),
                color: debt.isEMI
                    ? context.appColors.primary
                    : debt.type.accentColor,
                showLabel: true,
                label: debt.isEMI ? 'কিস্তি অগ্রগতি' : 'পরিশোধের অগ্রগতি',
              ),
              if (debt.isEMI) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${BanglaFormatters.count(debt.paidInstallments)}/${BanglaFormatters.count(debt.totalInstallments)} কিস্তি দেওয়া হয়েছে',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              if (debt.isEMI) ...[
                _EmiDetailsCard(debt: debt),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
              _GeneralInfoCard(
                debt: debt,
                linkedWallet: linkedWallet,
                status: status,
              ),
              if (status == DebtStatus.settled) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppChip(
                    label: 'পরিশোধিত ✓',
                    color: AppColors.success,
                    selected: true,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              AppSectionHeader(
                title: 'পরিশোধের ইতিহাস',
                action: _buildPaymentAction(context, debt, status),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.payments.isEmpty)
                AppCard(
                  child: const AppEmptyState(
                    icon: Icons.payment_rounded,
                    title: 'এখনো কোনো পরিশোধ হয়নি',
                    compact: true,
                  ),
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < detail.payments.length;
                        index++
                      ) ...[
                        _PaymentTile(
                          debt: debt,
                          payment: detail.payments[index],
                          wallet: _findWallet(
                            wallets,
                            detail.payments[index].walletId,
                          ),
                        ),
                        if (index != detail.payments.length - 1)
                          Divider(
                            height: 1,
                            color: context.borderColor.withValues(alpha: 0.4),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildBottomBar({
    required BuildContext context,
    required WidgetRef ref,
    required DebtEntity debt,
    required DebtStatus status,
  }) {
    if (status == DebtStatus.settled || status == DebtStatus.cancelled) {
      return null;
    }

    if (debt.isEMI) {
      return _DebtActionBar(
        debt: debt,
        child: AppActionButton(
          label: 'কিস্তি দিয়েছি ✓',
          icon: Icons.check_circle_outline_rounded,
          fullWidth: true,
          onPressed: () async {
            final result = await showRecordInstallmentSheet(
              context,
              debt: debt,
            );
            if (result != null && context.mounted) {
              showDebtMutationResultSnackBar(context, result);
            }
          },
        ),
      );
    }

    return _DebtActionBar(
      debt: debt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = [
            AppActionButton(
              label: 'পরিশোধ যোগ করুন',
              icon: Icons.payment_rounded,
              fullWidth: true,
              onPressed: () async {
                final result = await showAddPaymentSheet(context, debt: debt);
                if (result != null && context.mounted) {
                  showDebtMutationResultSnackBar(context, result);
                }
              },
            ),
            AppActionButton(
              label: 'সম্পূর্ণ পরিশোধ',
              icon: Icons.check_circle_outline_rounded,
              variant: AppActionButtonVariant.success,
              fullWidth: true,
              onPressed: () => _settleDebt(context, ref, debt),
            ),
          ];

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buttons[0],
                const SizedBox(height: AppSpacing.sm),
                buttons[1],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: buttons[0]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: buttons[1]),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildPaymentAction(
    BuildContext context,
    DebtEntity debt,
    DebtStatus status,
  ) {
    if (status != DebtStatus.active && status != DebtStatus.overdue) {
      return null;
    }

    if (debt.isEMI) {
      return AppActionButton(
        label: 'কিস্তি দিয়েছি ✓',
        icon: Icons.check_circle_outline_rounded,
        size: AppActionButtonSize.small,
        onPressed: () async {
          final result = await showRecordInstallmentSheet(context, debt: debt);
          if (result != null && context.mounted) {
            showDebtMutationResultSnackBar(context, result);
          }
        },
      );
    }

    return AppActionButton(
      label: 'যোগ করুন',
      icon: Icons.add_rounded,
      size: AppActionButtonSize.small,
      onPressed: () async {
        final result = await showAddPaymentSheet(context, debt: debt);
        if (result != null && context.mounted) {
          showDebtMutationResultSnackBar(context, result);
        }
      },
    );
  }

  WalletEntity? _findWallet(List<WalletEntity> wallets, int? walletId) {
    if (walletId == null) {
      return null;
    }
    for (final wallet in wallets) {
      if (wallet.id == walletId) {
        return wallet;
      }
    }
    return null;
  }

  Future<void> _settleDebt(
    BuildContext context,
    WidgetRef ref,
    DebtEntity debt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('সম্পূর্ণ পরিশোধ করবেন?'),
          content: Text(
            'বাকি ${BanglaFormatters.currency(debt.remainingAmount)} সম্পূর্ণ পরিশোধিত হিসেবে ধরা হবে।',
          ),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'সম্পূর্ণ পরিশোধ',
              variant: AppActionButtonVariant.success,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await ref
        .read(debtMutationControllerProvider)
        .settleDebt(debt.id);
    if (!context.mounted) {
      return;
    }
    showDebtMutationResultSnackBar(context, result);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DebtEntity debt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('রেকর্ডটি মুছবেন?'),
          content: Text(
            '“${debt.personName}” এর ধার-দেনার রেকর্ড স্থায়ীভাবে মুছে যাবে।',
          ),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await ref
        .read(debtMutationControllerProvider)
        .deleteDebt(debt.id);
    if (!context.mounted) {
      return;
    }

    if (!result.isSuccess) {
      showDebtMutationResultSnackBar(context, result);
      return;
    }

    Navigator.of(context).pop(result);
  }
}

class _EmiDetailsCard extends StatelessWidget {
  const _EmiDetailsCard({required this.debt});

  final DebtEntity debt;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.account_balance_outlined, 'প্রতিষ্ঠান', debt.personName),
      (
        Icons.payments_outlined,
        'মাসিক কিস্তি',
        BanglaFormatters.currency(debt.emiAmount),
      ),
      (
        Icons.percent_rounded,
        'সুদের হার',
        '${_formatBanglaNumber(debt.annualInterestRate)}%',
      ),
      (
        Icons.calendar_today_rounded,
        'মোট কিস্তি',
        '${BanglaFormatters.count(debt.totalInstallments)} মাস',
      ),
      (
        Icons.check_circle_outline_rounded,
        'দেওয়া হয়েছে',
        '${BanglaFormatters.count(debt.paidInstallments)} কিস্তি',
      ),
      (
        Icons.timelapse_rounded,
        'বাকি',
        '${BanglaFormatters.count(debt.remainingInstallments)} কিস্তি (${BanglaFormatters.currency(debt.remainingAmount)})',
      ),
      (
        Icons.schedule_rounded,
        'পরবর্তী কিস্তি',
        debt.nextInstallmentDate == null
            ? 'নির্ধারিত নয়'
            : BanglaFormatters.fullDate(debt.nextInstallmentDate!),
      ),
      (
        Icons.event_repeat_rounded,
        'কিস্তির তারিখ',
        debt.installmentDayOfMonth == null
            ? 'নির্ধারিত নয়'
            : 'প্রতি মাসের ${BanglaFormatters.count(debt.installmentDayOfMonth!)} তারিখ',
      ),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            AppListTile(
              title: items[index].$2,
              subtitle: items[index].$3,
              leadingIcon: items[index].$1,
              leadingColor: context.appColors.primary,
              dense: true,
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                color: context.borderColor.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({
    required this.debt,
    required this.linkedWallet,
    required this.status,
  });

  final DebtEntity debt;
  final WalletEntity? linkedWallet;
  final DebtStatus status;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      AppListTile(
        title: 'শুরুর তারিখ',
        subtitle: BanglaFormatters.fullDate(debt.createdAt),
        leadingIcon: Icons.calendar_today_rounded,
        leadingColor: context.appColors.primary,
        dense: true,
      ),
      if (!debt.isEMI && debt.dueDate != null)
        AppListTile(
          title: 'পরিশোধের তারিখ',
          subtitle: BanglaFormatters.fullDate(debt.dueDate!),
          leadingIcon: Icons.schedule_rounded,
          leadingColor: status == DebtStatus.overdue
              ? AppColors.error
              : context.appColors.primary,
          dense: true,
        ),
      if (linkedWallet != null)
        AppListTile(
          title: 'ওয়ালেট',
          subtitle: linkedWallet!.displayName,
          leadingIcon: Icons.account_balance_wallet_outlined,
          leadingColor: context.appColors.primary,
          dense: true,
        ),
      if (!debt.isEMI &&
          debt.personPhone != null &&
          debt.personPhone!.trim().isNotEmpty)
        AppListTile(
          title: 'ফোন',
          subtitle: debt.personPhone!,
          leadingIcon: Icons.phone_outlined,
          leadingColor: context.appColors.primary,
          dense: true,
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (debt.description != null &&
              debt.description!.trim().isNotEmpty) ...[
            Text(
              'বিবরণ',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              debt.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var index = 0; index < tiles.length; index++) ...[
            tiles[index],
            if (index != tiles.length - 1)
              Divider(
                height: 1,
                color: context.borderColor.withValues(alpha: 0.4),
              ),
          ],
          if (status == DebtStatus.overdue) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'মেয়াদোত্তীর্ণ!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (debt.note != null && debt.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'নোট',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              debt.note!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.debt,
    required this.payment,
    required this.wallet,
  });

  final DebtEntity debt;
  final DebtPaymentEntity payment;
  final WalletEntity? wallet;

  @override
  Widget build(BuildContext context) {
    final leadingColor = debt.type == DebtType.theyOwe
        ? AppColors.success
        : AppColors.error;
    final subtitleParts = <String>[BanglaFormatters.fullDate(payment.paidAt)];
    if (wallet != null) {
      subtitleParts.add(wallet!.emoji);
    }
    if (payment.note != null && payment.note!.trim().isNotEmpty) {
      subtitleParts.add(payment.note!);
    }

    final title = payment.isInstallment && payment.installmentNumber != null
        ? 'কিস্তি #${BanglaFormatters.count(payment.installmentNumber!)}'
        : '${BanglaFormatters.currency(payment.amount)} পরিশোধ';

    return AppListTile(
      title: title,
      subtitle: subtitleParts.join(' · '),
      leadingIcon: Icons.payment_rounded,
      leadingColor: leadingColor,
      trailingAmount: payment.amount,
      trailingAmountIsIncome: debt.type == DebtType.theyOwe,
      trailingAmountIsExpense: debt.type == DebtType.iOwe,
      dense: true,
    );
  }
}

class _DebtActionBar extends StatelessWidget {
  const _DebtActionBar({required this.debt, required this.child});

  final DebtEntity debt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final status = resolveDebtStatus(debt);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        border: Border(
          top: BorderSide(color: context.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == DebtStatus.overdue)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.cardAll,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'মেয়াদোত্তীর্ণ!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

String _formatBanglaNumber(double value) {
  final source = (value - value.round()).abs() < 0.01
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return source
      .replaceAll('0', '০')
      .replaceAll('1', '১')
      .replaceAll('2', '২')
      .replaceAll('3', '৩')
      .replaceAll('4', '৪')
      .replaceAll('5', '৫')
      .replaceAll('6', '৬')
      .replaceAll('7', '৭')
      .replaceAll('8', '৮')
      .replaceAll('9', '৯');
}
