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
    final totalAmount = _displayIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final selectedCount = _selectedIncomes.length;
    final selectedTotal = _selectedIncomes.fold<double>(
      0,
      (sum, income) => sum + income.amount,
    );
    final hasFutureDates = _displayIncomes.any((income) => income.isFutureDate);
    final hasInvalidDates = _displayIncomes.any(
      (income) => income.hasInvalidDate,
    );

    return ChatConfirmationCardShell(
      accentColor: AppColors.success,
      maxWidthFactor: 0.90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ChatConfirmationIconCircle(
                icon: Icons.list_alt_rounded,
                tintColor: AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${BanglaFormatters.count(_displayIncomes.length)}টি আয় পাওয়া গেছে',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.primaryTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppAmountText(
                amount: totalAmount,
                style: AppTextStyles.titleLarge,
                isIncome: true,
                showSign: true,
              ),
            ],
          ),
          if (_hasOverflow) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.info_outline_rounded,
              text: 'অনেক বেশি item। প্রথম ১০টা দেখানো হচ্ছে।',
              backgroundColor: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
              foregroundColor: Color(0xFF15803D),
            ),
          ],
          if (hasInvalidDates) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'কিছু item-এর তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে। চাইলে বদলান।',
              backgroundColor: Color(0xFFF8FAFC),
              borderColor: Color(0xFFE2E8F0),
              foregroundColor: Color(0xFF475569),
            ),
          ],
          if (hasFutureDates) ...[
            const SizedBox(height: 12),
            const ChatConfirmationBanner(
              icon: Icons.warning_amber_rounded,
              text: 'এখানে ভবিষ্যতের তারিখ আছে। নিশ্চিত?',
              backgroundColor: Color(0xFFF0FDF4),
              borderColor: Color(0xFFBBF7D0),
              foregroundColor: Color(0xFF15803D),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: AppRadius.cardAll,
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                for (var index = 0; index < _displayIncomes.length; index++)
                  Column(
                    children: [
                      _IncomeRow(
                        income: _displayIncomes[index],
                        checked: _checked[index],
                        onTap: () {
                          setState(() {
                            _checked[index] = !_checked[index];
                            _isSaved = false;
                          });
                        },
                      ),
                      if (index != _displayIncomes.length - 1)
                        Divider(
                          height: 1,
                          color: context.borderColor.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ChatConfirmationMutedBox(
            child: Row(
              children: [
                Text(
                  '${BanglaFormatters.count(selectedCount)}টি নির্বাচিত',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'মোট:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 6),
                AppAmountText(
                  amount: selectedTotal,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  isIncome: true,
                  showSign: true,
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
            unsavedChild: ChatActionButton(
              label: 'সব সংরক্ষণ করুন',
              icon: Icons.check_rounded,
              variant: AppActionButtonVariant.success,
              fullWidth: true,
              enabled: selectedCount > 0,
              isLoading: _isSaving,
              onPressed: () => _save(effectiveWalletId),
            ),
          ),
        ],
      ),
    );
  }

  List<IncomeData> get _selectedIncomes {
    final selected = <IncomeData>[];
    for (var index = 0; index < _displayIncomes.length; index++) {
      if (_checked[index]) {
        selected.add(_displayIncomes[index]);
      }
    }
    return selected;
  }

  Future<void> _save(int? walletId) async {
    if (_isSaved || _isSaving || _selectedIncomes.isEmpty) {
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
    required this.onTap,
  });

  final IncomeData income;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = findIncomeSourceByName(income.source);
    final label = source?.banglaLabel ?? income.source;
    final emoji = source?.emoji ?? '💰';
    final description = income.description.trim().isEmpty
        ? label
        : income.description.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              ChatSelectionCheckbox(checked: checked, color: AppColors.success),
              const SizedBox(width: 12),
              ChatConfirmationIconCircle(
                emoji: emoji,
                tintColor: AppColors.success,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label • ${BanglaFormatters.fullDate(income.parsedDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppAmountText(
                amount: income.amount,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                isIncome: true,
                showSign: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
