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

  test('parseExpenseFromResponse detects split metadata', () {
    const response =
        '[{"amount":800,"category":"Food","description":"দলের খাবার","date":"today","isSplit":true,"splitPersons":4}]\nSplit করবেন?';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.isSplit, isTrue);
    expect(result.splitPersons, 4);
    expect(result.expenses.single.isSplit, isTrue);
    expect(result.expenses.single.splitPersons, 4);
    expect(result.conversationalText, 'Split করবেন?');
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

  test('extractVisibleReplyText returns conversational text from json payload', () {
    const response =
        '{"text":"খরচটা যোগ করব?","expenses":[{"amount":60,"category":"Transport","description":"রিকশা","date":"today"}],"incomes":[]}';

    final visibleText = parser.extractVisibleReplyText(response);

    expect(visibleText, 'খরচটা যোগ করব?');
  });

  test('extractVisibleReplyText removes invalid json and keeps plain text', () {
    const response = '[{"amount":30,"category":"Food",]\nঠিক বুঝিনি';

    final visibleText = parser.extractVisibleReplyText(response);

    expect(visibleText, 'ঠিক বুঝিনি');
  });

  test('extractVisibleStreamingText hides partial json fragments', () {
    const response = '{"expenses":[{"amount":30';

    final visibleText = parser.extractVisibleStreamingText(response);

    expect(visibleText, isEmpty);
  });

  test('extractVisibleStreamingText keeps natural text before partial json', () {
    const response = 'ঠিক আছে\n{"expenses":[{"amount":30';

    final visibleText = parser.extractVisibleStreamingText(response);

    expect(visibleText, 'ঠিক আছে');
  });

  test('parseExpenseFromResponse preserves split metadata in object payloads', () {
    const response =
        '{"expenses":[{"amount":800,"category":"Food","description":"দলের খাবার","date":"2026-01-14","isSplit":true,"splitPersons":4}],"incomes":[],"text":"split bill বানাবো?"}';

    final result = parser.parseExpenseFromResponse(response);

    expect(result.isExpense, isTrue);
    expect(result.isMultiple, isFalse);
    expect(result.isSplit, isTrue);
    expect(result.splitPersons, 4);
    expect(result.expenses, hasLength(1));
    expect(result.expenses.single.isSplit, isTrue);
    expect(result.expenses.single.splitPersons, 4);
    expect(result.conversationalText, 'split bill বানাবো?');
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
