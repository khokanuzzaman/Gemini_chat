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

Future<MutationResult?> showAddPaymentSheet(
  BuildContext context, {
  required DebtEntity debt,
}) {
  return AppBottomSheet.show<MutationResult>(
    context: context,
    title: 'পরিশোধ যোগ করুন',
    subtitle: debt.personName,
    child: AddPaymentSheet(debt: debt),
  );
}

class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({super.key, required this.debt});

  final DebtEntity debt;

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  int? _selectedWalletId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedWalletId = widget.debt.walletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final accent = widget.debt.type.accentColor;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.debt.personName,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'বাকি আছে ${BanglaFormatters.currency(widget.debt.remainingAmount)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.debt.isEMI) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'এটি অতিরিক্ত বা ম্যানুয়াল পরিশোধ হিসেবে যোগ হবে।',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: '৫০%',
                color: accent,
                onTap: () {
                  _amountController.text = _formatAmount(
                    widget.debt.remainingAmount / 2,
                  );
                },
              ),
              AppChip(
                label: 'পুরোটা',
                color: accent,
                onTap: () {
                  _amountController.text = _formatAmount(
                    widget.debt.remainingAmount,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          TextFormField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.titleLarge.copyWith(color: accent),
            decoration: InputDecoration(
              labelText: 'পরিশোধের পরিমাণ',
              hintText:
                  'সর্বোচ্চ: ${BanglaFormatters.currency(widget.debt.remainingAmount)}',
              prefixText: '৳ ',
              filled: true,
              fillColor: accent.withValues(alpha: 0.08),
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null || amount <= 0) {
                return 'সঠিক টাকার পরিমাণ দিন';
              }
              if (amount > widget.debt.remainingAmount) {
                return 'বাকি টাকার চেয়ে বেশি দেওয়া যাবে না';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          WalletSelectorWidget(
            selectedWalletId: effectiveWalletId,
            onChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'নোট',
              hintText: 'ঐচ্ছিক নোট',
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppActionButton(
            label: 'সংরক্ষণ করুন',
            icon: Icons.payment_rounded,
            fullWidth: true,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(debtMutationControllerProvider)
        .addPayment(
          widget.debt.id,
          amount,
          walletId: _selectedWalletId,
          note: _normalizeText(_noteController.text),
        );

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

  String? _normalizeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatAmount(double amount) {
    final hasFraction = (amount - amount.round()).abs() >= 0.01;
    return hasFraction ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
  }
}
