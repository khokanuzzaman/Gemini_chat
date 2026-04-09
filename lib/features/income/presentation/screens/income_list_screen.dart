import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../wallet/domain/entities/wallet_entity.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/income_entity.dart';
import '../../domain/entities/income_source.dart';
import '../providers/income_providers.dart';
import '../widgets/add_edit_income_sheet.dart';

class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  int? _selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomeListControllerProvider);

    return AppPageScaffold(
      title: 'আয়ের তালিকা',
      showOfflineBanner: false,
      actions: [
        IconButton(
          onPressed: () => _openFilterSheet(),
          icon: const Icon(Icons.filter_alt_outlined),
          tooltip: 'ফিল্টার',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.success,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add_rounded),
      ),
      body: state.when(
        data: (income) => _buildDataState(context, income),
        loading: () => Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: AppStaggeredList(
            children: const [
              _IncomeTopPanelLoading(),
              SizedBox(height: AppSpacing.md),
              _IncomeSummaryLoading(),
              SizedBox(height: AppSpacing.md),
              AppLoadingState.list(),
            ],
          ),
        ),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.read(incomeListControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, List<IncomeEntity> income) {
    final visibleIncome = _selectedWalletId == null
        ? income
        : income
              .where((entry) => entry.walletId == _selectedWalletId)
              .toList(growable: false);
    final grouped = _groupByDate(visibleIncome);
    final totalAmount = visibleIncome.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    return Column(
      children: [
        AppFadeSlideIn(
          duration: AppMotion.fast,
          child: _IncomeTopPanel(
            selectedWalletId: _selectedWalletId,
            onWalletChanged: (walletId) {
              setState(() {
                _selectedWalletId = walletId;
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(incomeListControllerProvider.notifier).refresh(),
            color: AppColors.success,
            backgroundColor: context.cardBackgroundColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                AppFadeSlideIn(
                  delay: AppMotion.staggerDelay,
                  duration: AppMotion.fast,
                  child: _IncomeSummaryStrip(
                    totalAmount: totalAmount,
                    count: visibleIncome.length,
                    onFilterTap: _openFilterSheet,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (visibleIncome.isEmpty)
                  AppFadeSlideIn(
                    delay: AppMotion.fast,
                    child: AppEmptyState(
                      icon: Icons.trending_up_rounded,
                      title: 'কোনো আয় নেই',
                      subtitle: 'আয় যোগ করতে + বাটনে ট্যাপ করুন',
                      actionLabel: 'আয় যোগ করুন',
                      onAction: _openAddSheet,
                    ),
                  )
                else ...[
                  for (var i = 0; i < grouped.entries.length; i++) ...[
                    AppFadeSlideIn(
                      key: ValueKey(
                        'income-group-${grouped.entries.elementAt(i).key}',
                      ),
                      delay: Duration(
                        milliseconds:
                            AppMotion.staggerDelay.inMilliseconds * (i + 2),
                      ),
                      duration: AppMotion.fast,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: i == grouped.length - 1 ? 0 : AppSpacing.lg,
                        ),
                        child: _IncomeDateSection(
                          date: grouped.entries.elementAt(i).key,
                          entries: grouped.entries.elementAt(i).value,
                          onEdit: _openEditSheet,
                          onDelete: _confirmDeleteIncome,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
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

  Future<void> _openAddSheet() async {
    final saved = await showAddEditIncomeSheet(context);
    if (saved != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('আয় সংরক্ষণ হয়েছে'),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _openEditSheet(IncomeEntity entry) async {
    final updated = await showAddEditIncomeSheet(
      context,
      existingIncome: entry,
    );

    if (updated != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('আয় আপডেট হয়েছে'),
          backgroundColor: AppColors.success,
        ),
      );
  }

  Future<void> _confirmDeleteIncome(IncomeEntity entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('আয় মুছে ফেলবেন?'),
          content: Text(
            '${entry.description.trim().isEmpty ? (findIncomeSourceByName(entry.source)?.banglaLabel ?? entry.source) : entry.description}\n${BanglaFormatters.currency(entry.amount)}',
          ),
          actions: [
            AppActionButton(
              label: 'বাতিল',
              variant: AppActionButtonVariant.ghost,
              size: AppActionButtonSize.small,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppActionButton(
              label: 'মুছুন',
              variant: AppActionButtonVariant.danger,
              size: AppActionButtonSize.small,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final error = await ref
        .read(incomeListControllerProvider.notifier)
        .deleteIncome(entry);

    if (!mounted || error == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _openFilterSheet() async {
    final wallets =
        ref.read(walletProvider).valueOrNull ?? const <WalletEntity>[];

    await AppBottomSheet.show<void>(
      context: context,
      title: 'ফিল্টার',
      subtitle: 'ওয়ালেট অনুযায়ী আয়ের তালিকা দেখুন',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ওয়ালেট',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: 'সব ওয়ালেট',
                selected: _selectedWalletId == null,
                onTap: () {
                  setState(() {
                    _selectedWalletId = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              for (final wallet in wallets)
                AppChip(
                  label: wallet.name,
                  emoji: wallet.emoji,
                  selected: _selectedWalletId == wallet.id,
                  onTap: () {
                    setState(() {
                      _selectedWalletId = wallet.id;
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'উৎস',
            style: AppTextStyles.titleMedium.copyWith(
              color: context.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const AppChip(label: 'সব উৎস', selected: true),
              for (final source in defaultIncomeSources)
                AppChip(
                  label: source.banglaLabel,
                  emoji: source.emoji,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'উৎস ফিল্টার এখন শুধু visual guide হিসেবে দেখানো হচ্ছে।',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTopPanel extends ConsumerWidget {
  const _IncomeTopPanel({
    required this.selectedWalletId,
    required this.onWalletChanged,
  });

  final int? selectedWalletId;
  final ValueChanged<int?> onWalletChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: walletsAsync.when(
              data: (wallets) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return AppChip(
                      label: 'সব ওয়ালেট',
                      selected: selectedWalletId == null,
                      onTap: () => onWalletChanged(null),
                    );
                  }

                  final wallet = wallets[index - 1];
                  return AppChip(
                    label: wallet.name,
                    emoji: wallet.emoji,
                    selected: selectedWalletId == wallet.id,
                    onTap: () => onWalletChanged(wallet.id),
                  );
                },
              ),
              loading: () => const _InlineChipLoading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: defaultIncomeSources.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const AppChip(label: 'সব উৎস', selected: true);
                }

                final source = defaultIncomeSources[index - 1];
                return AppChip(
                  label: source.banglaLabel,
                  emoji: source.emoji,
                  color: AppColors.success,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeSummaryStrip extends StatelessWidget {
  const _IncomeSummaryStrip({
    required this.totalAmount,
    required this.count,
    required this.onFilterTap,
  });

  final double totalAmount;
  final int count;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.cardAll,
        boxShadow: context.elevationLevel(1),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${BanglaFormatters.currency(totalAmount)} মোট · ${BanglaFormatters.count(count)}টি লেনদেন',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: onFilterTap,
            borderRadius: AppRadius.buttonAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.mutedSurfaceColor,
                borderRadius: AppRadius.buttonAll,
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ফিল্টার',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeDateSection extends StatelessWidget {
  const _IncomeDateSection({
    required this.date,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<IncomeEntity> entries;
  final Future<void> Function(IncomeEntity entry) onEdit;
  final Future<void> Function(IncomeEntity entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: BanglaFormatters.relativeDay(date),
          subtitle:
              '${BanglaFormatters.fullDate(date)} · ${BanglaFormatters.currency(total)}',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < entries.length; i++) ...[
          _IncomeCard(
            entry: entries[i],
            onTap: () => onEdit(entries[i]),
            onLongPress: () => onDelete(entries[i]),
          ),
          if (i != entries.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _IncomeCard extends ConsumerWidget {
  const _IncomeCard({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  final IncomeEntity entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = findIncomeSourceByName(entry.source);
    final label = source?.banglaLabel ?? entry.source;
    final emoji = source?.emoji ?? '💰';
    final wallet = entry.walletId == null
        ? null
        : ref.watch(walletByIdProvider(entry.walletId!));
    final title = entry.description.trim().isEmpty ? label : entry.description;
    final subtitleParts = <String>[
      label,
      BanglaFormatters.fullDate(entry.date),
      if (wallet != null) '${wallet.emoji} ${wallet.name}',
    ];

    return AppCard(
      elevation: 1,
      padding: EdgeInsets.zero,
      child: AppListTile(
        leadingEmoji: emoji,
        leadingColor: AppColors.success,
        title: title,
        subtitle: subtitleParts.join(' · '),
        trailingAmount: entry.amount,
        trailingAmountIsIncome: true,
        trailingSubtitle: BanglaFormatters.time(entry.date),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

class _InlineChipLoading extends StatelessWidget {
  const _InlineChipLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: const [
        _ChipPlaceholder(width: 110),
        SizedBox(width: AppSpacing.sm),
        _ChipPlaceholder(width: 92),
        SizedBox(width: AppSpacing.sm),
        _ChipPlaceholder(width: 104),
      ],
    );
  }
}

class _ChipPlaceholder extends StatelessWidget {
  const _ChipPlaceholder({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: AppRadius.buttonAll,
        border: Border.all(color: context.borderColor),
      ),
    );
  }
}

class _IncomeTopPanelLoading extends StatelessWidget {
  const _IncomeTopPanelLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.mutedSurfaceColor,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: context.borderColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40, child: _InlineChipLoading()),
          SizedBox(height: AppSpacing.sm),
          SizedBox(height: 40, child: _InlineChipLoading()),
        ],
      ),
    );
  }
}

class _IncomeSummaryLoading extends StatelessWidget {
  const _IncomeSummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingState.card(height: 72);
  }
}
