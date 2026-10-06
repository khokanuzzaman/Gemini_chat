import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_source.dart';
import 'package:gemini_chat/features/expense/domain/recent_activity.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';

ExpenseEntity _expense(
  String title,
  DateTime date, {
  int? id,
  double amount = 100,
  ExpenseSource source = ExpenseSource.expense,
  String category = 'Food',
}) {
  return ExpenseEntity(
    id: id,
    amount: amount,
    category: category,
    description: title,
    date: date,
    sourceType: source,
  );
}

IncomeEntity _income(
  String title,
  DateTime date, {
  int? id,
  double amount = 500,
}) {
  return IncomeEntity(
    id: id,
    amount: amount,
    source: 'Salary',
    description: title,
    date: date,
    createdAt: date,
  );
}

void main() {
  final base = DateTime(2026, 10, 6, 12);

  test('merges expenses and income, newest first', () {
    final items = mergeRecentActivity(
      expenses: [
        _expense('old lunch', base.subtract(const Duration(days: 3))),
        _expense('tea', base.subtract(const Duration(hours: 1))),
      ],
      incomes: [_income('salary', base.subtract(const Duration(days: 1)))],
    );
    expect(items.map((i) => i.title), ['tea', 'salary', 'old lunch']);
    expect(items.map((i) => i.kind), [
      ActivityKind.expense,
      ActivityKind.income,
      ActivityKind.expense,
    ]);
  });

  test('keeps only the newest [limit] (default 5)', () {
    final items = mergeRecentActivity(
      expenses: [
        for (var i = 0; i < 5; i++)
          _expense('e$i', base.subtract(Duration(days: i * 2))),
      ],
      incomes: [
        for (var i = 0; i < 5; i++)
          _income('i$i', base.subtract(Duration(days: i * 2 + 1))),
      ],
    );
    expect(items, hasLength(5));
    expect(items.map((i) => i.title), ['e0', 'i0', 'e1', 'i1', 'e2']);
    expect(mergeRecentActivity(expenses: const [], incomes: const []), isEmpty);
  });

  test(
    'an old expense is not pushed out by a flood of older income, and vice versa',
    () {
      final items = mergeRecentActivity(
        expenses: [
          _expense('yesterday', base.subtract(const Duration(days: 1))),
        ],
        incomes: [
          for (var i = 0; i < 10; i++)
            _income('old $i', base.subtract(Duration(days: 30 + i))),
        ],
        limit: 3,
      );
      expect(items.first.title, 'yesterday');
    },
  );

  test('EMI (debt payment) is flagged; goal/ordinary expenses are not', () {
    final items = mergeRecentActivity(
      expenses: [
        _expense(
          'City Bank',
          base,
          id: 1,
          source: ExpenseSource.debtPayment,
          category: 'EMI',
        ),
        _expense('lunch', base.subtract(const Duration(hours: 1)), id: 2),
      ],
      incomes: const [],
    );
    expect(items.map((i) => i.isEmi), [true, false]);
  });

  test('empty description falls back to the category / source', () {
    final items = mergeRecentActivity(
      expenses: [_expense('  ', base, category: 'Transport')],
      incomes: [_income('', base.subtract(const Duration(days: 1)))],
    );
    expect(items.map((i) => i.title), ['Transport', 'Salary']);
  });

  test(
    'same instant: expense before income, then higher id — fully deterministic',
    () {
      final a = mergeRecentActivity(
        expenses: [_expense('x1', base, id: 1), _expense('x2', base, id: 2)],
        incomes: [_income('i1', base, id: 9)],
      );
      final b = mergeRecentActivity(
        expenses: [_expense('x2', base, id: 2), _expense('x1', base, id: 1)],
        incomes: [_income('i1', base, id: 9)],
      );
      expect(a.map((i) => i.title), ['x2', 'x1', 'i1']);
      expect(b.map((i) => i.title), a.map((i) => i.title));
    },
  );
}
