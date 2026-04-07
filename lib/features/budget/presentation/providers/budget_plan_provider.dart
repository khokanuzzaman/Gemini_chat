import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_plan_entity.dart';
import 'budget_provider.dart';

export 'budget_provider.dart';

final budgetPlanProvider = Provider<BudgetPlanEntity?>((ref) {
  return ref.watch(budgetProvider).activeBudget;
});
