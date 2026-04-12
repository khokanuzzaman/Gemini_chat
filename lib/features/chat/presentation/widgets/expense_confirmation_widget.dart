import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import 'chat_confirmation_primitives.dart';

class ExpenseConfirmationWidget extends ConsumerStatefulWidget {
  const ExpenseConfirmationWidget({
    super.key,
    required this.expense,
    required this.onSave,
    required this.onCancel,
  });

  final ExpenseData expense;
  final Future<void> Function(ExpenseData expense, int? walletId) onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<ExpenseConfirmationWidget> createState() =>
      _ExpenseConfirmationWidgetState();
}

class _ExpenseConfirmationWidgetState
    extends ConsumerState<ExpenseConfirmationWidget> {
  late ExpenseData _expense = widget.expense;
  int? _selectedWalletId;
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final categoryMeta = resolveExpenseCategory(_expense.category);
    final description = _expense.description.trim().isEmpty
        ? 'খরচ'
        : _expense.description.trim();

    return ChatConfirmationCardShell(
      accentColor: context.appColors.primary,
      maxWidthFactor: 0.82,
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
                    icon: categoryMeta.icon,
                    tintColor: categoryMeta.color,
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
                          '${_expense.category} • ${BanglaFormatters.fullDate(_expense.parsedDate)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                        if (_expense.dateFallbackNote != null)
                          ChatConfirmationNoteChip(
                            note: _expense.dateFallbackNote!,
                          ),
                        if (_expense.isFutureDate)
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
                    amount: _expense.amount,
                    style: AppTextStyles.titleLarge,
                    isExpense: true,
                  ),
                ],
              ),
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
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ChatActionButton(
                    label: 'সংরক্ষণ করুন',
                    icon: Icons.check_rounded,
                    variant: AppActionButtonVariant.primary,
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
      initialDate: _expense.parsedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expense = _expense.copyWith(date: _formatIsoDate(pickedDate));
      _isSaved = false;
    });
  }

  Future<void> _save(int? walletId) async {
    if (_isSaving || _isSaved) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.onSave(_expense, walletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isSaved = true;
    });
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
