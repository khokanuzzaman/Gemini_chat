import 'package:flutter/material.dart';

import '../../../../core/ai/expense_result.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../expense/presentation/utils/expense_category_meta.dart';

class ReceiptConfirmationWidget extends StatefulWidget {
  const ReceiptConfirmationWidget({
    super.key,
    required this.receiptData,
    required this.onSave,
    required this.onCancel,
  });

  final Map<String, dynamic> receiptData;
  final Future<void> Function(Map<String, dynamic> receiptData) onSave;
  final VoidCallback onCancel;

  @override
  State<ReceiptConfirmationWidget> createState() =>
      _ReceiptConfirmationWidgetState();
}

class _ReceiptConfirmationWidgetState extends State<ReceiptConfirmationWidget> {
  late DateTime _selectedDate;
  late bool _autoAdjustedToToday;
  late bool _hadInvalidDate;

  Map<String, dynamic> get _effectiveReceiptData {
    return {...widget.receiptData, 'date': _formatIsoDate(_selectedDate)};
  }

  @override
  void initState() {
    super.initState();
    final resolution = _resolveInitialDate(widget.receiptData['date']);
    _selectedDate = resolution.date;
    _autoAdjustedToToday = resolution.autoAdjustedToToday;
    _hadInvalidDate = resolution.hadInvalidDate;
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.receiptData['merchant'] as String? ?? 'Receipt';
    final category = widget.receiptData['category'] as String? ?? 'Other';
    final summary = widget.receiptData['summary'] as String? ?? '';
    final total = _normalizeAmount(widget.receiptData['total']);
    final items = (widget.receiptData['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final categoryMeta = resolveExpenseCategory(category);
    final isPastDate =
        !_isSameDay(_selectedDate, DateTime.now()) &&
        _stripTime(_selectedDate).isBefore(_stripTime(DateTime.now()));

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
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
                Text(
                  AppStrings.receiptDetected,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  merchant,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
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
                            BanglaFormatters.fullDate(_selectedDate),
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isPastDate) ...[
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
                if (_autoAdjustedToToday) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    backgroundColor: context.mutedSurfaceColor,
                    borderColor: context.borderColor,
                    textColor: context.secondaryTextColor,
                    text:
                        'Receipt date current monthের বাইরে ছিল, তাই আজকের তারিখ select করা হয়েছে। চাইলে বদলান।',
                  ),
                ] else if (_hadInvalidDate) ...[
                  const SizedBox(height: 10),
                  _InfoBanner(
                    icon: Icons.info_outline_rounded,
                    backgroundColor: context.mutedSurfaceColor,
                    borderColor: context.borderColor,
                    textColor: context.secondaryTextColor,
                    text:
                        'Receipt date বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে।',
                  ),
                ],
                if (summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ReceiptBadge(
                      icon: categoryMeta.icon,
                      label: category,
                      color: categoryMeta.color,
                    ),
                    _ReceiptBadge(
                      icon: Icons.shopping_cart_checkout_rounded,
                      label: '${items.length} item',
                      color: const Color(0xFF475569),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: context.mutedSurfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  items[index]['name'] as String? ?? 'Item',
                                  style: TextStyle(
                                    color: context.primaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                BanglaFormatters.currency(
                                  _normalizeAmount(items[index]['amount']),
                                ),
                                style: TextStyle(
                                  color: context.secondaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index != items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.borderColor,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.ragChipBackgroundColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'মোট',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        BanglaFormatters.currency(total),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => widget.onSave(_effectiveReceiptData),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: const Text(AppStrings.saveButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onCancel,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: const Text(AppStrings.cancelButton),
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
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = _stripTime(pickedDate);
      _autoAdjustedToToday = false;
      _hadInvalidDate = false;
    });
  }

  _ReceiptDateResolution _resolveInitialDate(Object? rawDate) {
    final today = _stripTime(DateTime.now());
    final dateText = (rawDate as String? ?? '').trim();

    if (dateText.isEmpty) {
      return _ReceiptDateResolution(
        date: today,
        autoAdjustedToToday: false,
        hadInvalidDate: true,
      );
    }

    final parsedDate = ExpenseData.parseDateValue(dateText);
    final parsedIso = _formatIsoDate(parsedDate);
    final parsedMonthMatchesCurrent =
        parsedDate.year == today.year && parsedDate.month == today.month;

    if (!parsedMonthMatchesCurrent) {
      return _ReceiptDateResolution(
        date: today,
        autoAdjustedToToday: true,
        hadInvalidDate: false,
      );
    }

    if (parsedIso == _formatIsoDate(today) && !_looksLikeToday(dateText)) {
      return _ReceiptDateResolution(
        date: today,
        autoAdjustedToToday: false,
        hadInvalidDate: true,
      );
    }

    return _ReceiptDateResolution(
      date: _stripTime(parsedDate),
      autoAdjustedToToday: false,
      hadInvalidDate: false,
    );
  }

  bool _looksLikeToday(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'today' || normalized == 'আজ' || normalized == 'আজকে';
  }

  double _normalizeAmount(Object? value) {
    return switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text) ?? 0,
      _ => 0,
    };
  }

  String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _ReceiptDateResolution {
  const _ReceiptDateResolution({
    required this.date,
    required this.autoAdjustedToToday,
    required this.hadInvalidDate,
  });

  final DateTime date;
  final bool autoAdjustedToToday;
  final bool hadInvalidDate;
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptBadge extends StatelessWidget {
  const _ReceiptBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
