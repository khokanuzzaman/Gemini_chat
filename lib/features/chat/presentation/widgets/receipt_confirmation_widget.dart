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

class ReceiptConfirmationWidget extends ConsumerStatefulWidget {
  const ReceiptConfirmationWidget({
    super.key,
    required this.receiptData,
    required this.onSave,
    required this.onCancel,
  });

  final Map<String, dynamic> receiptData;
  final Future<void> Function(Map<String, dynamic> receiptData, int? walletId)
  onSave;
  final VoidCallback onCancel;

  @override
  ConsumerState<ReceiptConfirmationWidget> createState() =>
      _ReceiptConfirmationWidgetState();
}

class _ReceiptConfirmationWidgetState
    extends ConsumerState<ReceiptConfirmationWidget> {
  late DateTime _selectedDate;
  late bool _autoAdjustedToToday;
  late bool _hadInvalidDate;
  int? _selectedWalletId;
  bool _showAll = false;
  bool _isSaving = false;
  bool _isSaved = false;

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
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final merchant = widget.receiptData['merchant'] as String? ?? 'Receipt';
    final category = widget.receiptData['category'] as String? ?? 'Other';
    final summary = widget.receiptData['summary'] as String? ?? '';
    final total = _normalizeAmount(widget.receiptData['total']);
    final items = (widget.receiptData['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final visibleItems = _showAll
        ? items
        : items.take(5).toList(growable: false);
    final remaining = items.length - visibleItems.length;
    final categoryMeta = resolveExpenseCategory(category);

    return ChatConfirmationCardShell(
      accentColor: const Color(0xFF00897B),
      maxWidthFactor: 0.86,
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
                  const ChatConfirmationIconCircle(
                    icon: Icons.receipt_long_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00897B), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          BanglaFormatters.fullDate(_selectedDate),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                        if (_autoAdjustedToToday)
                          const ChatConfirmationNoteChip(
                            note:
                                'Receipt date current monthের বাইরে ছিল, তাই আজকের তারিখ select করা হয়েছে।',
                          ),
                        if (_hadInvalidDate)
                          const ChatConfirmationNoteChip(
                            note:
                                'Receipt date বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে।',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppAmountText(
                    amount: total,
                    style: AppTextStyles.titleLarge,
                    isExpense: true,
                  ),
                ],
              ),
            ),
          ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ChatConfirmationMutedBox(
              child: AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (
                      var index = 0;
                      index < visibleItems.length;
                      index++
                    ) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              visibleItems[index]['name'] as String? ?? 'আইটেম',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.primaryTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            BanglaFormatters.currency(
                              _normalizeAmount(visibleItems[index]['amount']),
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      if (index != visibleItems.length - 1)
                        const SizedBox(height: 6),
                    ],
                    if (remaining > 0) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAll = !_showAll;
                          });
                        },
                        child: Text(
                          _showAll
                              ? 'কম দেখুন'
                              : 'আরো ${BanglaFormatters.count(remaining)}টি দেখুন',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppChip(
            label: category,
            icon: categoryMeta.icon,
            color: categoryMeta.color,
            compact: true,
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

    await widget.onSave(_effectiveReceiptData, walletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _isSaved = true;
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
