import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/income_data.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';

class IncomeConfirmationWidget extends ConsumerStatefulWidget {
  const IncomeConfirmationWidget({
    super.key,
    required this.income,
    required this.onSave,
    required this.onCancel,
  });

  final IncomeData income;
  final Future<void> Function(IncomeData income, int? walletId) onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<IncomeConfirmationWidget> createState() =>
      _IncomeConfirmationWidgetState();
}

class _IncomeConfirmationWidgetState
    extends ConsumerState<IncomeConfirmationWidget> {
  late IncomeData _income = widget.income;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  int? _selectedWalletId;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _formatNumber(_income.amount),
    );
    _descriptionController =
        TextEditingController(text: _income.description);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final source = findIncomeSourceByName(_income.source);
    final label = source?.banglaLabel ?? _income.source;
    final emoji = source?.emoji ?? '💰';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
        ),
        child: Card(
          elevation: 0,
          color: context.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: context.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDate,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.mutedSurfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _income.displayDate,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (_income.isPastDate) ...[
                          const _DateBadge(label: 'অতীত'),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.edit_calendar_rounded,
                          size: 16,
                          color: context.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_income.isFutureDate) ...[
                  const SizedBox(height: 10),
                  const _InfoBanner(
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: Color(0xFFF0FDF4),
                    borderColor: Color(0xFFBBF7D0),
                    textColor: Color(0xFF15803D),
                    text: 'এটা ভবিষ্যতের তারিখ। নিশ্চিত?',
                  ),
                ],
                if (_income.dateFallbackNote != null) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    backgroundColor: context.mutedSurfaceColor,
                    borderColor: context.borderColor,
                    textColor: context.secondaryTextColor,
                    text: _income.dateFallbackNote!,
                  ),
                ],
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  maxLength: 100,
                  onChanged: (value) {
                    _income = _income.copyWith(description: value.trim());
                  },
                  decoration: const InputDecoration(
                    labelText: 'বিবরণ',
                    hintText: 'কোন আয় এসেছে?',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    final parsed = _parseAmount(value);
                    if (parsed != null) {
                      _income = _income.copyWith(amount: parsed);
                    }
                  },
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'পরিমাণ (টাকা)',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 16),
                WalletSelectorWidget(
                  selectedWalletId: effectiveWalletId,
                  onChanged: (walletId) {
                    setState(() {
                      _selectedWalletId = walletId;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_isSaved)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'আয় সংরক্ষণ হয়েছে',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text(AppStrings.cancelButton),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving
                              ? null
                              : () => _save(effectiveWalletId),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(AppStrings.saveButton),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _income.parsedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _income = _income.copyWith(
        date: _formatIsoDate(pickedDate),
      );
    });
  }

  Future<void> _save(int? walletId) async {
    if (_isSaved) {
      return;
    }

    final parsedAmount = _parseAmount(_amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      _showMessage('সঠিক পরিমাণ লিখুন');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final normalized = _income.copyWith(
      amount: parsedAmount,
      description: _descriptionController.text.trim(),
    );
    await widget.onSave(normalized, walletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.borderColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: context.secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.text,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
