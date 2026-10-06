import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../income/presentation/providers/income_providers.dart';
import '../../domain/recent_activity.dart';
import 'expense_providers.dart';

/// What Home needs about transactions, in one place.
class HomeActivity {
  const HomeActivity({required this.recent, required this.hasAny});

  /// Newest 5 expense+income movements.
  final List<RecentActivityItem> recent;

  /// False only when there are ZERO expenses AND ZERO income — the first-run
  /// state. (`DashboardData.recentExpenses` is the newest 10 of ALL expenses, and
  /// the income list is every income, so empty here really means none exist.)
  final bool hasAny;
}

/// Merged expense + income feed. Read-only. Waits for the dashboard (expenses);
/// income loading/failing degrades to "no income" rather than blocking Home.
final homeActivityProvider = Provider<AsyncValue<HomeActivity>>((ref) {
  final dashboard = ref.watch(dashboardControllerProvider);
  final income = ref.watch(incomeListControllerProvider);

  final data = dashboard.valueOrNull;
  if (data == null) {
    return dashboard.hasError
        ? AsyncValue.error(
            dashboard.error!,
            dashboard.stackTrace ?? StackTrace.empty,
          )
        : const AsyncValue.loading();
  }
  if (income.isLoading && !income.hasValue) {
    return const AsyncValue.loading();
  }

  final incomes = income.valueOrNull ?? const [];
  final recent = mergeRecentActivity(
    expenses: data.recentExpenses,
    incomes: incomes,
  );
  return AsyncValue.data(
    HomeActivity(
      recent: recent,
      hasAny: data.recentExpenses.isNotEmpty || incomes.isNotEmpty,
    ),
  );
});
