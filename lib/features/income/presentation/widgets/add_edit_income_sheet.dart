import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/income_source.dart';
import '../providers/income_providers.dart';

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

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existingIncome == null ? 'নতুন আয়' : 'আয় সম্পাদনা',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              autofocus: widget.existingIncome == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: 'পরিমাণ (টাকা)',
                prefixText: '৳ ',
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.success),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('উৎস নির্বাচন করুন', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sources.map((source) {
                  final selected = source.name == selectedSource;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${source.emoji} ${source.banglaLabel}'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedSource = source.name;
                        });
                      },
                      selectedColor: AppColors.success.withValues(alpha: 0.16),
                      labelStyle: TextStyle(
                        color:
                            selected ? AppColors.success : AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.success
                            : context.borderColor,
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'বিবরণ (optional)',
                hintText: 'যেমন: মাসিক বেতন, ক্লায়েন্ট পেমেন্ট',
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(BanglaFormatters.fullDate(_selectedDate)),
                    const Spacer(),
                    Text(
                      'পরিবর্তন করুন',
                      style: TextStyle(
                        color: context.appColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _isRecurring,
              contentPadding: EdgeInsets.zero,
              title: const Text('নিয়মিত আয়'),
              subtitle: const Text('মাসিক বেতন বা রেগুলার ইনকাম হলে'),
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: 200,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'নোট (optional)',
                hintText: 'অতিরিক্ত কিছু যোগ করতে পারেন',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('সংরক্ষণ করুন'),
              ),
            ),
          ],
        ),
      ),
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
      _showMessage(_messageForError(error));
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForError(Object error) {
    if (error is Failure) {
      return error.message;
    }
    return error.toString();
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
