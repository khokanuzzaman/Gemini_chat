import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/debt_entity.dart';
import '../models/mutation_result.dart';
import '../providers/debt_providers.dart';
import '../utils/debt_ui.dart';
import '../widgets/add_edit_debt_sheet.dart';
import 'debt_detail_screen.dart';

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _emiSectionKey = GlobalKey();
  bool _showSettled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtListAsync = ref.watch(debtListProvider);

    return AppPageScaffold(
      title: 'ধার-দেনা',
      refreshIndicator: () => ref.read(debtListProvider.notifier).refresh(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDebtSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: debtListAsync.when(
        loading: () => const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: AppLoadingState.list(),
        ),
        error: (error, _) => AppErrorState(
          title: 'ধার-দেনা লোড করা যায়নি',
          message: '$error',
          onRetry: () => ref.read(debtListProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.debts.isEmpty) {
            return AppEmptyState(
              icon: Icons.handshake_rounded,
              title: 'কোনো ধার-দেনা নেই',
              subtitle: 'নতুন পাওনা, দেনা বা কিস্তি যোগ করলে এখানে দেখাবে',
              actionLabel: 'নতুন যোগ করুন',
              onAction: () => _openAddDebtSheet(context),
            );
          }

          final children = <Widget>[
            _DebtSummaryCard(state: state),
            if (state.upcomingInstallmentsThisWeek.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _UpcomingEmiBanner(
                count: state.upcomingInstallmentsThisWeek.length,
                total: state.upcomingInstallmentsThisWeek.fold<double>(
                  0,
                  (sum, debt) => sum + debt.nextInstallmentAmount,
                ),
                onTap: _scrollToEmiSection,
              ),
            ],
            const SizedBox(height: AppSpacing.sectionGap),
            _FilterRow(
              selected: state.filter,
              onChanged: (filter) {
                ref.read(debtListProvider.notifier).setFilter(filter);
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            ..._buildDebtContent(context, state),
          ];

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              100,
            ),
            child: AppStaggeredList(children: children),
          );
        },
      ),
    );
  }

  List<Widget> _buildDebtContent(BuildContext context, DebtListState state) {
    final filteredDebts = state.filteredDebts;
    if (filteredDebts.isEmpty) {
      return const [
        AppEmptyState(
          icon: Icons.filter_alt_off_rounded,
          title: 'এই ফিল্টারে কিছু পাওয়া যায়নি',
          compact: true,
        ),
      ];
    }

    if (state.filter != DebtFilterType.all) {
      return [
        for (var index = 0; index < filteredDebts.length; index++) ...[
          _DebtListCard(debt: filteredDebts[index]),
          if (index != filteredDebts.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ];
    }

    final overdueDebts = filteredDebts
        .where((debt) => resolveDebtStatus(debt) == DebtStatus.overdue)
        .toList(growable: false);
    final activeEmiDebts = filteredDebts
        .where(
          (debt) => resolveDebtStatus(debt) == DebtStatus.active && debt.isEMI,
        )
        .toList(growable: false);
    final activeRegularDebts = filteredDebts
        .where(
          (debt) => resolveDebtStatus(debt) == DebtStatus.active && !debt.isEMI,
        )
        .toList(growable: false);
    final settledDebts = filteredDebts
        .where((debt) => resolveDebtStatus(debt) == DebtStatus.settled)
        .toList(growable: false);
    final cancelledDebts = filteredDebts
        .where((debt) => resolveDebtStatus(debt) == DebtStatus.cancelled)
        .toList(growable: false);

    final children = <Widget>[];
    void addSection(
      String title,
      List<DebtEntity> debts, {
      Key? key,
      Widget? action,
    }) {
      if (debts.isEmpty) {
        return;
      }
      children.add(
        KeyedSubtree(
          key: key,
          child: AppSectionHeader(title: title, action: action),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.sm));
      for (var index = 0; index < debts.length; index++) {
        children.add(_DebtListCard(debt: debts[index]));
        if (index != debts.length - 1) {
          children.add(const SizedBox(height: AppSpacing.md));
        }
      }
      children.add(const SizedBox(height: AppSpacing.sectionGap));
    }

    addSection('মেয়াদোত্তীর্ণ', overdueDebts);
    addSection('কিস্তি', activeEmiDebts, key: _emiSectionKey);
    addSection('সক্রিয়', activeRegularDebts);

    if (settledDebts.isNotEmpty) {
      children.add(
        AppSectionHeader(
          title: 'পরিশোধিত (${BanglaFormatters.count(settledDebts.length)})',
          action: TextButton(
            onPressed: () {
              setState(() {
                _showSettled = !_showSettled;
              });
            },
            child: Text(_showSettled ? 'লুকান' : 'দেখুন'),
          ),
        ),
      );
      if (_showSettled) {
        children.add(const SizedBox(height: AppSpacing.sm));
        for (var index = 0; index < settledDebts.length; index++) {
          children.add(_DebtListCard(debt: settledDebts[index]));
          if (index != settledDebts.length - 1) {
            children.add(const SizedBox(height: AppSpacing.md));
          }
        }
      }
      children.add(const SizedBox(height: AppSpacing.sectionGap));
    }

    addSection('বাতিল', cancelledDebts);

    if (children.isNotEmpty) {
      children.removeLast();
    }
    return children;
  }

  Future<void> _openAddDebtSheet(BuildContext context) async {
    final result = await showAddEditDebtSheet(context);
    if (result != null && context.mounted) {
      showDebtMutationResultSnackBar(context, result);
    }
  }

  void _scrollToEmiSection() {
    final notifier = ref.read(debtListProvider.notifier);
    if (ref.read(debtListProvider).valueOrNull?.filter != DebtFilterType.all) {
      notifier.setFilter(DebtFilterType.all);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _emiSectionKey.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: AppMotion.normal,
          curve: AppMotion.standard,
        );
      }
    });
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({required this.state});

  final DebtListState state;

  @override
  Widget build(BuildContext context) {
    final netColor = state.netPosition >= 0
        ? const Color(0xFFC9FFD4)
        : const Color(0xFFFFD6D2);

    return AppCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D5E4A), Color(0xFF611D1D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'পাওনা',
              value: BanglaFormatters.currency(state.totalOwedToMe),
              valueColor: const Color(0xFFC8FACC),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryMetric(
              label: 'দেনা',
              value: BanglaFormatters.currency(state.totalIOwe),
              valueColor: const Color(0xFFFFD2D2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryMetric(
              label: 'নিট',
              value: BanglaFormatters.currency(state.netPosition.abs()),
              prefix: state.netPosition >= 0 ? '+' : '-',
              valueColor: netColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.prefix = '',
  });

  final String label;
  final String value;
  final Color valueColor;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix$value',
          style: AppTextStyles.titleMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _UpcomingEmiBanner extends StatelessWidget {
  const _UpcomingEmiBanner({
    required this.count,
    required this.total,
    required this.onTap,
  });

  final int count;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'এই সপ্তাহে ${BanglaFormatters.count(count)} টি কিস্তি, মোট ${BanglaFormatters.currency(total)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.secondaryTextColor),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});

  final DebtFilterType selected;
  final ValueChanged<DebtFilterType> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<(DebtFilterType, String, IconData?, Color)> items = [
      (DebtFilterType.all, 'সব', null, context.appColors.primary),
      (
        DebtFilterType.theyOwe,
        'পাওনা',
        Icons.arrow_downward_rounded,
        AppColors.success,
      ),
      (
        DebtFilterType.iOwe,
        'দেনা',
        Icons.arrow_upward_rounded,
        AppColors.error,
      ),
      (
        DebtFilterType.active,
        'সক্রিয়',
        Icons.radio_button_checked_rounded,
        context.appColors.primary,
      ),
      (
        DebtFilterType.emiOnly,
        'কিস্তি',
        Icons.calendar_month_rounded,
        context.appColors.primary,
      ),
      (
        DebtFilterType.regularOnly,
        'সাধারণ',
        Icons.receipt_long_rounded,
        context.appColors.primary,
      ),
      (
        DebtFilterType.settled,
        'পরিশোধিত',
        Icons.check_circle_rounded,
        AppColors.success,
      ),
      (
        DebtFilterType.overdue,
        'মেয়াদোত্তীর্ণ',
        Icons.warning_amber_rounded,
        AppColors.error,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            AppChip(
              label: items[index].$2,
              icon: items[index].$3,
              color: items[index].$4,
              selected: selected == items[index].$1,
              onTap: () => onChanged(items[index].$1),
            ),
            if (index != items.length - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _DebtListCard extends ConsumerWidget {
  const _DebtListCard({required this.debt});

  final DebtEntity debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = resolveDebtStatus(debt);
    final isMuted =
        status == DebtStatus.settled || status == DebtStatus.cancelled;

    final content = AppCard(
      onTap: () async {
        final result = await Navigator.of(context).push<MutationResult>(
          AppSlideRoute(builder: (_) => DebtDetailScreen(debtId: debt.id)),
        );
        if (result != null && context.mounted) {
          showDebtMutationResultSnackBar(context, result);
        }
      },
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
                      debt.personName,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: context.primaryTextColor,
                      ),
                    ),
                    if (!debt.isEMI &&
                        debt.personPhone != null &&
                        debt.personPhone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: context.secondaryTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              debt.personPhone!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.end,
                children: [
                  AppChip(
                    label: debt.type.labelBn,
                    color: debt.type.accentColor,
                    compact: true,
                  ),
                  if (debt.isEMI)
                    AppChip(
                      label: 'কিস্তি',
                      color: context.appColors.primary,
                      compact: true,
                    ),
                  AppChip(
                    label: status.labelBn,
                    color: status.accentColor,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _AmountColumn(
                  label: 'বাকি আছে',
                  amount: debt.remainingAmount,
                  isIncome: debt.type == DebtType.theyOwe,
                  isExpense: debt.type == DebtType.iOwe,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _AmountColumn(
                  label: 'মূল পরিমাণ',
                  amount: debt.originalAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: (debt.progressPercentage / 100).clamp(0.0, 1.0),
            color: debt.isEMI
                ? context.appColors.primary
                : debt.type.accentColor,
            showLabel: true,
            label: debt.isEMI
                ? 'কিস্তি ${BanglaFormatters.count(debt.paidInstallments)}/${BanglaFormatters.count(debt.totalInstallments)}'
                : 'পরিশোধ ${BanglaFormatters.currency(debt.paidAmount)}',
          ),
          const SizedBox(height: AppSpacing.md),
          if (debt.isEMI)
            Text(
              '${BanglaFormatters.count(debt.paidInstallments)}/${BanglaFormatters.count(debt.totalInstallments)} কিস্তি · মাসিক ${BanglaFormatters.currency(debt.emiAmount)} · পরবর্তী: ${debt.nextInstallmentDate == null ? 'নির্ধারিত নয়' : BanglaFormatters.dayMonth(debt.nextInstallmentDate!)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: status == DebtStatus.overdue
                    ? AppColors.error
                    : context.secondaryTextColor,
                fontWeight: status == DebtStatus.overdue
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            )
          else if (debt.dueDate != null)
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: status == DebtStatus.overdue
                      ? AppColors.error
                      : context.secondaryTextColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'তারিখ: ${BanglaFormatters.fullDate(debt.dueDate!)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: status == DebtStatus.overdue
                          ? AppColors.error
                          : context.secondaryTextColor,
                      fontWeight: status == DebtStatus.overdue
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          if (status == DebtStatus.overdue) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              debt.isEMI ? 'কিস্তির সময় পেরিয়ে গেছে' : 'মেয়াদ পেরিয়ে গেছে',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: isMuted ? 0.76 : 1,
      child: status == DebtStatus.overdue
          ? Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardAll,
                border: const Border(
                  left: BorderSide(color: AppColors.error, width: 4),
                ),
              ),
              child: content,
            )
          : content,
    );
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({
    required this.label,
    required this.amount,
    this.isIncome = false,
    this.isExpense = false,
  });

  final String label;
  final double amount;
  final bool isIncome;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 4),
        AppAmountText(
          amount: amount,
          isIncome: isIncome,
          isExpense: isExpense,
          style: AppTextStyles.titleMedium,
        ),
      ],
    );
  }
}
