import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../wallet/presentation/widgets/wallet_selector.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';
import '../utils/expense_category_meta.dart';

Future<void> showManualAddSheet(BuildContext context) async {
  final saved = await Navigator.of(
    context,
  ).push<bool>(AppSlideUpRoute(builder: (_) => const ManualAddScreen()));

  if (saved != true || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text('খরচ সংরক্ষণ হয়েছে'),
        backgroundColor: AppColors.success,
      ),
    );
}

class ManualAddScreen extends ConsumerStatefulWidget {
  const ManualAddScreen({super.key});

  @override
  ConsumerState<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends ConsumerState<ManualAddScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Food';
  int? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final activeWallet = ref.watch(activeWalletProvider);
    final effectiveWalletId = _selectedWalletId ?? activeWallet?.id;
    final categoryNames = categories
        .map((category) => category.name)
        .toList(growable: false);

    if (!categoryNames.contains(_selectedCategory) &&
        categoryNames.isNotEmpty) {
      _selectedCategory = categoryNames.contains('Other')
          ? 'Other'
          : categoryNames.first;
    }

    return AppPageScaffold(
      title: 'ম্যানুয়াল খরচ যোগ',
      showOfflineBanner: false,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: AppStaggeredList(
            children: [
              _AmountFieldCard(
                controller: _amountController,
                accentColor: context.appColors.primary,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionBlock(
                title: 'ক্যাটাগরি',
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryNames.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final category = categoryNames[index];
                      final meta = resolveExpenseCategory(category);
                      final isSelected = _selectedCategory == category;
                      return AppChip(
                        label: _categoryDisplayName(category),
                        emoji: _categoryEmoji(category),
                        color: meta.color,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionBlock(
                title: 'বিবরণ',
                child: TextField(
                  controller: _descriptionController,
                  maxLength: 100,
                  maxLines: 3,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.primaryTextColor,
                  ),
                  decoration: _fieldDecoration(
                    context,
                    hintText: 'বিবরণ লিখুন...',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionBlock(
                title: 'তারিখ',
                child: _DateSelectorRow(date: _selectedDate, onTap: _pickDate),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionBlock(
                title: 'ওয়ালেট',
                child: WalletSelectorWidget(
                  selectedWalletId: effectiveWalletId,
                  onChanged: (walletId) {
                    setState(() {
                      _selectedWalletId = walletId;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppActionButton(
                label: 'সংরক্ষণ করুন',
                icon: Icons.check_rounded,
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
                fullWidth: true,
              ),
            ],
          ),
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
    final amount = _parseAmount(_amountController.text.trim());
    final description = _descriptionController.text.trim();
    final selectedWalletId =
        _selectedWalletId ?? ref.read(activeWalletProvider)?.id;

    if (amount == null || amount <= 0) {
      _showMessage('সঠিক পরিমাণ লিখুন');
      return;
    }

    if (_selectedCategory.trim().isEmpty) {
      _showMessage('একটি ক্যাটাগরি বেছে নিন');
      return;
    }

    if (selectedWalletId == null) {
      _showMessage('একটি ওয়ালেট বেছে নিন');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final expense = ExpenseEntity(
      amount: amount,
      category: _selectedCategory,
      description: description,
      date: _selectedDate,
      isManual: true,
    );

    final error = await ref
        .read(expenseMutationControllerProvider)
        .saveManualExpense(expense, walletId: selectedWalletId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (error != null) {
      _showMessage(error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

class _AmountFieldCard extends StatelessWidget {
  const _AmountFieldCard({required this.controller, required this.accentColor});

  final TextEditingController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Text(
            'পরিমাণ',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '৳',
                style: AppTextStyles.heroAmount.copyWith(color: accentColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroAmount.copyWith(color: accentColor),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSelectorRow extends StatelessWidget {
  const _DateSelectorRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: AppRadius.cardAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: context.appColors.primary,
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
            Text(
              'পরিবর্তন করুন',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.appColors.primary,
                fontWeight: FontWeight.w600,
              ),
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
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: context.hintTextColor),
    filled: true,
    fillColor: context.mutedSurfaceColor,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(AppRadius.input),
      borderSide: BorderSide.none,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(AppRadius.input),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: const BorderRadius.all(AppRadius.input),
      borderSide: BorderSide(color: context.appColors.primary),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 14,
    ),
  );
}

String _categoryEmoji(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
    case 'খাবার':
      return '🍽️';
    case 'transport':
    case 'যাতায়াত':
      return '🛺';
    case 'shopping':
    case 'কেনাকাটা':
      return '🛍️';
    case 'healthcare':
    case 'স্বাস্থ্য':
      return '🩺';
    case 'bill':
    case 'bills':
    case 'বিল':
      return '💡';
    case 'entertainment':
    case 'বিনোদন':
      return '🎬';
    case 'education':
    case 'শিক্ষা':
      return '📚';
    case 'travel':
    case 'ভ্রমণ':
      return '✈️';
    case 'rent':
    case 'ভাড়া':
      return '🏠';
    case 'other':
    case 'অন্যান্য':
      return '🧾';
    default:
      return '💸';
  }
}

String _categoryDisplayName(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
      return 'খাবার';
    case 'transport':
      return 'যাতায়াত';
    case 'shopping':
      return 'কেনাকাটা';
    case 'healthcare':
      return 'স্বাস্থ্য';
    case 'bill':
    case 'bills':
      return 'বিল';
    case 'entertainment':
      return 'বিনোদন';
    case 'education':
      return 'শিক্ষা';
    case 'travel':
      return 'ভ্রমণ';
    case 'rent':
      return 'ভাড়া';
    case 'other':
      return 'অন্যান্য';
    default:
      return category;
  }
}
