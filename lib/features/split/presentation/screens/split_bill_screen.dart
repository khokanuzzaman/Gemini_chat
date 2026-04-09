import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/split_bill_entity.dart';
import '../providers/split_bill_provider.dart';
import 'add_edit_split_screen.dart';
import 'split_detail_screen.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  const SplitBillScreen({super.key});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final splits = ref.watch(splitBillProvider);
    final ready = ref.watch(splitBillReadyProvider);
    final activeSplits =
        splits.where((split) => !split.isSettled).toList(growable: false)
          ..sort((first, second) => second.date.compareTo(first.date));
    final settledSplits =
        splits.where((split) => split.isSettled).toList(growable: false)
          ..sort((first, second) => second.date.compareTo(first.date));

    return AppPageScaffold(
      title: 'স্প্লিট বিল',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSplitEditor(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              0,
            ),
            child: AppSegmentedTabs(
              tabs: const ['সক্রিয়', 'সম্পন্ন'],
              selectedIndex: _selectedIndex,
              onChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: !ready
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(AppSpacing.screenPadding),
                    child: AppLoadingState.list(),
                  )
                : AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: _SplitListTab(
                      key: ValueKey('split-tab-$_selectedIndex'),
                      splits: _selectedIndex == 0
                          ? activeSplits
                          : settledSplits,
                      emptyIcon: _selectedIndex == 0
                          ? Icons.call_split_rounded
                          : Icons.check_circle_outline_rounded,
                      emptyTitle: _selectedIndex == 0
                          ? 'কোনো সক্রিয় স্প্লিট নেই'
                          : 'কোনো সম্পন্ন স্প্লিট নেই',
                      emptySubtitle: _selectedIndex == 0
                          ? 'বন্ধুদের সাথে খরচ ভাগ করলে এখানে দেখাবে'
                          : 'settled হয়ে যাওয়া split এখানে থাকবে',
                      emptyButtonLabel: 'নতুন স্প্লিট',
                      onEmptyAction: () => _openSplitEditor(context),
                      itemBuilder: (split) => _SplitSummaryCard(
                        split: split,
                        onTap: () => _openSplitDetails(context, split.id),
                        onMarkSettled: split.isSettled
                            ? null
                            : () => _confirmSettle(context, split.id),
                        onEdit: split.isSettled
                            ? null
                            : () => _openSplitEditor(context, split: split),
                        onDelete: () => _confirmDelete(context, split),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openSplitEditor(BuildContext context, {SplitBillEntity? split}) {
    Navigator.of(
      context,
    ).push(AppSlideRoute(builder: (_) => AddEditSplitScreen(split: split)));
  }

  void _openSplitDetails(BuildContext context, int splitId) {
    Navigator.of(
      context,
    ).push(AppSlideRoute(builder: (_) => SplitDetailScreen(splitId: splitId)));
  }

  Future<void> _confirmSettle(BuildContext context, int splitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('সম্পন্ন করবেন?'),
          content: const Text(
            'সব পরিশোধ হয়ে গেলে এটি সম্পন্ন তালিকায় চলে যাবে।',
          ),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'সম্পন্ন',
              variant: AppActionButtonVariant.success,
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
    setState(() {
      _selectedIndex = 1;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('স্প্লিট সম্পন্ন হয়েছে')));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SplitBillEntity split,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('স্প্লিট মুছবেন?'),
          content: Text('“${split.title}” স্থায়ীভাবে মুছে যাবে।'),
          actions: [
            AppActionButton(
              label: 'না',
              variant: AppActionButtonVariant.ghost,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
    ).showSnackBar(const SnackBar(content: Text('স্প্লিট মুছে গেছে')));
  }
}

class _SplitListTab extends StatelessWidget {
  const _SplitListTab({
    super.key,
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
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: emptyButtonLabel,
        onAction: onEmptyAction,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        100,
      ),
      itemCount: splits.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
    final statusColor = split.isSettled ? AppColors.success : AppColors.warning;

    return Opacity(
      opacity: split.isSettled ? 0.82 : 1,
      child: AppCard(
        elevation: 1,
        onTap: onTap,
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
                      Text(
                        split.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: context.primaryTextColor,
                        ),
                      ),
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
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      BanglaFormatters.preciseCurrency(split.totalAmount),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: split.isSettled
                            ? context.secondaryTextColor
                            : context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${BanglaFormatters.count(split.persons.length)} জন',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppChip(
                      label: split.isSettled ? 'সম্পন্ন' : 'সক্রিয়',
                      color: statusColor,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final person in split.persons)
                  _BalanceChip(person: person),
              ],
            ),
            if (settlements.isNotEmpty && !split.isSettled) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                elevation: 1,
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.16),
                    AppColors.warning.withValues(alpha: 0.08),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সেটেলমেন্ট সাজেশন',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final settlement in settlements.take(2))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          '${settlement.from} → ${settlement.to}: ${BanglaFormatters.preciseCurrency(settlement.amount)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF8B5A00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (settlements.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'আরো ${BanglaFormatters.count(settlements.length - 2)}টি বাকি',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (!split.isSettled && onMarkSettled != null)
                  Expanded(
                    child: AppActionButton(
                      label: 'সম্পন্ন',
                      icon: Icons.check_circle_outline_rounded,
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.success,
                      onPressed: onMarkSettled,
                    ),
                  ),
                if (!split.isSettled && onEdit != null)
                  Padding(
                    padding: EdgeInsets.only(
                      left: onMarkSettled != null ? AppSpacing.sm : 0,
                    ),
                    child: AppActionButton(
                      label: 'সম্পাদনা',
                      icon: Icons.edit_outlined,
                      size: AppActionButtonSize.small,
                      variant: AppActionButtonVariant.ghost,
                      onPressed: onEdit,
                    ),
                  ),
                const Spacer(),
                AppActionButton(
                  label: 'মুছুন',
                  icon: Icons.delete_outline_rounded,
                  size: AppActionButtonSize.small,
                  variant: AppActionButtonVariant.danger,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
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
        borderRadius: const BorderRadius.all(AppRadius.chip),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
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
