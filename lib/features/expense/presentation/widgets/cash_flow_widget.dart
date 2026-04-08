import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../income/presentation/screens/income_list_screen.dart';
import '../providers/expense_providers.dart';
import 'savings_rate_info_sheet.dart';

class CashFlowWidget extends ConsumerWidget {
  const CashFlowWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlowAsync = ref.watch(cashFlowProvider);

    return cashFlowAsync.when(
      loading: () => const ShimmerBox(height: 170, radius: 20),
      error: (error, _) => _ErrorCard(
        onRetry: () => ref.invalidate(cashFlowProvider),
      ),
      data: (data) {
        if (data.income == 0 && data.expense == 0) {
          return _EmptyCard(
            onIncomeTap: () {
              Navigator.of(context).push(
                buildAppRoute(const IncomeListScreen()),
              );
            },
            onExpenseTap: () async {
              await _openThisMonthExpenses(ref);
              if (!context.mounted) {
                return;
              }
              AppShellNavigation.openExpenses();
            },
          );
        }

        final netFlow = data.netFlow;
        final savingsRate = data.savingsRate;
        final netFlowColor = netFlow >= 0 ? AppColors.success : AppColors.error;
        final rateColor = savingsRate >= 20
            ? AppColors.success
            : (savingsRate >= 0 ? AppColors.warning : AppColors.error);
        final changePercent = data.netFlowChangePercent;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, size: 18),
                  const SizedBox(width: 8),
                  const Text('ক্যাশ ফ্লো', style: AppTextStyles.titleMedium),
                  const SizedBox(width: 6),
                  Text(
                    'এই মাস',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          buildAppRoute(const IncomeListScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _AmountCell(
                        label: 'আয়',
                        amount: data.income,
                        color: AppColors.success,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await _openThisMonthExpenses(ref);
                        if (!context.mounted) {
                          return;
                        }
                        AppShellNavigation.openExpenses();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: _AmountCell(
                        label: 'খরচ',
                        amount: data.expense,
                        color: AppColors.error,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: context.borderColor),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showSavingsRateInfo(context, savingsRate),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Text('নিট সঞ্চয়', style: AppTextStyles.bodyMedium),
                      const Spacer(),
                      Text(
                        '${netFlow >= 0 ? '+' : '-'}${BanglaFormatters.currency(netFlow.abs())}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: netFlowColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RateChip(
                        color: rateColor,
                        label:
                            '${BanglaFormatters.count(savingsRate.round())}% সঞ্চয়',
                      ),
                    ],
                  ),
                ),
              ),
              if (data.lastMonthIncome != 0 || data.lastMonthExpense != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        changePercent >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color:
                            changePercent >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'গত মাসের তুলনায় ${BanglaFormatters.count(changePercent.abs().round())}% '
                        '${changePercent >= 0 ? 'বেশি' : 'কম'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openThisMonthExpenses(WidgetRef ref) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    final controller = ref.read(expenseListControllerProvider.notifier);
    await controller.clearFilters();
    await controller.setDateRange(start, end);
  }

  void _showSavingsRateInfo(BuildContext context, double rate) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SavingsRateInfoSheet(rate: rate),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(
                BanglaFormatters.currency(amount),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onIncomeTap, required this.onExpenseTap});

  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ক্যাশ ফ্লো', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'এখনো কোনো তথ্য নেই',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onIncomeTap,
                  child: const Text('আয় যোগ করুন'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onExpenseTap,
                  child: const Text('খরচ যোগ করুন'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          const Expanded(child: Text('ক্যাশ ফ্লো লোড করা যায়নি')),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
