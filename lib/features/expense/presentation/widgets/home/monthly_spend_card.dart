import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/spending_delta.dart';
import '../../providers/expense_providers.dart';

/// এই মাসের খরচ — resets monthly — with "গত মাসের এই সময়ের চেয়ে X% কম/বেশি"
/// (month so far vs the same days last month) and an "আয় · নিট" line.
class MonthlySpendCard extends ConsumerWidget {
  const MonthlySpendCard({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardControllerProvider).valueOrNull;
    if (data == null) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    // Like with like: this month so far vs last month's SAME days (never last
    // month's full total, which would read "less" every month start).
    final delta = spendingDelta(
      thisMonth: data.thisMonthToDateTotal,
      lastMonth: data.lastMonthSamePeriodTotal,
    );
    final cashFlow = ref.watch(cashFlowProvider).valueOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'এই মাসের খরচ',
                  style: AppTextStyles.bodyMedium.copyWith(color: tokens.muted),
                ),
              ),
              Text(
                BanglaFormatters.monthYear(now ?? DateTime.now()),
                style: AppTextStyles.bodySmall.copyWith(color: tokens.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                BanglaFormatters.currency(data.thisMonthTotal),
                style: AppTextStyles.displayMedium.copyWith(color: tokens.ink),
              ),
              if (delta != null) _DeltaChip(delta: delta),
            ],
          ),
          // আয় · নিট for the month, from the existing cash-flow figures. Hidden
          // with no income: "নিট" would then just repeat the spending above.
          if (cashFlow != null && cashFlow.income > 0) ...[
            const SizedBox(height: 6),
            _IncomeNetLine(income: cashFlow.income, net: cashFlow.netFlow),
          ],
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final SpendingDelta delta;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Green = spent less; muted (not alarm-red) = spent more.
    final less = delta.trend == SpendingTrend.less;
    final same = delta.trend == SpendingTrend.same;
    final background = less ? tokens.successSoft : tokens.surface2;
    final foreground = less ? tokens.successText : tokens.muted;

    final percent = BanglaFormatters.count(delta.displayPercent);
    final label = same
        ? 'গত মাসের এই সময়ের প্রায় সমান'
        : 'গত মাসের এই সময়ের চেয়ে $percent%${delta.isCapped ? '+' : ''} ${less ? 'কম' : 'বেশি'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!same) ...[
            Icon(
              less ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 14,
              color: foreground,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeNetLine extends StatelessWidget {
  const _IncomeNetLine({required this.income, required this.net});

  final double income;
  final double net;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final base = AppTextStyles.bodySmall.copyWith(color: tokens.muted);
    final strong = base.copyWith(
      color: tokens.ink,
      fontWeight: FontWeight.w700,
    );
    // Calm, not alarming: a negative net is just a "−", not a red warning.
    final netText =
        '${net < 0 ? '−' : ''}${BanglaFormatters.currency(net.abs())}';
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'আয় '),
          TextSpan(text: BanglaFormatters.currency(income), style: strong),
          const TextSpan(text: ' · নিট '),
          TextSpan(text: netText, style: strong),
        ],
      ),
    );
  }
}
