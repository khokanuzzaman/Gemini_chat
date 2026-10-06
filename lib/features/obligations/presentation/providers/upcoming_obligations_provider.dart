import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../debt/presentation/providers/debt_providers.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../domain/upcoming_obligation.dart';

/// "Today" for the obligations list; overridden in tests.
final obligationsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Everything due in the next 30 days (plus anything overdue), recurring entries
/// and debt instalments merged, de-duplicated and date-sorted. Read-only: no new
/// data, no writes. Empty while either source is still loading.
///
/// Recomputes when recurring entries or debts change (and on Home refresh); it
/// does not tick at midnight on its own.
final upcomingObligationsProvider = Provider<UpcomingObligations>((ref) {
  final recurring = ref.watch(recurringProvider).valueOrNull;
  final debtState = ref.watch(debtListProvider).valueOrNull;
  if (recurring == null && debtState == null) {
    return const UpcomingObligations.empty();
  }
  return mergeUpcomingObligations(
    today: ref.watch(obligationsClockProvider)(),
    recurring: recurring ?? const [],
    debts: debtState?.debts ?? const [],
  );
});
