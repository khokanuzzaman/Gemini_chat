import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/income_data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import 'chat_confirmation_primitives.dart';

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
    _descriptionController = TextEditingController(text: _income.description);
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
    final description = _descriptionController.text.trim().isEmpty
        ? (_income.description.trim().isEmpty
              ? 'আয়'
              : _income.description.trim())
        : _descriptionController.text.trim();
    final amountPreview =
        _parseAmount(_amountController.text) ?? _income.amount;

    return ChatConfirmationCardShell(
      accentColor: AppColors.success,
      maxWidthFactor: 0.84,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: AppRadius.cardAll,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChatConfirmationIconCircle(
                    emoji: emoji,
                    tintColor: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$label • ${BanglaFormatters.fullDate(_income.parsedDate)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                        if (_income.dateFallbackNote != null)
                          ChatConfirmationNoteChip(
                            note: _income.dateFallbackNote!,
                          ),
                        if (_income.isFutureDate)
                          const ChatConfirmationNoteChip(
                            note: 'তারিখটি ভবিষ্যতের',
                            tintColor: AppColors.warning,
                            icon: Icons.warning_amber_rounded,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppAmountText(
                    amount: amountPreview,
                    style: AppTextStyles.titleLarge,
                    isIncome: true,
                    showSign: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ChatConfirmationMutedBox(
            child: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  maxLength: 100,
                  onChanged: (value) {
                    setState(() {
                      _income = _income.copyWith(description: value.trim());
                      _isSaved = false;
                    });
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
                    setState(() {
                      if (parsed != null) {
                        _income = _income.copyWith(amount: parsed);
                      }
                      _isSaved = false;
                    });
                  },
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.success,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'পরিমাণ (টাকা)',
                    prefixText: '৳ ',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WalletSelectorWidget(
            label: null,
            selectedWalletId: effectiveWalletId,
            onChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
                _isSaved = false;
              });
            },
          ),
          const SizedBox(height: 12),
          ChatConfirmationActionSwitcher(
            isSaved: _isSaved,
            unsavedChild: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ChatActionButton(
                    label: 'এডিট',
                    icon: Icons.edit_outlined,
                    variant: AppActionButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: _isSaving ? null : widget.onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ChatActionButton(
                    label: 'সংরক্ষণ করুন',
                    icon: Icons.check_rounded,
                    variant: AppActionButtonVariant.success,
                    fullWidth: true,
                    isLoading: _isSaving,
                    onPressed: () => _save(effectiveWalletId),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      _income = _income.copyWith(date: _formatIsoDate(pickedDate));
      _isSaved = false;
    });
  }

  Future<void> _save(int? walletId) async {
    if (_isSaved || _isSaving) {
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
