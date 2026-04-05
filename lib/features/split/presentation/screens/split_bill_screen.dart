// Feature: Split
// Layer: Presentation

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../providers/split_bill_provider.dart';
import 'add_edit_split_screen.dart';
import 'split_detail_screen.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final splits = ref.watch(splitBillProvider);
    final ready = ref.watch(splitBillReadyProvider);
    final activeSplits = splits
        .where((split) => !split.isSettled)
        .toList(growable: false)
      ..sort((first, second) => second.date.compareTo(first.date));
    final settledSplits = splits
        .where((split) => split.isSettled)
        .toList(growable: false)
      ..sort((first, second) => second.date.compareTo(first.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill ভাগ'),
        actions: [
          IconButton(
            onPressed: () => _openSplitEditor(context),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'নতুন split',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(key: Key('split-tab-active'), text: 'চলমান'),
            Tab(key: Key('split-tab-settled'), text: 'সম্পন্ন'),
          ],
        ),
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SplitListTab(
                  splits: activeSplits,
                  emptyIcon: Icons.call_split_rounded,
                  emptyTitle: 'কোনো bill ভাগ নেই',
                  emptySubtitle: 'বন্ধুদের সাথে খরচ ভাগ করুন',
                  emptyButtonLabel: 'নতুন split',
                  onEmptyAction: () => _openSplitEditor(context),
                  itemBuilder: (split) => _SplitSummaryCard(
                    split: split,
                    onTap: () => _openSplitDetails(context, split.id),
                    onMarkSettled: () => _confirmSettle(context, split.id),
                    onEdit: () => _openSplitEditor(context, split: split),
                    onDelete: () => _confirmDelete(context, split),
                  ),
                ),
                _SplitListTab(
                  splits: settledSplits,
                  emptyIcon: Icons.check_circle_outline_rounded,
                  emptyTitle: 'কোনো সম্পন্ন split নেই',
                  emptySubtitle: 'যেগুলো settle করবেন, এখানে দেখা যাবে',
                  emptyButtonLabel: 'নতুন split',
                  onEmptyAction: () => _openSplitEditor(context),
                  itemBuilder: (split) => _SplitSummaryCard(
                    split: split,
                    onTap: () => _openSplitDetails(context, split.id),
                    onDelete: () => _confirmDelete(context, split),
                  ),
                ),
              ],
            ),
    );
  }

  void _openSplitEditor(BuildContext context, {SplitBillEntity? split}) {
    Navigator.of(context).push(buildAppRoute(AddEditSplitScreen(split: split)));
  }

  void _openSplitDetails(BuildContext context, int splitId) {
    Navigator.of(
      context,
    ).push(buildAppRoute(SplitDetailScreen(splitId: splitId)));
  }

  Future<void> _confirmSettle(BuildContext context, int splitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('সম্পন্ন করবেন?'),
          content: const Text(
            'সব পরিশোধ হয়ে গেলে এটা সম্পন্ন tab-এ চলে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('সম্পন্ন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(splitBillProvider.notifier).markSettled(splitId);
    if (!context.mounted) {
      return;
    }
    _tabController.animateTo(1);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Split সম্পন্ন হয়েছে')));
  }

  Future<void> _confirmDelete(BuildContext context, SplitBillEntity split) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Split মুছবেন?'),
          content: Text('“${split.title}” permanently মুছে যাবে।'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('মুছুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(splitBillProvider.notifier).deleteSplit(split.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Split মুছে গেছে')));
  }
}

class _SplitListTab extends StatelessWidget {
  const _SplitListTab({
    required this.splits,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyButtonLabel,
    required this.onEmptyAction,
    required this.itemBuilder,
  });

  final List<SplitBillEntity> splits;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final String emptyButtonLabel;
  final VoidCallback onEmptyAction;
  final Widget Function(SplitBillEntity split) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 64, color: context.secondaryTextColor),
              const SizedBox(height: AppSpacing.md),
              Text(emptyTitle, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                emptySubtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: onEmptyAction,
                child: Text(emptyButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: splits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => itemBuilder(splits[index]),
    );
  }
}

class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({
    required this.split,
    required this.onTap,
    this.onMarkSettled,
    this.onEdit,
    required this.onDelete,
  });

  final SplitBillEntity split;
  final VoidCallback onTap;
  final VoidCallback? onMarkSettled;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final settlements = split.settlements;
    final amountColor = split.isSettled
        ? context.secondaryTextColor
        : context.appColors.primary;

    final content = InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(split.title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        BanglaFormatters.fullDate(split.date),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      BanglaFormatters.preciseCurrency(split.totalAmount),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${BanglaFormatters.count(split.persons.length)} জন',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    if (split.isSettled) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '✅ সম্পন্ন',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final person in split.persons) ...[
                    _BalanceChip(person: person),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            if (settlements.isNotEmpty && !split.isSettled) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final settlement in settlements.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${settlement.from} → ${settlement.to}: ${BanglaFormatters.preciseCurrency(settlement.amount)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF8B5A00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (settlements.length > 2)
                      Text(
                        '...আরো ${BanglaFormatters.count(settlements.length - 2)}টি',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (!split.isSettled && onMarkSettled != null)
                  TextButton.icon(
                    key: Key('split-action-settle-${split.id}'),
                    onPressed: onMarkSettled,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('সম্পন্ন'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                    ),
                  ),
                if (!split.isSettled) const Spacer(),
                if (!split.isSettled && onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('সম্পাদনা'),
                  ),
                if (split.isSettled) const Spacer(),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('মুছুন'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Opacity(
      opacity: split.isSettled ? 0.78 : 1,
      child: Card(child: content),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({required this.person});

  final SplitPerson person;

  @override
  Widget build(BuildContext context) {
    final isPositive = person.balance >= 0;
    final tint = isPositive ? AppColors.success : AppColors.error;
    final prefix = isPositive ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        '${person.name}: $prefix${BanglaFormatters.preciseCurrency(person.balance.abs())}',
        style: AppTextStyles.bodySmall.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
