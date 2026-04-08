import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/income_source.dart';
import '../providers/income_providers.dart';
import '../widgets/add_edit_income_sheet.dart';

class IncomeListScreen extends ConsumerWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomeListControllerProvider);
    final monthIncome = ref.watch(thisMonthIncomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('আয়'),
        actions: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: state.when(
        data: (income) {
          final grouped = _groupByDate(income);
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(incomeListControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _IncomeSummaryCard(value: monthIncome),
                const SizedBox(height: 16),
                if (income.isEmpty)
                  const _IncomeEmptyState()
                else
                  ...grouped.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _IncomeDateSection(
                        date: entry.key,
                        entries: entry.value,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const _IncomeLoadingState(),
        error: (error, _) => _IncomeErrorState(
          message: 'আয়ের তালিকা লোড করা যায়নি\n$error',
          onRetry: () =>
              ref.read(incomeListControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Map<DateTime, List<IncomeEntity>> _groupByDate(List<IncomeEntity> income) {
    final sorted = [...income]..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <DateTime, List<IncomeEntity>>{};
    for (final entry in sorted) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(date, () => []).add(entry);
    }
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.date.compareTo(a.date));
    }
    return grouped;
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddEditIncomeSheet(),
    );
  }
}

class _IncomeSummaryCard extends StatelessWidget {
  const _IncomeSummaryCard({required this.value});

  final AsyncValue<double> value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'এই মাসে মোট আয়',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            value.when(
              data: (amount) => Text(
                BanglaFormatters.currency(amount),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              loading: () => const ShimmerBox(height: 18, width: 140, radius: 8),
              error: (error, _) => Text(
                'লোড হচ্ছে না',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeDateSection extends ConsumerWidget {
  const _IncomeDateSection({required this.date, required this.entries});

  final DateTime date;
  final List<IncomeEntity> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          BanglaFormatters.fullDate(date),
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey('income-${entry.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('আয় মুছবেন?'),
                    content: Text(
                      '${BanglaFormatters.currency(entry.amount)} আয়টি মুছে যাবে।',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('বাদ দিন'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('মুছুন'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) {
                  return false;
                }
                final error = await ref
                    .read(incomeListControllerProvider.notifier)
                    .deleteIncome(entry);
                if (context.mounted && error != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
                return error == null;
              },
              child: _IncomeCard(entry: entry),
            ),
          );
        }),
      ],
    );
  }
}

class _IncomeCard extends ConsumerWidget {
  const _IncomeCard({required this.entry});

  final IncomeEntity entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = findIncomeSourceByName(entry.source);
    final label = source?.banglaLabel ?? entry.source;
    final emoji = source?.emoji ?? '💰';
    final wallet = entry.walletId == null
        ? null
        : ref.watch(walletByIdProvider(entry.walletId!));

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final updated = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: context.cardBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (_) => AddEditIncomeSheet(existingIncome: entry),
        );
        if (updated == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('আয় আপডেট হয়েছে')),
          );
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.success.withValues(alpha: 0.12),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleMedium),
                    if (entry.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (wallet != null)
                          _WalletMetaPill(
                            emoji: wallet.emoji,
                            label: wallet.name,
                          ),
                        if (entry.isRecurring)
                          const _IncomeMetaPill(
                            label: 'নিয়মিত',
                            icon: Icons.repeat_rounded,
                            color: AppColors.success,
                          ),
                        if (entry.isManual)
                          const _IncomeMetaPill(
                            label: 'Manual',
                            icon: Icons.edit_note_rounded,
                            color: AppColors.grey600,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      BanglaFormatters.time(entry.date),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                BanglaFormatters.currency(entry.amount),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletMetaPill extends StatelessWidget {
  const _WalletMetaPill({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeMetaPill extends StatelessWidget {
  const _IncomeMetaPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeLoadingState extends StatelessWidget {
  const _IncomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          ShimmerBox(height: 90, radius: 16),
          SizedBox(height: 16),
          ShimmerBox(height: 84, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(height: 84, radius: 16),
          SizedBox(height: 12),
          ShimmerBox(height: 84, radius: 16),
        ],
      ),
    );
  }
}

class _IncomeEmptyState extends StatelessWidget {
  const _IncomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 48,
              color: context.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'এখনো কোনো আয় যোগ করেননি',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'নতুন আয় যোগ করতে + চাপুন',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeErrorState extends StatelessWidget {
  const _IncomeErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: context.secondaryTextColor,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
