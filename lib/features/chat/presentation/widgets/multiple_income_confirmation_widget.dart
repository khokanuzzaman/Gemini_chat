import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/income_data.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import 'chat_card_primitives.dart';

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
    final selectedIncomes = _selectedIncomes;
    final selectedTotal = selectedIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final hasFutureDates = _displayIncomes.any((income) => income.isFutureDate);
    final hasInvalidDates = _displayIncomes.any((income) => income.hasInvalidDate);

    return ChatDataCardShell(
      accentColor: AppColors.success,
      maxWidthFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChatCardHeader(
            icon: Icons.savings_rounded,
            title: 'একাধিক আয় draft',
            subtitle: 'যেগুলো রাখতে চান সেগুলো বেছে নিন',
            accentColor: AppColors.success,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChatStatChip(
                icon: Icons.receipt_long_rounded,
                label: '${BanglaFormatters.count(_displayIncomes.length)}টি আয়',
                accentColor: AppColors.success,
              ),
              ChatStatChip(
                icon: Icons.payments_rounded,
                label: BanglaFormatters.currency(selectedTotal),
                accentColor: AppColors.success,
              ),
            ],
          ),
          if (_hasOverflow) ...[
            const SizedBox(height: 12),
            const ChatInfoBanner(
              icon: Icons.info_outline_rounded,
              text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
              backgroundColor: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
              textColor: Color(0xFF15803D),
            ),
          ],
          if (hasInvalidDates) ...[
            const SizedBox(height: 12),
            const ChatInfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
              backgroundColor: Color(0xFFF8FAFC),
              borderColor: Color(0xFFE2E8F0),
              textColor: Color(0xFF475569),
            ),
          ],
          if (hasFutureDates) ...[
            const SizedBox(height: 12),
            const ChatInfoBanner(
              icon: Icons.warning_amber_rounded,
              text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
              backgroundColor: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
              textColor: Color(0xFF15803D),
            ),
          ],
          const SizedBox(height: 14),
          ChatSectionSurface(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: _displayIncomes.length > 4 ? 320 : 220,
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
          ),
          const SizedBox(height: 14),
          ChatSectionSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কোন wallet-এ যাবে',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                WalletSelectorWidget(
                  selectedWalletId: effectiveWalletId,
                  onChanged: (walletId) {
                    setState(() {
                      _selectedWalletId = walletId;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_isSaved)
            const ChatInfoBanner(
              icon: Icons.check_circle_rounded,
              text: 'আয় সংরক্ষণ হয়েছে',
              backgroundColor: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
              textColor: Color(0xFF15803D),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChatStatChip(
                  icon: Icons.checklist_rounded,
                  label: '${BanglaFormatters.count(selectedIncomes.length)}টি বাছাই',
                  accentColor: AppColors.success,
                ),
                ChatStatChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'মোট ${BanglaFormatters.currency(selectedTotal)}',
                  accentColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving || selectedIncomes.isEmpty
                        ? null
                        : () => _save(effectiveWalletId),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.saveButton),
                  ),
                ),
              ],
            ),
          ],
        ],
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
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: context.isDarkMode ? 0.28 : 0.14,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: checked, onChanged: onChanged),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        income.description.trim().isEmpty
                            ? label
                            : income.description.trim(),
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      BanglaFormatters.currency(income.amount),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      income.displayDate,
                      style: AppTextStyles.caption.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
