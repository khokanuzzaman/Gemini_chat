import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/ai/expense_parser.dart';
import 'package:gemini_chat/core/ai/expense_result.dart';

void main() {
  const parser = ExpenseParser();

  test('parseExpenseFromResponse parses single expense json', () {
    const response =
        '[{"amount":60,"category":"Transport","description":"রিকশা","date":"today"}]\nSave করব?';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.isMultiple, isFalse);
    expect(result.expenses, hasLength(1));
    expect(result.expenses.first.amount, 60);
    expect(result.expenses.first.category, 'Transport');
    expect(result.conversationalText, 'Save করব?');
  });

  test('parseExpenseFromResponse parses multiple expense json', () {
    const response =
        '[{"amount":30,"category":"Food","description":"নাস্তা","date":"today"},'
        '{"amount":200,"category":"Food","description":"লাঞ্চ","date":"today"}]\n'
        'দুটোই save করব?';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.isMultiple, isTrue);
    expect(result.expenses, hasLength(2));
    expect(result.expenses.map((e) => e.amount), [30, 200]);
    expect(result.conversationalText, 'দুটোই save করব?');
  });

  test('parseExpenseFromResponse returns non-expense when no json exists', () {
    const response = 'ভালো আছি! আপনি কেমন আছেন?';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isFalse);
    expect(result.expenses, isEmpty);
    expect(result.conversationalText, response);
  });

  test('parseExpenseFromResponse falls back gracefully on invalid json', () {
    const response = '[{"amount":30,"category":"Food",]\nঠিক বুঝিনি';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isFalse);
    expect(result.expenses, isEmpty);
    expect(result.conversationalText, response);
  });

  test('ExpenseData parses past date strings correctly', () {
    final expense = ExpenseData.fromJson({
      'amount': 30,
      'category': 'Food',
      'description': 'নাস্তা',
      'date': '2/02/2026',
    });

    expect(expense.parsedDate, DateTime(2026, 2, 2));
    expect(expense.isoDate, '2026-02-02');
  });

  test('ExpenseData resolves গতকাল to yesterday', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final expense = ExpenseData.fromJson({
      'amount': 60,
      'category': 'Transport',
      'description': 'রিকশা',
      'date': 'গতকাল',
    });

    expect(ExpenseData.isSameDay(expense.parsedDate, yesterday), isTrue);
  });

  test('ExpenseData parses Bengali amount strings', () {
    final expense = ExpenseData.fromJson({
      'amount': '২,৩০০',
      'category': 'Healthcare',
      'description': 'ওষুধ',
      'date': 'today',
    });

    expect(expense.amount, 2300);
  });
}
