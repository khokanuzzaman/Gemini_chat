import 'package:flutter/material.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';

class ExpenseConfirmationWidget extends StatefulWidget {
  const ExpenseConfirmationWidget({
    super.key,
    required this.expense,
    required this.onSave,
    required this.onCancel,
  });

  final ExpenseData expense;
  final Future<void> Function(ExpenseData expense) onSave;
  final VoidCallback onCancel;

  @override
  State<ExpenseConfirmationWidget> createState() =>
      _ExpenseConfirmationWidgetState();
}

class _ExpenseConfirmationWidgetState extends State<ExpenseConfirmationWidget> {
  late ExpenseData _expense = widget.expense;

  @override
  Widget build(BuildContext context) {
    final categoryMeta = resolveExpenseCategory(_expense.category);

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
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
                            _expense.displayDate,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (_expense.isPastDate) ...[
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
                if (_expense.isFutureDate) ...[
                  const SizedBox(height: 10),
                  const _InfoBanner(
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: Color(0xFFFFF7ED),
                    borderColor: Color(0xFFFED7AA),
                    textColor: Color(0xFFB45309),
                    text: 'এটা ভবিষ্যতের তারিখ। নিশ্চিত?',
                  ),
                ],
                if (_expense.dateFallbackNote != null) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    backgroundColor: context.mutedSurfaceColor,
                    borderColor: context.borderColor,
                    textColor: context.secondaryTextColor,
                    text: _expense.dateFallbackNote!,
                  ),
                ],
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: categoryMeta.color.withValues(alpha: 0.14),
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
                        Icon(
                          categoryMeta.icon,
                          size: 18,
                          color: categoryMeta.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _expense.category,
                          style: TextStyle(
                            color: categoryMeta.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _expense.description.trim().isEmpty
                      ? 'খরচ'
                      : _expense.description.trim(),
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  BanglaFormatters.currency(_expense.amount),
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
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
                        onPressed: () => widget.onSave(_expense),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: const Text(AppStrings.saveButton),
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
      initialDate: _expense.parsedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expense = _expense.copyWith(date: _formatIsoDate(pickedDate));
    });
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
