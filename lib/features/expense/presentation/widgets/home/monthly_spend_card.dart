import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/spending_delta.dart';
import '../../providers/expense_providers.dart';

/// এই মাসের খরচ — resets monthly — with "গত মাসের চেয়ে X% কম/বেশি".
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
    final delta = spendingDelta(
      thisMonth: data.thisMonthTotal,
      lastMonth: data.lastMonthTotal,
    );

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
        ? 'গত মাসের প্রায় সমান'
        : 'গত মাসের চেয়ে $percent%${delta.isCapped ? '+' : ''} ${less ? 'কম' : 'বেশি'}';

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
