import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../providers/recurring_provider.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  String _frequencyLabel(RecurringExpenseEntity pattern) {
    switch (pattern.frequency) {
      case RecurringFrequency.weekly:
        return 'সাপ্তাহিক ~${BanglaFormatters.currency(pattern.averageAmount)}';
      case RecurringFrequency.monthly:
        return 'মাসিক ~${BanglaFormatters.currency(pattern.averageAmount)}';
      case RecurringFrequency.daily:
        return 'দৈনিক ~${BanglaFormatters.currency(pattern.averageAmount)}';
    }
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

  String _frequencyBadgeLabel(RecurringExpenseEntity pattern) {
    switch (pattern.frequency) {
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.daily:
        return 'Daily';
    }
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<RecurringExpenseEntity> patterns,
  ) {
    final reminderCount = patterns
        .where((pattern) => pattern.reminderEnabled)
        .length;
    final nextPattern = patterns
        .where((pattern) => pattern.nextExpected != null)
        .cast<RecurringExpenseEntity?>()
        .map((pattern) => pattern!)
        .fold<RecurringExpenseEntity?>(null, (current, pattern) {
          if (current == null) {
            return pattern;
          }
          final currentDate = current.nextExpected!;
          final nextDate = pattern.nextExpected!;
          return nextDate.isBefore(currentDate) ? pattern : current;
        });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.primaryTextColor.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected overview',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${patterns.length}টি নিয়মিত খরচ',
            style: AppTextStyles.titleLarge.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.notifications_active_outlined,
                label: '$reminderCount টি reminder চালু',
                color: Theme.of(context).colorScheme.primary,
              ),
              _InfoChip(
                icon: Icons.timeline_rounded,
                label: nextPattern?.nextExpected == null
                    ? 'পরবর্তী তারিখ নেই'
                    : 'পরবর্তী: ${BanglaFormatters.dayMonth(nextPattern!.nextExpected!)}',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextStatus(
    BuildContext context,
    RecurringExpenseEntity pattern,
  ) {
    final now = DateTime.now();
    final next = pattern.nextExpected;

    if (next == null) {
      return Text(
        'পরবর্তী: —',
        style: TextStyle(
          color: context.secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final daysLeft = next.difference(now).inDays;

    if (daysLeft < 0) {
      return const Text(
        'মেয়াদ উত্তীর্ণ',
        style: TextStyle(
          color: AppColors.error,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (daysLeft == 0) {
      return const Text(
        'আজকে আসছে ⚠️',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (daysLeft >= 1 && daysLeft <= 3) {
      return _UrgencyContainer(
        color: AppColors.error,
        label: '⚠️ $daysLeft দিন পরে আসছে',
      );
    }

    if (daysLeft >= 4 && daysLeft <= 7) {
      return _UrgencyContainer(
        color: AppColors.warning,
        label: '⚠️ $daysLeft দিন পরে আসছে',
      );
    }

    return Text(
      'পরবর্তী: ${BanglaFormatters.fullDate(next)}',
      style: TextStyle(
        color: context.secondaryTextColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildConfidenceSection(
    BuildContext context,
    RecurringExpenseEntity pattern,
  ) {
    final confidenceColor = _confidenceColor(pattern.confidenceScore);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(
          alpha: context.isDarkMode ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pattern confidence',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                'নির্ভরযোগ্যতা ${(pattern.confidenceScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: confidenceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pattern.confidenceScore,
              minHeight: 4,
              backgroundColor: Theme.of(context).colorScheme.surface,
              color: confidenceColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('পুনরাবৃত্তিমূলক খরচ'),
        actions: [
          if (recurring.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
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
            icon: const Icon(Icons.refresh),
            tooltip: 'আবার খুঁজুন',
          ),
        ],
      ),
      body: recurring.when(
        data: (patterns) {
          if (patterns.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_alt_rounded,
                      size: 48,
                      color: context.secondaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'এখনো কোনো pattern পাওয়া যায়নি।\nআরো expense add করুন।',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(recurringProvider.notifier).reDetect(),
                      child: const Text('এখন detect করুন'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(recurringProvider.notifier).reDetect();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildSummaryCard(context, patterns),
                const SizedBox(height: 16),
                ...patterns.map(
                  (pattern) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: CategoryIcon.getColor(
                                    pattern.category,
                                  ).withValues(alpha: 0.15),
                                  child: Icon(
                                    CategoryIcon.getIcon(pattern.category),
                                    color: CategoryIcon.getColor(
                                      pattern.category,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            pattern.description,
                                            style: AppTextStyles.titleMedium,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _frequencyBadgeLabel(pattern),
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _frequencyLabel(pattern),
                                        style: AppTextStyles.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildConfidenceSection(context, pattern),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Switch.adaptive(
                                      value: pattern.reminderEnabled,
                                      onChanged: (value) => ref
                                          .read(recurringProvider.notifier)
                                          .toggleReminder(pattern.id, value),
                                    ),
                                    Text(
                                      pattern.reminderEnabled
                                          ? 'Reminder on'
                                          : 'Reminder off',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.category_outlined,
                                  label: pattern.category,
                                  color: CategoryIcon.getColor(
                                    pattern.category,
                                  ),
                                ),
                                _InfoChip(
                                  icon: Icons.history_rounded,
                                  label:
                                      'সর্বশেষ: ${BanglaFormatters.dayMonth(pattern.lastOccurrence)}',
                                  color: context.secondaryTextColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildNextStatus(context, pattern),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(recurringProvider.notifier).reDetect(),
                  child: const Text('এখন detect করুন'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class _UrgencyContainer extends StatelessWidget {
  const _UrgencyContainer({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
