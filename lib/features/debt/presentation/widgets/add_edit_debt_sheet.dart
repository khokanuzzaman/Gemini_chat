import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/utils/emi_calculator.dart';
import '../models/mutation_result.dart';
import '../providers/debt_providers.dart';
import '../utils/debt_ui.dart';

Future<MutationResult?> showAddEditDebtSheet(
  BuildContext context, {
  DebtEntity? existingDebt,
}) {
  return AppBottomSheet.show<MutationResult>(
    context: context,
    title: existingDebt == null ? 'নতুন ধার-দেনা' : 'সম্পাদনা',
    subtitle: existingDebt == null
        ? 'পাওনা, দেনা বা কিস্তির হিসাব সংরক্ষণ করুন'
        : 'ধার-দেনার তথ্য আপডেট করুন',
    child: AddEditDebtSheet(existingDebt: existingDebt),
  );
}

class AddEditDebtSheet extends ConsumerStatefulWidget {
  const AddEditDebtSheet({super.key, this.existingDebt});

  final DebtEntity? existingDebt;

  @override
  ConsumerState<AddEditDebtSheet> createState() => _AddEditDebtSheetState();
}

class _AddEditDebtSheetState extends ConsumerState<AddEditDebtSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _personNameController;
  late final TextEditingController _personPhoneController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _installmentCountController;
  late final TextEditingController _installmentDayController;

  late DebtType _selectedType;
  late bool _isEMI;
  DateTime? _selectedDueDate;
  int? _selectedWalletId;
  bool _reminderEnabled = false;
  bool _isSaving = false;

  bool get _isEditing => widget.existingDebt != null;

  @override
  void initState() {
    super.initState();
    final debt = widget.existingDebt;
    _selectedType = debt?.type ?? DebtType.theyOwe;
    _isEMI = debt?.isEMI ?? false;
    _selectedDueDate = debt?.dueDate;
    _selectedWalletId = debt?.walletId;
    _reminderEnabled = debt?.reminderEnabled ?? false;

    _personNameController = TextEditingController(text: debt?.personName ?? '');
    _personPhoneController = TextEditingController(
      text: debt?.personPhone ?? '',
    );
    _amountController = TextEditingController(
      text: debt == null ? '' : _formatAmount(debt.originalAmount),
    );
    _descriptionController = TextEditingController(
      text: debt?.description ?? '',
    );
    _noteController = TextEditingController(text: debt?.note ?? '');
    _interestRateController = TextEditingController(
      text: debt == null || !debt.isEMI
          ? ''
          : _formatPlainNumber(debt.annualInterestRate),
    );
    _installmentCountController = TextEditingController(
      text: debt == null || !debt.isEMI || debt.totalInstallments <= 0
          ? ''
          : debt.totalInstallments.toString(),
    );
    _installmentDayController = TextEditingController(
      text: debt == null || !debt.isEMI || debt.installmentDayOfMonth == null
          ? ''
          : debt.installmentDayOfMonth.toString(),
    );

    for (final controller in [
      _amountController,
      _interestRateController,
      _installmentCountController,
      _installmentDayController,
    ]) {
      controller.addListener(_onPreviewChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _amountController,
      _interestRateController,
      _installmentCountController,
      _installmentDayController,
    ]) {
      controller.removeListener(_onPreviewChanged);
    }
    _personNameController.dispose();
    _personPhoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    _interestRateController.dispose();
    _installmentCountController.dispose();
    _installmentDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final previewEmiAmount = _previewEmiAmount;
    final previewTotalPayable = _previewTotalPayable;
    final previewInterest = previewTotalPayable - _parsedPrincipal;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DebtTypeSelector(
            selectedType: _selectedType,
            onChanged: (type) {
              setState(() {
                _selectedType = type;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _EmiToggleCard(
            value: _isEMI,
            onChanged: (value) {
              setState(() {
                _isEMI = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'সম্পাদনায় মূল টাকার পরিমাণের ব্যালেন্স স্বয়ংক্রিয়ভাবে বদলাবে না।',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          TextFormField(
            controller: _personNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: _isEMI ? 'প্রতিষ্ঠান / নাম' : 'নাম',
              hintText: _isEMI ? 'প্রতিষ্ঠানের নাম' : 'কার সাথে?',
            ),
            validator: (value) {
              if ((value?.trim() ?? '').isEmpty) {
                return _isEMI ? 'প্রতিষ্ঠানের নাম লিখুন' : 'নাম লিখুন';
              }
              return null;
            },
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            child: !_isEMI
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: TextFormField(
                      controller: _personPhoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'ফোন নম্বর',
                        hintText: 'ফোন নম্বর (ঐচ্ছিক)',
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _amountController,
            readOnly: _isEditing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.titleLarge.copyWith(
              color: _isEMI
                  ? context.appColors.primary
                  : _selectedType.accentColor,
            ),
            decoration: InputDecoration(
              labelText: 'মোট পরিমাণ',
              hintText: '০',
              prefixText: '৳ ',
              helperText: _isEditing
                  ? 'মূল পরিমাণ পরিবর্তন করা যাবে না'
                  : 'শুরুতে যত টাকা লেনদেন হয়েছে',
              filled: true,
              fillColor:
                  (_isEMI
                          ? context.appColors.primary
                          : _selectedType.accentColor)
                      .withValues(alpha: 0.08),
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null || amount <= 0) {
                return 'সঠিক টাকার পরিমাণ দিন';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'বিবরণ',
              hintText: 'কিসের জন্য?',
            ),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            child: _isEMI
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _interestRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'সুদের হার',
                            hintText: 'বার্ষিক সুদের হার (০% হলে ফাঁকা রাখুন)',
                            suffixText: '%',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _installmentCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'কিস্তির সংখ্যা',
                            hintText: 'কত মাসে? (e.g., 12, 24, 36)',
                          ),
                          validator: (value) {
                            if (!_isEMI) {
                              return null;
                            }
                            final months = int.tryParse(value?.trim() ?? '');
                            if (months == null || months <= 0) {
                              return 'কত মাসে কিস্তি হবে, সেটি দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _installmentDayController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'মাসের তারিখ',
                            hintText: 'মাসের কোন তারিখে কিস্তি?',
                          ),
                          validator: (value) {
                            if (!_isEMI) {
                              return null;
                            }
                            final day = int.tryParse(value?.trim() ?? '');
                            if (day == null || day < 1 || day > 31) {
                              return '১ থেকে ৩১ এর মধ্যে তারিখ দিন';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          elevation: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'মাসিক কিস্তি',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.secondaryTextColor,
                                      ),
                                    ),
                                  ),
                                  if (_parsedAnnualRate <= 0)
                                    AppChip(
                                      label: 'সুদমুক্ত কিস্তি',
                                      color: AppColors.success,
                                      compact: true,
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                previewEmiAmount == null
                                    ? 'তথ্য পূরণ করলে দেখা যাবে'
                                    : BanglaFormatters.currency(
                                        previewEmiAmount,
                                      ),
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: context.appColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (previewEmiAmount != null &&
                                  previewTotalPayable > 0) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'মোট পরিশোধ: ${BanglaFormatters.currency(previewTotalPayable)} (সুদ: ${BanglaFormatters.currency(math.max(0, previewInterest))})',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: context.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _DateSelectorField(
                      label: 'পরিশোধের তারিখ',
                      value: _selectedDueDate == null
                          ? 'পরিশোধের তারিখ (ঐচ্ছিক)'
                          : BanglaFormatters.fullDate(_selectedDueDate!),
                      onTap: _pickDueDate,
                      onClear: _selectedDueDate == null
                          ? null
                          : () {
                              setState(() {
                                _selectedDueDate = null;
                              });
                            },
                    ),
                  ),
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
          const SizedBox(height: AppSpacing.sm),
          Text(
            'এই টাকা কোন ওয়ালেট থেকে গেছে বা কোন ওয়ালেটে এসেছে',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: _reminderEnabled,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _isEMI
                ? context.appColors.primary
                : _selectedType.accentColor,
            title: Text(
              'মনে করিয়ে দিন',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
              ),
            ),
            subtitle: Text(
              _isEMI
                  ? 'পরবর্তী কিস্তির আগে রিমাইন্ডার দেওয়া হবে'
                  : 'পরিশোধের তারিখের আগে রিমাইন্ডার দেওয়া হবে',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _reminderEnabled = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'নোট',
              hintText: 'অতিরিক্ত তথ্য',
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppActionButton(
            label: 'সংরক্ষণ করুন',
            icon: Icons.check_rounded,
            fullWidth: true,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  double get _parsedPrincipal =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  double get _parsedAnnualRate =>
      double.tryParse(_interestRateController.text.trim()) ?? 0;

  int get _parsedInstallmentCount =>
      int.tryParse(_installmentCountController.text.trim()) ?? 0;

  double? get _previewEmiAmount {
    if (!_isEMI || _parsedPrincipal <= 0 || _parsedInstallmentCount <= 0) {
      return null;
    }
    return EmiCalculator.calculateEMI(
      principal: _parsedPrincipal,
      annualRate: _parsedAnnualRate,
      months: _parsedInstallmentCount,
    );
  }

  double get _previewTotalPayable {
    final emiAmount = _previewEmiAmount;
    if (emiAmount == null) {
      return 0;
    }
    return emiAmount * _parsedInstallmentCount;
  }

  void _onPreviewChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    final initialDate = _selectedDueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDueDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = _parsedPrincipal;
    final now = DateTime.now();
    final existingDebt = widget.existingDebt;
    final debt = DebtEntity(
      id: existingDebt?.id ?? 0,
      personName: _personNameController.text.trim(),
      personPhone: _isEMI ? null : _normalizeText(_personPhoneController.text),
      type: _selectedType,
      originalAmount: amount,
      remainingAmount:
          existingDebt?.remainingAmount ??
          (_isEMI ? _previewTotalPayable : amount),
      description: _normalizeText(_descriptionController.text),
      category: existingDebt?.category,
      walletId: _selectedWalletId,
      status: existingDebt?.status ?? DebtStatus.active,
      createdAt: existingDebt?.createdAt ?? now,
      dueDate: _isEMI ? null : _selectedDueDate,
      settledAt: existingDebt?.settledAt,
      note: _normalizeText(_noteController.text),
      reminderEnabled: _reminderEnabled,
      isEMI: _isEMI,
      annualInterestRate: _isEMI ? _parsedAnnualRate : 0,
      totalInstallments: _isEMI ? _parsedInstallmentCount : 0,
      paidInstallments: existingDebt?.paidInstallments ?? 0,
      emiAmount: _isEMI
          ? (_previewEmiAmount ?? existingDebt?.emiAmount ?? 0)
          : 0,
      nextInstallmentDate: existingDebt?.nextInstallmentDate,
      installmentDayOfMonth: _isEMI
          ? int.tryParse(_installmentDayController.text.trim())
          : null,
    );

    setState(() {
      _isSaving = true;
    });

    final result = _isEditing
        ? await ref.read(debtMutationControllerProvider).updateDebt(debt)
        : await ref
              .read(debtMutationControllerProvider)
              .saveDebt(debt, walletId: _selectedWalletId);

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

  String _formatPlainNumber(double value) {
    final hasFraction = (value - value.round()).abs() >= 0.01;
    return hasFraction ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
  }
}

class _DebtTypeSelector extends StatelessWidget {
  const _DebtTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final DebtType selectedType;
  final ValueChanged<DebtType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DebtTypeCard(
            type: DebtType.theyOwe,
            selected: selectedType == DebtType.theyOwe,
            onTap: () => onChanged(DebtType.theyOwe),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DebtTypeCard(
            type: DebtType.iOwe,
            selected: selectedType == DebtType.iOwe,
            onTap: () => onChanged(DebtType.iOwe),
          ),
        ),
      ],
    );
  }
}

class _DebtTypeCard extends StatelessWidget {
  const _DebtTypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DebtType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = type.accentColor;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardAll,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: AppRadius.cardAll,
          border: Border.all(
            color: selected ? accent : accent.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              type.directionIcon,
              color: selected ? Colors.white : accent,
              size: 22,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              type.selectorTitleBn,
              style: AppTextStyles.titleMedium.copyWith(
                color: selected ? Colors.white : context.primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.selectorSubtitleBn,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmiToggleCard extends StatelessWidget {
  const _EmiToggleCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevation: 1,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.appColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.cardAll,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.calendar_month_rounded,
              color: context.appColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কিস্তি / EMI',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'চালু করলে মাসিক কিস্তি, সুদ ও তারিখ ট্র্যাক হবে',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DateSelectorField extends StatelessWidget {
  const _DateSelectorField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(AppRadius.input),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: context.mutedSurfaceColor,
              borderRadius: const BorderRadius.all(AppRadius.input),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: context.secondaryTextColor,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: context.secondaryTextColor,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.secondaryTextColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
