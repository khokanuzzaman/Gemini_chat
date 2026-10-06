import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/bangla_formatters.dart';
import '../../../domain/day_groups.dart';
import '../../../domain/recent_activity.dart';
import '../home/home_recent_card.dart';

/// One row of the খরচ / আয় list, already mapped to display strings so the lazy
/// list builder does no lookups. [source] is the original entity the screen
/// handed in (ExpenseEntity / IncomeEntity); it is only passed back to the
/// screen's tap/delete callbacks.
class ActivityEntry {
  const ActivityEntry({
    required this.item,
    required this.subtitle,
    required this.time,
    required this.source,
    this.locked = false,
  });

  final RecentActivityItem item;
  final String subtitle;
  final String time;
  final Object source;

  /// Owned by another feature (EMI / goal): read-only, never swipe-deletes.
  final bool locked;

  /// Stable per record (kind + id), so rebuilds and swipes keep row identity.
  String get rowKey => '${item.kind.name}-${item.id}';

  DateTime get date => item.date;
  double get amount => item.amount;
}

/// Flat, lazily-buildable view of day groups: a header then its rows.
sealed class ActivityListItem {
  const ActivityListItem();
}

class ActivityHeaderItem extends ActivityListItem {
  const ActivityHeaderItem(this.group, {required this.isFirstGroup});
  final DayGroup<ActivityEntry> group;
  final bool isFirstGroup;
}

class ActivityRowItem extends ActivityListItem {
  const ActivityRowItem(
    this.entry, {
    required this.isFirst,
    required this.isLast,
  });
  final ActivityEntry entry;
  final bool isFirst;
  final bool isLast;
}

/// Groups entries by day (newest first, with the daily subtotal) and flattens to
/// header + row items. Pure; the screens memoize the result per data/search
/// change, so scrolling never regroups.
List<ActivityListItem> buildActivityItems(Iterable<ActivityEntry> entries) {
  final groups = groupByDay<ActivityEntry>(
    entries,
    dateOf: (e) => e.date,
    amountOf: (e) => e.amount,
  );
  return [
    for (final (g, group) in groups.indexed) ...[
      ActivityHeaderItem(group, isFirstGroup: g == 0),
      for (final (i, entry) in group.items.indexed)
        ActivityRowItem(
          entry,
          isFirst: i == 0,
          isLast: i == group.items.length - 1,
        ),
    ],
  ];
}

/// The lazy list. Only rows near the viewport are built, so a year of SMS
/// imports (thousands of rows) costs the same as a handful.
class SliverActivityList extends StatelessWidget {
  const SliverActivityList({
    super.key,
    required this.items,
    required this.isIncome,
    required this.onTap,
    required this.onDelete,
  });

  final List<ActivityListItem> items;
  final bool isIncome;
  final void Function(ActivityEntry entry) onTap;

  /// Asks the screen to confirm + delete (or open the read-only sheet for a
  /// locked row). Never deletes by itself.
  final Future<void> Function(ActivityEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return switch (item) {
          ActivityHeaderItem() => ActivityDayHeader(
            key: ValueKey('day-${item.group.day.millisecondsSinceEpoch}'),
            group: item.group,
            isIncome: isIncome,
            isFirstGroup: item.isFirstGroup,
          ),
          ActivityRowItem() => _ActivityRowShell(
            key: ValueKey(item.entry.rowKey),
            entry: item.entry,
            isFirst: item.isFirst,
            isLast: item.isLast,
            onTap: onTap,
            onDelete: onDelete,
          ),
        };
      },
    );
  }
}

class ActivityDayHeader extends StatelessWidget {
  const ActivityDayHeader({
    super.key,
    required this.group,
    required this.isIncome,
    required this.isFirstGroup,
  });

  final DayGroup<ActivityEntry> group;
  final bool isIncome;
  final bool isFirstGroup;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final relative = BanglaFormatters.relativeDay(group.day);
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          4,
          isFirstGroup ? 0 : AppSpacing.lg,
          4,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: relative,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: tokens.ink,
                      ),
                    ),
                    // "আজকে / গতকাল" gets its date beside it; older days
                    // already ARE the date, so it is not repeated.
                    if (relative != BanglaFormatters.fullDate(group.day))
                      TextSpan(
                        text: '  ${BanglaFormatters.fullDate(group.day)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${isIncome ? '+' : ''}${BanglaFormatters.currency(group.total)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isIncome ? tokens.successText : tokens.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRowShell extends StatelessWidget {
  const _ActivityRowShell({
    super.key,
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  final ActivityEntry entry;
  final bool isFirst;
  final bool isLast;
  final void Function(ActivityEntry entry) onTap;
  final Future<void> Function(ActivityEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const radius = Radius.circular(16);
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? radius : Radius.zero,
      bottom: isLast ? radius : Radius.zero,
    );

    Widget row = HomeActivityRow(
      item: entry.item,
      subtitle: entry.subtitle,
      time: entry.time,
      locked: entry.locked,
      onTap: () => onTap(entry),
      onLongPress: () => onDelete(entry),
    );

    if (!entry.locked) {
      row = Dismissible(
        key: ValueKey('swipe-${entry.rowKey}'),
        direction: DismissDirection.endToStart,
        // The screen confirms; the row never leaves the list on its own.
        confirmDismiss: (_) async {
          await onDelete(entry);
          return false;
        },
        background: const SizedBox.shrink(),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          color: tokens.danger,
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: row,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: tokens.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFirst)
              Divider(height: 1, indent: 16, endIndent: 16, color: tokens.line),
            row,
          ],
        ),
      ),
    );
  }
}

/// "৳ মোট · N টি লেনদেন" — the list's one-line summary.
class ActivitySummaryLine extends StatelessWidget {
  const ActivitySummaryLine({
    super.key,
    required this.total,
    required this.count,
  });

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, AppSpacing.md),
      child: Text(
        '${BanglaFormatters.currency(total)} মোট · ${BanglaFormatters.count(count)}টি লেনদেন',
        style: AppTextStyles.bodySmall.copyWith(
          color: context.tokens.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
