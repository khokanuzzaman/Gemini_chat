import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/income_data.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';

class MultipleIncomeConfirmationWidget extends ConsumerStatefulWidget {
  const MultipleIncomeConfirmationWidget({
    super.key,
    required this.incomes,
    required this.onSave,
    required this.onCancel,
  });

  final List<IncomeData> incomes;
  final Future<void> Function(List<IncomeData> selectedIncomes, int? walletId)
  onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<MultipleIncomeConfirmationWidget> createState() =>
      _MultipleIncomeConfirmationWidgetState();
}

class _MultipleIncomeConfirmationWidgetState
    extends ConsumerState<MultipleIncomeConfirmationWidget> {
  late final List<bool> _checked;
  late List<IncomeData> _displayIncomes;
  int? _selectedWalletId;
  bool _isSaving = false;
  bool _isSaved = false;

  bool get _hasOverflow => widget.incomes.length > 10;

  @override
  void initState() {
    super.initState();
    _displayIncomes = widget.incomes.take(10).toList(growable: true);
    _checked = List<bool>.filled(_displayIncomes.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final selectedTotal = _selectedIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final hasFutureDates = _displayIncomes.any((income) => income.isFutureDate);
    final hasInvalidDates = _displayIncomes.any((income) => income.hasInvalidDate);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Card(
          elevation: 0,
          color: context.cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: context.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasOverflow)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.info_outline_rounded,
                      text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
                      backgroundColor: Color(0xFFF0FDF4),
                      borderColor: Color(0xFFBBF7D0),
                      textColor: Color(0xFF15803D),
                    ),
                  ),
                if (hasInvalidDates)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.info_outline_rounded,
                      text:
                          'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
                      backgroundColor: Color(0xFFF8FAFC),
                      borderColor: Color(0xFFE2E8F0),
                      textColor: Color(0xFF475569),
                    ),
                  ),
                if (hasFutureDates)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _Banner(
                      icon: Icons.warning_amber_rounded,
                      text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
                      backgroundColor: Color(0xFFF0FDF4),
                      borderColor: Color(0xFFBBF7D0),
                      textColor: Color(0xFF15803D),
                    ),
                  ),
                Text(
                  '${BanglaFormatters.count(_displayIncomes.length)}টি আয় পাওয়া গেছে',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _displayIncomes.length > 4 ? 300 : 200,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var index = 0; index < _displayIncomes.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _IncomeRow(
                              income: _displayIncomes[index],
                              checked: _checked[index],
                              onChanged: (value) {
                                setState(() {
                                  _checked[index] = value ?? false;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                WalletSelectorWidget(
                  selectedWalletId: effectiveWalletId,
                  onChanged: (walletId) {
                    setState(() {
                      _selectedWalletId = walletId;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 14),
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
                        child: Text(
                          'মোট: ${BanglaFormatters.currency(selectedTotal)}',
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isSaving ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: const Text(AppStrings.cancelButton),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isSaving || _selectedIncomes.isEmpty
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(AppStrings.saveButton),
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

  List<IncomeData> get _selectedIncomes {
    final selected = <IncomeData>[];
    for (var i = 0; i < _displayIncomes.length; i++) {
      if (_checked[i]) {
        selected.add(_displayIncomes[i]);
      }
    }
    return selected;
  }

  Future<void> _save(int? walletId) async {
    if (_isSaved) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.onSave(_selectedIncomes, walletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({
    required this.income,
    required this.checked,
    required this.onChanged,
  });

  final IncomeData income;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final source = findIncomeSourceByName(income.source);
    final label = source?.banglaLabel ?? income.source;
    final emoji = source?.emoji ?? '💰';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Checkbox(value: checked, onChanged: onChanged),
          const SizedBox(width: 4),
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  income.displayDate,
                  style: AppTextStyles.caption.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            BanglaFormatters.currency(income.amount),
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

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
