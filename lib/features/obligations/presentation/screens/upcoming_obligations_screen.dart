import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_page_route.dart';
import '../../../../core/navigation/app_shell_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/bangla_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../recurring/presentation/screens/recurring_screen.dart';
import '../../domain/obligation_groups.dart';
import '../../domain/upcoming_obligation.dart';
import '../providers/upcoming_obligations_provider.dart';

/// "আসন্ন পরিশোধ" — the full, read-only list behind the প্ল্যান strip and Home's
/// "আসছে" row: everything due in the next 30 days plus anything overdue, grouped by
/// how soon. It only READS `upcomingObligationsProvider` (the G4 combiner); a tap
/// deep-links to the debt or the recurring entry, exactly like Home.
class UpcomingObligationsScreen extends ConsumerWidget {
  const UpcomingObligationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingObligationsProvider);
    final today = ref.watch(obligationsClockProvider)();
    final groups = groupObligations(upcoming.items, today: today);

    return AppPageScaffold(
      title: 'আসন্ন পরিশোধ',
      body: groups.isEmpty
          ? const AppEmptyState(
              icon: Icons.event_available_rounded,
              title: 'আগামী ৩০ দিনে কিছু বাকি নেই',
              subtitle: 'ঋণের কিস্তি আর নিয়মিত খরচ এখানে দেখা যাবে',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                for (final (index, group) in groups.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.lg),
                  _GroupHeader(group: group),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (final (i, item) in group.items.indexed) ...[
                          _ObligationRow(item: item),
                          if (i != group.items.length - 1)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: context.tokens.line,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final ObligationGroup group;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final overdue = group.section == ObligationSection.overdue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.section.label,
              style: AppTextStyles.titleMedium.copyWith(
                color: overdue ? tokens.dangerText : tokens.ink,
              ),
            ),
          ),
          Text(
            BanglaFormatters.currency(group.total),
            style: AppTextStyles.bodySmall.copyWith(
              color: overdue ? tokens.dangerText : tokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationRow extends StatelessWidget {
  const _ObligationRow({required this.item});

  final UpcomingObligation item;

  void _open(BuildContext context) {
    if (item.kind == ObligationKind.debt) {
      AppShellNavigation.openDebtDetail(item.sourceId);
    } else {
      Navigator.of(context).push(buildAppRoute(const RecurringScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // The section header already says "মেয়াদ পেরিয়েছে"; the row gives the date.
    final when = BanglaFormatters.dayMonthLong(item.dueDate);
    final kindLabel = item.isEmi
        ? 'কিস্তি'
        : item.kind == ObligationKind.debt
        ? 'ঋণ'
        : 'নিয়মিত';
    return Semantics(
      button: true,
      label: '${item.title}, $when, ${BanglaFormatters.currency(item.amount)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              HubIcon(
                size: 40,
                icon: item.kind == ObligationKind.debt
                    ? Icons.handshake_rounded
                    : Icons.repeat_rounded,
                accent: item.kind == ObligationKind.debt
                    ? HubAccent.brass
                    : HubAccent.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: tokens.ink,
                      ),
                    ),
                    Text(
                      '$kindLabel · $when',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: item.isOverdue
                            ? tokens.dangerText
                            : tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    BanglaFormatters.currency(item.amount),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: tokens.expenseText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
