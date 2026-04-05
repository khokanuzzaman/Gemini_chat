import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/utils/category_icon.dart';
import '../providers/recurring_provider.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(recurringProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Regular Expenses')),
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
                      size: 44,
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pattern.description,
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    Text(
                                      'প্রতি মাসে ~${BanglaFormatters.currency(pattern.averageAmount)}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: pattern.reminderEnabled,
                                onChanged: (value) => ref
                                    .read(recurringProvider.notifier)
                                    .toggleReminder(pattern.id, value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'পরবর্তী: ${pattern.nextExpected == null ? '—' : BanglaFormatters.fullDate(pattern.nextExpected!)}',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (pattern.nextExpected != null &&
                              pattern.nextExpected!
                                      .difference(DateTime.now())
                                      .inDays <=
                                  7) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '⚠️ ${pattern.nextExpected!.difference(DateTime.now()).inDays}দিন পরে আসছে',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
