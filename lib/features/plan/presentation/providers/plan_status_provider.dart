import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../debt/presentation/providers/debt_providers.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../obligations/domain/upcoming_obligation.dart';
import '../../../obligations/presentation/providers/upcoming_obligations_provider.dart';
import '../../../recurring/presentation/providers/recurring_provider.dart';
import '../../domain/plan_status.dart';

/// The live line under each প্ল্যান card, composed from providers that already
/// exist — nothing is computed here but wording (see `plan_status.dart`).
/// A null status means "still loading": the card shows its title alone rather
/// than flashing a wrong "০" / "ঠিক করুন".
class PlanHubStatus {
  const PlanHubStatus({
    this.budget,
    this.goals,
    this.debt,
    this.recurring,
    this.upcoming,
  });

  final HubStatus? budget;
  final HubStatus? goals;
  final HubStatus? debt;
  final HubStatus? recurring;

  /// Null = nothing coming (the strip is not drawn).
  final HubStatus? upcoming;
}

final planHubStatusProvider = Provider<PlanHubStatus>((ref) {
  final budgetState = ref.watch(budgetProvider);
  final spent = ref
      .watch(dashboardControllerProvider)
      .valueOrNull
      ?.thisMonthTotal;
  final goals = ref.watch(goalProvider);
  final debtState = ref.watch(debtListProvider);
  final debt = ref.watch(debtSummaryProvider);
  final recurring = ref.watch(recurringProvider).valueOrNull;
  final upcoming = ref.watch(upcomingObligationsProvider);

  UpcomingObligation? nextRecurring;
  for (final item in upcoming.items) {
    if (item.kind == ObligationKind.recurring && !item.isOverdue) {
      nextRecurring = item;
      break;
    }
  }

  return PlanHubStatus(
    // Home's budget row compares the same two numbers.
    budget: budgetState.isLoading || spent == null
        ? null
        : budgetStatus(
            budgeted: budgetState.activeBudget?.totalBudgeted,
            spent: spent,
          ),
    goals: goals.isLoading
        ? null
        : goalsStatus(active: goals.activeGoals.length),
    debt: debtState.hasValue
        ? debtStatus(
            active: debt.activeCount,
            overdue: debt.overdueCount,
            iOwe: debt.totalIOwe,
            owedToMe: debt.totalOwedToMe,
          )
        : null,
    recurring: recurring == null
        ? null
        : recurringStatus(
            active: recurring.where((entry) => entry.isActive).length,
            next: nextRecurring,
          ),
    upcoming: upcomingStripStatus(upcoming),
  );
});
