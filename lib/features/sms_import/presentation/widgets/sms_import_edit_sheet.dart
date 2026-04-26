import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sms/sms_import_result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';
import '../../../income/domain/entities/income_source.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../models/sms_import_models.dart';

Future<SmsImportDraft?> showSmsImportEditSheet(
  BuildContext context, {
  required SmsImportCandidate candidate,
  required SmsImportDraft draft,
}) {
  return AppBottomSheet.show<SmsImportDraft>(
    context: context,
    title: candidate.isExpense ? 'খরচ সম্পাদনা করুন' : 'আয় সম্পাদনা করুন',
    subtitle: candidate.transaction.sourceLabel,
    maxHeightFactor: 0.94,
    child: _SmsImportEditSheet(candidate: candidate, initialDraft: draft),
  );
}

class _SmsImportEditSheet extends ConsumerStatefulWidget {
  const _SmsImportEditSheet({
    required this.candidate,
    required this.initialDraft,
  });

  final SmsImportCandidate candidate;
  final SmsImportDraft initialDraft;

  @override
  ConsumerState<_SmsImportEditSheet> createState() =>
      _SmsImportEditSheetState();
}

class _SmsImportEditSheetState extends ConsumerState<_SmsImportEditSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late SmsImportDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _amountController = TextEditingController(
      text: _formatAmount(widget.initialDraft.amount),
    );
    _descriptionController = TextEditingController(
      text: widget.initialDraft.description,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final categoryNames = categories
        .map((category) => category.name)
        .toList(growable: false);
    final currentCategory = categoryNames.contains(_draft.category)
        ? _draft.category
        : (categoryNames.contains('Other')
              ? 'Other'
              : categoryNames.firstOrNull);
    final currentIncomeSource =
        findIncomeSourceByName(_draft.incomeSource ?? '')?.name ?? 'Other';

    if (_draft.isExpense && currentCategory != _draft.category) {
      _draft = _draft.copyWith(category: currentCategory);
    }
    if (_draft.isIncome && currentIncomeSource != _draft.incomeSource) {
      _draft = _draft.copyWith(incomeSource: currentIncomeSource);
    }

    return AppStaggeredList(
      children: [
        _SectionBlock(
          title: 'পরিমাণ',
          child: TextField(
            key: const Key('sms-import-edit-amount'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTextStyles.heroAmount.copyWith(
              color: _draft.isIncome
                  ? AppColors.success
                  : context.primaryTextColor,
              fontSize: 28,
            ),
            decoration: _fieldDecoration(
              context,
              hintText: '৳ 0',
              prefixText: '৳ ',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionBlock(
          title: 'বিবরণ',
          child: TextField(
            key: const Key('sms-import-edit-description'),
            controller: _descriptionController,
            maxLength: 100,
            maxLines: 3,
            style: AppTextStyles.bodyLarge.copyWith(
              color: context.primaryTextColor,
            ),
            decoration: _fieldDecoration(context, hintText: 'বিবরণ লিখুন'),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionBlock(
          title: 'তারিখ',
          child: _DateSelectorRow(date: _draft.date, onTap: _pickDate),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        if (_draft.isExpense) ...[
          _SectionBlock(
            title: 'ক্যাটাগরি',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in categoryNames)
                  AppChip(
                    label: category,
                    color: resolveExpenseCategory(category).color,
                    selected: _draft.category == category,
                    onTap: () {
                      setState(() {
                        _draft = _draft.copyWith(category: category);
                      });
                    },
                  ),
              ],
            ),
          ),
        ] else ...[
          _SectionBlock(
            title: 'আয়ের উৎস',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final source in defaultIncomeSources)
                  AppChip(
                    label: source.banglaLabel,
                    emoji: source.emoji,
                    color: AppColors.success,
                    selected: _draft.incomeSource == source.name,
                    onTap: () {
                      setState(() {
                        _draft = _draft.copyWith(incomeSource: source.name);
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        _SectionBlock(
          title: 'ওয়ালেট',
          child: WalletSelectorWidget(
            selectedWalletId: _draft.walletId,
            onChanged: (walletId) {
              setState(() {
                _draft = _draft.copyWith(walletId: walletId);
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Raw SMS দেখুন',
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.primaryTextColor,
                ),
              ),
              subtitle: Text(
                '${widget.candidate.sms.address} · ${BanglaFormatters.time(widget.candidate.sms.date)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.mutedSurfaceColor,
                    borderRadius: const BorderRadius.all(AppRadius.card),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: SelectableText(
                    widget.candidate.sms.body,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.primaryTextColor,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppActionButton(
          key: const Key('sms-import-edit-save'),
          label: 'আপডেট করুন',
          icon: Icons.check_rounded,
          fullWidth: true,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(
        date: DateTime(
          picked.year,
          picked.month,
          picked.day,
          _draft.date.hour,
          _draft.date.minute,
          _draft.date.second,
        ),
      );
    });
  }

  void _save() {
    final amount = _parseAmount(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('সঠিক পরিমাণ লিখুন');
      return;
    }

    final description = _descriptionController.text.trim();
    final updatedDraft = _draft.copyWith(
      amount: amount,
      description: description,
    );
    Navigator.of(context).pop(updatedDraft);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatAmount(double amount) {
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

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.child});

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

class _DateSelectorRow extends StatelessWidget {
  const _DateSelectorRow({required this.date, required this.onTap});

  final DateTime date;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(AppRadius.card),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.mutedSurfaceColor,
          borderRadius: const BorderRadius.all(AppRadius.card),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: context.secondaryTextColor,
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
            Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: context.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String hintText,
  String? prefixText,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixText: prefixText,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: context.hintTextColor),
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
