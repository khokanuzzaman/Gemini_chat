import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/repositories/expense_repository.dart';
import 'package:gemini_chat/features/expense/domain/usecases/get_dashboard_data_usecase.dart';

class _MockRepo extends Mock implements ExpenseRepository {}

ExpenseEntity _e(DateTime date, double amount) => ExpenseEntity(
  amount: amount,
  category: 'Food',
  description: 'x',
  date: date,
);

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2026)));

  test('carries a like-with-like pair next to the full-month totals', () async {
    final repo = _MockRepo();
    final thisMonth = [
      _e(DateTime(2026, 10, 2), 1000),
      _e(DateTime(2026, 10, 5), 500),
      _e(
        DateTime(2026, 10, 20),
        8000,
      ), // future-dated: in the month, not so far
    ];
    final lastMonth = [
      _e(DateTime(2026, 9, 3), 1200),
      _e(DateTime(2026, 9, 6), 300),
      _e(DateTime(2026, 9, 25), 40000),
    ];
    when(repo.getThisMonthExpenses).thenAnswer((_) async => thisMonth);
    when(repo.getLastMonthExpenses).thenAnswer((_) async => lastMonth);
    when(repo.getTodayExpenses).thenAnswer((_) async => const []);
    when(
      repo.getAllExpenses,
    ).thenAnswer((_) async => [...thisMonth, ...lastMonth]);
    when(
      () => repo.getExpensesByDateRange(any(), any()),
    ).thenAnswer((_) async => const []);

    final data = await GetDashboardDataUseCase(
      repo,
    ).call(now: DateTime(2026, 10, 6, 10));

    // Unchanged full-month figures (other screens rely on them).
    expect(data.thisMonthTotal, 9500);
    expect(data.lastMonthTotal, 41500);
    // The chip's basis: days 1..6 on both sides.
    expect(data.thisMonthToDateTotal, 1500);
    expect(data.lastMonthSamePeriodTotal, 1500);
  });
}
