import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';

import 'package:gemini_chat/core/ai/rag_context_builder.dart';
import 'package:gemini_chat/core/database/expense_local_datasource.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';

class _StubIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeExpenseLocalDataSource extends ExpenseLocalDataSource {
  _FakeExpenseLocalDataSource(this._expenses) : super(_StubIsar());

  final List<ExpenseRecordModel> _expenses;

  @override
  Future<List<ExpenseRecordModel>> getThisMonthExpenses() async {
    final now = DateTime.now();
    return _forMonth(DateTime(now.year, now.month, 1));
  }

  @override
  Future<List<ExpenseRecordModel>> getTodayExpenses() async {
    final today = DateTime.now();
    return _expenses
        .where(
          (expense) =>
              expense.date.year == today.year &&
              expense.date.month == today.month &&
              expense.date.day == today.day,
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseRecordModel>> getLastMonthExpenses() async {
    final now = DateTime.now();
    final month = now.month == 1
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    return _forMonth(month);
  }

  @override
  Future<List<ExpenseRecordModel>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return _expenses
        .where(
          (expense) =>
              !expense.date.isBefore(start) && !expense.date.isAfter(endOfDay),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ExpenseRecordModel>> getExpensesForMonth(DateTime month) async {
    return _forMonth(month);
  }

  List<ExpenseRecordModel> _forMonth(DateTime month) {
    return _expenses
        .where(
          (expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .toList(growable: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  test('RAG builder resolves english month with current year', () async {
    final currentYear = DateTime.now().year;
    final builder = RagContextBuilder(
      localDataSource: _FakeExpenseLocalDataSource([
        _expense(
          amount: 300,
          category: 'Food',
          description: 'লাঞ্চ',
          date: DateTime(currentYear, 3, 2),
        ),
        _expense(
          amount: 200,
          category: 'Transport',
          description: 'রিকশা',
          date: DateTime(currentYear, 3, 3),
        ),
        _expense(
          amount: 900,
          category: 'Shopping',
          description: 'এপ্রিল বাজার',
          date: DateTime(currentYear, 4, 3),
        ),
      ]),
    );

    final context = await builder.buildContext('march মাসের খরচ কত?');

    expect(context, isNotNull);
    expect(context!.data.periodTotal, 500);
    expect(context.data.transactionCount, 2);
    expect(context.data.monthName, contains('মার্চ'));
    expect(context.textForAi, contains('মোট খরচ: ৳ ৫০০'));
  });

  test('RAG builder resolves explicit english month and year', () async {
    final builder = RagContextBuilder(
      localDataSource: _FakeExpenseLocalDataSource([
        _expense(
          amount: 1200,
          category: 'Shopping',
          description: 'মার্চ ২০২৫ বাজার',
          date: DateTime(2025, 3, 4),
        ),
        _expense(
          amount: 700,
          category: 'Food',
          description: 'মার্চ ২০২৬ লাঞ্চ',
          date: DateTime(2026, 3, 4),
        ),
      ]),
    );

    final context = await builder.buildContext('march 2025 মাসের খরচ কত?');

    expect(context, isNotNull);
    expect(context!.data.periodTotal, 1200);
    expect(context.data.monthName, contains('২০২৫'));
    expect(context.textForAi, contains('মোট খরচ: ৳ ১,২০০'));
  });

  test('RAG builder resolves Bangla year then month', () async {
    final builder = RagContextBuilder(
      localDataSource: _FakeExpenseLocalDataSource([
        _expense(
          amount: 450,
          category: 'Bill',
          description: 'ফেব্রুয়ারি ২০২৫ বিল',
          date: DateTime(2025, 2, 10),
        ),
        _expense(
          amount: 300,
          category: 'Food',
          description: 'ফেব্রুয়ারি ২০২৬ নাস্তা',
          date: DateTime(2026, 2, 10),
        ),
      ]),
    );

    final context = await builder.buildContext(
      '২০২৫ সালের ফেব্রুয়ারি মাসের খরচ কত?',
    );

    expect(context, isNotNull);
    expect(context!.data.periodTotal, 450);
    expect(context.data.monthName, contains('ফেব্রুয়ার'));
    expect(context.data.monthName, contains('২০২৫'));
  });
}

ExpenseRecordModel _expense({
  required int amount,
  required String category,
  required String description,
  required DateTime date,
}) {
  return ExpenseRecordModel()
    ..amount = amount
    ..category = category
    ..description = description
    ..date = date;
}
