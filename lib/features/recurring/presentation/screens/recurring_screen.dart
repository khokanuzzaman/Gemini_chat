import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../providers/recurring_provider.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringProvider);

    return AppPageScaffold(
      title: 'নিয়মিত খরচ',
      showOfflineBanner: false,
      actions: [
        if (recurring.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        IconButton(
          onPressed: () => ref.read(recurringProvider.notifier).reDetect(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'আবার খুঁজুন',
        ),
      ],
      body: recurring.when(
        data: (patterns) {
          if (patterns.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(recurringProvider.notifier).reDetect(),
              color: context.appColors.primary,
              backgroundColor: context.cardBackgroundColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  const AppEmptyState(
                    icon: Icons.repeat_rounded,
                    title: 'কোনো নিয়মিত খরচ সনাক্ত হয়নি',
                    subtitle:
                        'পর্যাপ্ত খরচ ডেটা জমা হলে নিয়মিত খরচ স্বয়ংক্রিয়ভাবে সনাক্ত হবে',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppActionButton(
                    label: 'আবার খুঁজুন',
                    icon: Icons.refresh_rounded,
                    fullWidth: true,
                    onPressed: () =>
                        ref.read(recurringProvider.notifier).reDetect(),
                  ),
                ],
              ),
            );
          }

          final reminderCount = patterns
              .where((pattern) => pattern.reminderEnabled)
              .length;

          return RefreshIndicator(
            onRefresh: () => ref.read(recurringProvider.notifier).reDetect(),
            color: context.appColors.primary,
            backgroundColor: context.cardBackgroundColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: AppStaggeredList(
                children: [
                  AppCard(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          title: 'নিয়মিত খরচ',
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${BanglaFormatters.count(patterns.length)}টি সনাক্ত হয়েছে · ${BanglaFormatters.count(reminderCount)}টি রিমাইন্ডার চালু',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardGap),
                  for (var i = 0; i < patterns.length; i++) ...[
                    _RecurringExpenseCard(pattern: patterns[i]),
                    if (i != patterns.length - 1)
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: const AppLoadingState.list(),
        ),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.read(recurringProvider.notifier).reDetect(),
        ),
      ),
    );
  }
}

class _RecurringExpenseCard extends ConsumerWidget {
  const _RecurringExpenseCard({required this.pattern});

  final RecurringExpenseEntity pattern;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _categoryColor(pattern.category);

    return AppCard(
      elevation: 1,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppListTile(
                  padding: EdgeInsets.zero,
                  leadingEmoji: _categoryEmoji(pattern.category),
                  leadingColor: color,
                  title: pattern.description,
                  subtitle:
                      '${_frequencyLabel(pattern.frequency)} · ${_nextExpectedLabel(pattern.nextExpected)}',
                  trailingAmount: pattern.averageAmount,
                  trailingAmountIsExpense: true,
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAmountText(
                        amount: pattern.averageAmount,
                        isExpense: true,
                        showSign: true,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'গড়',
                        style: AppTextStyles.caption.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppProgressBar(
                  value: pattern.confidenceScore,
                  color: _confidenceColor(pattern.confidenceScore),
                  showLabel: true,
                  label: 'আত্মবিশ্বাস',
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (pattern.reminderEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: AppRadius.buttonAll,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'রিমাইন্ডার চালু',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Text(
                      _categoryDisplayName(pattern.category),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Switch.adaptive(
                      value: pattern.reminderEnabled,
                      activeTrackColor: context.appColors.primary.withValues(
                        alpha: 0.3,
                      ),
                      activeThumbColor: context.appColors.primary,
                      onChanged: (value) => ref
                          .read(recurringProvider.notifier)
                          .toggleReminder(pattern.id, value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (pattern.reminderEnabled)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _frequencyLabel(RecurringFrequency frequency) {
  return switch (frequency) {
    RecurringFrequency.daily => 'প্রতিদিন',
    RecurringFrequency.weekly => 'প্রতি সপ্তাহে',
    RecurringFrequency.monthly => 'প্রতি মাসে',
  };
}

String _nextExpectedLabel(DateTime? date) {
  if (date == null) {
    return 'পরবর্তী তারিখ নেই';
  }
  return 'পরবর্তী: ${BanglaFormatters.fullDate(date)}';
}

Color _confidenceColor(double confidenceScore) {
  if (confidenceScore >= 0.75) {
    return AppColors.success;
  }
  if (confidenceScore >= 0.5) {
    return AppColors.warning;
  }
  return AppColors.error;
}

Color _categoryColor(String category) {
  switch (category.trim().toLowerCase()) {
    case 'food':
    case 'খাবার':
      return AppColors.food;
    case 'transport':
    case 'যাতায়াত':
      return AppColors.transport;
    case 'shopping':
    case 'কেনাকাটা':
      return AppColors.shopping;
    case 'healthcare':
    case 'স্বাস্থ্য':
      return AppColors.healthcare;
    case 'bill':
    case 'bills':
    case 'বিল':
      return AppColors.bill;
    case 'entertainment':
    case 'বিনোদন':
      return AppColors.entertainment;
    default:
      return AppColors.other;
  }
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
    default:
      return category;
  }
}
