import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/income_source.dart';
import '../providers/income_providers.dart';

Future<bool?> showAddEditIncomeSheet(
  BuildContext context, {
  IncomeEntity? existingIncome,
}) {
  final isEditing = existingIncome != null;

  return AppBottomSheet.show<bool>(
    context: context,
    title: isEditing ? 'আয় সম্পাদনা করুন' : 'আয় যোগ করুন',
    scrollable: true,
    maxHeightFactor: 0.92,
    child: AddEditIncomeSheet(existingIncome: existingIncome),
  );
}

class AddEditIncomeSheet extends ConsumerStatefulWidget {
  const AddEditIncomeSheet({super.key, this.existingIncome});

  final IncomeEntity? existingIncome;

  @override
  ConsumerState<AddEditIncomeSheet> createState() => _AddEditIncomeSheetState();
}

class _AddEditIncomeSheetState extends ConsumerState<AddEditIncomeSheet> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSource;
  int? _selectedWalletId;
  bool _isRecurring = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingIncome;
    if (existing != null) {
      _amountController.text = _formatNumber(existing.amount);
      _descriptionController.text = existing.description;
      _noteController.text = existing.note ?? '';
      _selectedDate = existing.date;
      _selectedSource = existing.source;
      _selectedWalletId = existing.walletId;
      _isRecurring = existing.isRecurring;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final selectedSource = _selectedSource;
    final sources = defaultIncomeSources;

    return AppStaggeredList(
      children: [
        _IncomeAmountFieldCard(controller: _amountController),
        const SizedBox(height: AppSpacing.sectionGap),
        _FormSection(
          title: 'আয়ের উৎস',
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sources.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final source = sources[index];
                final selected = source.name == selectedSource;
                return AppChip(
                  label: source.banglaLabel,
                  emoji: source.emoji,
                  color: AppColors.success,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedSource = source.name;
                    });
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _FormSection(
          title: 'বিবরণ',
          child: TextField(
            controller: _descriptionController,
            maxLength: 100,
            maxLines: 3,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.primaryTextColor,
            ),
            decoration: _inputDecoration(
              context,
              hintText: 'যেমন: মাসিক বেতন, ক্লায়েন্ট পেমেন্ট',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _FormSection(
          title: 'তারিখ',
          child: _DateSelectorRow(date: _selectedDate, onTap: _pickDate),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _FormSection(
          title: 'ওয়ালেট',
          child: WalletSelectorWidget(
            selectedWalletId: effectiveWalletId,
            onChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _RecurringToggleCard(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _FormSection(
          title: 'নোট',
          child: TextField(
            controller: _noteController,
            maxLength: 200,
            minLines: 2,
            maxLines: 4,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.primaryTextColor,
            ),
            decoration: _inputDecoration(
              context,
              hintText: 'অতিরিক্ত কিছু যোগ করতে পারেন',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppActionButton(
          label: 'সংরক্ষণ করুন',
          icon: Icons.check_rounded,
          variant: AppActionButtonVariant.success,
          onPressed: _isSaving ? null : _save,
          isLoading: _isSaving,
          fullWidth: true,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _save() async {
    final parsedAmount = _parseAmount(_amountController.text.trim());
    final source = _selectedSource;
    final selectedWalletId =
        _selectedWalletId ?? ref.read(activeWalletProvider)?.id;

    if (parsedAmount == null || parsedAmount <= 0) {
      _showMessage('সঠিক পরিমাণ লিখুন');
      return;
    }
    if (source == null || source.trim().isEmpty) {
      _showMessage('একটি উৎস নির্বাচন করুন');
      return;
    }
    if (selectedWalletId == null) {
      _showMessage('একটি ওয়ালেট বেছে নিন');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final description = _descriptionController.text.trim();
    final note = _noteController.text.trim();
    final existing = widget.existingIncome;
    final income = IncomeEntity(
      id: existing?.id,
      amount: parsedAmount,
      source: source,
      description: description,
      date: _selectedDate,
      walletId: selectedWalletId,
      isRecurring: _isRecurring,
      isManual: true,
      note: note.isEmpty ? null : note,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    String? error;
    if (existing == null) {
      error = await ref
          .read(incomeMutationControllerProvider)
          .saveManualIncome(income, walletId: selectedWalletId);
    } else {
      error = await ref
          .read(incomeMutationControllerProvider)
          .updateIncome(income, existing);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatNumber(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  double? _parseAmount(String? raw) {
    final input = (raw ?? '').trim();
    if (input.isEmpty) {
      return null;
    }
    final normalized = input
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll('٫', '.')
        .replaceAll('৳', '')
        .replaceAll(' ', '')
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9');
    final cleaned = normalized.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: context.primaryTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _IncomeAmountFieldCard extends StatelessWidget {
  const _IncomeAmountFieldCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            'পরিমাণ',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '৳',
                style: AppTextStyles.heroAmount.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroAmount.copyWith(
                    color: AppColors.success,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSelectorRow extends StatelessWidget {
  const _DateSelectorRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                BanglaFormatters.fullDate(date),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
            ),
            Text(
              'পরিবর্তন করুন',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringToggleCard extends StatelessWidget {
  const _RecurringToggleCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'নিয়মিত আয়',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'মাসিক বেতন বা নিয়মিত ইনকাম হলে চালু রাখুন',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.success.withValues(alpha: 0.4),
            activeThumbColor: AppColors.success,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hintText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: context.hintTextColor),
    filled: true,
    fillColor: context.mutedSurfaceColor,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(AppRadius.input),
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(AppRadius.input),
      borderSide: BorderSide.none,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(AppRadius.input),
      borderSide: BorderSide(color: AppColors.success),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
  );
}
