import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/debt_entity.dart';
import '../models/mutation_result.dart';
import '../providers/debt_providers.dart';
import '../utils/debt_ui.dart';

Future<MutationResult?> showRecordInstallmentSheet(
  BuildContext context, {
  required DebtEntity debt,
}) {
  return AppBottomSheet.show<MutationResult>(
    context: context,
    title: 'কিস্তি দিয়েছি',
    subtitle: debt.personName,
    child: RecordInstallmentSheet(debt: debt),
  );
}

class RecordInstallmentSheet extends ConsumerStatefulWidget {
  const RecordInstallmentSheet({super.key, required this.debt});

  final DebtEntity debt;

  @override
  ConsumerState<RecordInstallmentSheet> createState() =>
      _RecordInstallmentSheetState();
}

class _RecordInstallmentSheetState
    extends ConsumerState<RecordInstallmentSheet> {
  int? _selectedWalletId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedWalletId = widget.debt.walletId;
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final nextInstallmentNumber = widget.debt.paidInstallments + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${BanglaFormatters.currency(widget.debt.nextInstallmentAmount)} কিস্তি পরিশোধ নিশ্চিত করুন?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'কিস্তি #${BanglaFormatters.count(nextInstallmentNumber)}/${BanglaFormatters.count(widget.debt.totalInstallments)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        WalletSelectorWidget(
          selectedWalletId: effectiveWalletId,
          onChanged: (walletId) {
            setState(() {
              _selectedWalletId = walletId;
            });
          },
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppActionButton(
          label: 'নিশ্চিত করুন',
          icon: Icons.check_circle_rounded,
          fullWidth: true,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _confirm,
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(debtMutationControllerProvider)
        .recordInstallmentPaid(widget.debt.id, walletId: _selectedWalletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!result.isSuccess) {
      showDebtMutationResultSnackBar(context, result);
      return;
    }

    Navigator.of(context).pop(result);
  }
}
