import '../../features/expense/domain/entities/expense_entity.dart';
import '../database/expense_local_datasource.dart';
import '../database/models/expense_record_model.dart';
import '../utils/bangla_formatters.dart';

class RagContext {
  const RagContext({required this.textForAi, required this.data});

  final String textForAi;
  final RagStructuredData data;
}

class RagStructuredData {
  const RagStructuredData({
    required this.thisMonthTotal,
    required this.lastMonthTotal,
    required this.categoryTotals,
    required this.todayExpenses,
    required this.recentExpenses,
    required this.monthName,
    required this.transactionCount,
    required this.periodTotal,
    required this.periodExpenses,
    required this.lastMonthCategoryTotals,
    required this.lastMonthExpenses,
    required this.lastMonthName,
    required this.referenceDate,
  });

  final double thisMonthTotal;
  final double? lastMonthTotal;
  final Map<String, double> categoryTotals;
  final List<ExpenseEntity> todayExpenses;
  final List<ExpenseEntity> recentExpenses;
  final String monthName;
  final int transactionCount;
  final double periodTotal;
  final List<ExpenseEntity> periodExpenses;
  final Map<String, double> lastMonthCategoryTotals;
  final List<ExpenseEntity> lastMonthExpenses;
  final String? lastMonthName;
  final DateTime referenceDate;
}

class RagContextBuilder {
  const RagContextBuilder({required ExpenseLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ExpenseLocalDataSource _localDataSource;

  /// Builds personalized context from local expense data for RAG-style prompts.
  Future<RagContext?> buildContext(String userQuestion) async {
    if (!_needsData(userQuestion) || _looksLikeExpenseEntry(userQuestion)) {
      return null;
    }

    final now = DateTime.now();
    final requestedMonth = _resolveRequestedMonth(userQuestion, now);
    final thisMonthExpenses = await _localDataSource.getThisMonthExpenses();
    final todayExpenses = await _localDataSource.getTodayExpenses();
    final includeLastMonth = _containsAny(userQuestion, const [
      'গত মাস',
      'last month',
      'তুলনা',
      'compare',
    ]);

    final lastMonthExpenses = includeLastMonth
        ? await _loadComparisonExpenses(now, requestedMonth)
        : const <ExpenseRecordModel>[];
    final primaryExpenses = await _loadPrimaryExpenses(userQuestion, now);

    if (primaryExpenses.isEmpty &&
        thisMonthExpenses.isEmpty &&
        todayExpenses.isEmpty &&
        lastMonthExpenses.isEmpty) {
      return null;
    }

    final comparisonBaseMonth =
        requestedMonth ?? DateTime(now.year, now.month, 1);
    final lastMonthDate = _previousMonth(comparisonBaseMonth);
    final primaryEntities = _toEntities(primaryExpenses);
    final thisMonthEntities = _toEntities(thisMonthExpenses);
    final todayEntities = _toEntities(todayExpenses);
    final lastMonthEntities = _toEntities(lastMonthExpenses);
    final primaryCategoryTotals = _buildCategoryTotals(primaryEntities);
    final lastMonthCategoryTotals = _buildCategoryTotals(lastMonthEntities);
    final periodTotal = _sumExpenses(primaryEntities);
    final thisMonthTotal = _sumExpenses(thisMonthEntities);
    final lastMonthTotal = lastMonthEntities.isEmpty
        ? null
        : _sumExpenses(lastMonthEntities);
    final monthName = _resolvePrimaryLabel(userQuestion, now);

    final data = RagStructuredData(
      thisMonthTotal: thisMonthTotal,
      lastMonthTotal: lastMonthTotal,
      categoryTotals: primaryCategoryTotals,
      todayExpenses: todayEntities,
      recentExpenses: primaryEntities.take(10).toList(growable: false),
      monthName: monthName,
      transactionCount: primaryEntities.length,
      periodTotal: periodTotal,
      periodExpenses: primaryEntities,
      lastMonthCategoryTotals: lastMonthCategoryTotals,
      lastMonthExpenses: lastMonthEntities,
      lastMonthName: includeLastMonth
          ? BanglaFormatters.monthYear(lastMonthDate)
          : null,
      referenceDate: requestedMonth ?? now,
    );

    final buffer = StringBuffer()
      ..writeln('## User Expense Data ($monthName)')
      ..writeln('মোট খরচ: ${BanglaFormatters.currency(periodTotal)}')
      ..writeln('')
      ..writeln('ক্যাটাগরি অনুযায়ী:');

    if (primaryCategoryTotals.isEmpty) {
      buffer.writeln('- কোনো খরচ নেই');
    } else {
      for (final entry in primaryCategoryTotals.entries) {
        buffer.writeln(
          '- ${entry.key}: ${BanglaFormatters.currency(entry.value)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('সাম্প্রতিক লেনদেন (শেষ ১০টি):');
    if (primaryEntities.isEmpty) {
      buffer.writeln('- কোনো লেনদেন নেই');
    } else {
      for (final expense in primaryEntities.take(10)) {
        buffer.writeln(
          '- ${BanglaFormatters.dayMonth(expense.date)}: ${expense.category} | '
          '${expense.description} | ${BanglaFormatters.currency(expense.amount)}',
        );
      }
    }

    if (includeLastMonth) {
      buffer
        ..writeln('')
        ..writeln(
          '## Last Month Data (${BanglaFormatters.monthYear(lastMonthDate)})',
        )
        ..writeln('মোট খরচ: ${BanglaFormatters.currency(lastMonthTotal ?? 0)}')
        ..writeln('ক্যাটাগরি অনুযায়ী:');
      if (lastMonthCategoryTotals.isEmpty) {
        buffer.writeln('- কোনো খরচ নেই');
      } else {
        for (final entry in lastMonthCategoryTotals.entries) {
          buffer.writeln(
            '- ${entry.key}: ${BanglaFormatters.currency(entry.value)}',
          );
        }
      }
    }

    return RagContext(textForAi: buffer.toString().trim(), data: data);
  }

  /// Returns true when the question looks like it needs personal expense data.
  bool needsData(String question) => _needsData(question);

  Future<List<ExpenseRecordModel>> _loadPrimaryExpenses(
    String userQuestion,
    DateTime now,
  ) async {
    final requestedMonth = _resolveRequestedMonth(userQuestion, now);

    if (_containsAny(userQuestion, const ['আজকে', 'today'])) {
      return _localDataSource.getTodayExpenses();
    }

    if (_containsAny(userQuestion, const ['সপ্তাহ', 'week'])) {
      final start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      return _localDataSource.getExpensesByDateRange(start, now);
    }

    if (_containsAny(userQuestion, const ['গত মাস', 'last month']) &&
        !_containsAny(userQuestion, const ['তুলনা', 'compare', 'সাথে'])) {
      return _localDataSource.getLastMonthExpenses();
    }

    if (requestedMonth != null) {
      return _localDataSource.getExpensesForMonth(requestedMonth);
    }

    return _localDataSource.getThisMonthExpenses();
  }

  Future<List<ExpenseRecordModel>> _loadComparisonExpenses(
    DateTime now,
    DateTime? requestedMonth,
  ) async {
    if (requestedMonth != null) {
      return _localDataSource.getExpensesForMonth(
        _previousMonth(requestedMonth),
      );
    }

    return _localDataSource.getLastMonthExpenses();
  }

  Map<String, double> _buildCategoryTotals(List<ExpenseEntity> expenses) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final entries = totals.entries.toList(growable: false)
      ..sort((first, second) => second.value.compareTo(first.value));
    return Map<String, double>.fromEntries(entries);
  }

  List<ExpenseEntity> _toEntities(List<ExpenseRecordModel> expenses) {
    return expenses
        .map(
          (expense) => ExpenseEntity(
            id: expense.id,
            amount: expense.amount.toDouble(),
            category: expense.category,
            description: expense.description,
            date: expense.date,
          ),
        )
        .toList(growable: false);
  }

  double _sumExpenses(List<ExpenseEntity> expenses) {
    return expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  String _resolvePrimaryLabel(String userQuestion, DateTime now) {
    final requestedMonth = _resolveRequestedMonth(userQuestion, now);

    if (_containsAny(userQuestion, const ['আজকে', 'today'])) {
      return BanglaFormatters.fullDate(now);
    }

    if (_containsAny(userQuestion, const ['সপ্তাহ', 'week'])) {
      return 'গত ৭ দিন';
    }

    if (_containsAny(userQuestion, const ['গত মাস', 'last month']) &&
        !_containsAny(userQuestion, const ['তুলনা', 'compare', 'সাথে'])) {
      final lastMonthDate = _previousMonth(DateTime(now.year, now.month, 1));
      return BanglaFormatters.monthYear(lastMonthDate);
    }

    if (requestedMonth != null) {
      return BanglaFormatters.monthYear(requestedMonth);
    }

    return BanglaFormatters.monthYear(now);
  }

  bool _needsData(String question) {
    const keywords = [
      'কত',
      'খরচ',
      'টাকা',
      'মাস',
      'budget',
      'বাজেট',
      'total',
      'মোট',
      'category',
      'ক্যাটাগরি',
      'spent',
      'বেশি',
      'কম',
      'analysis',
      'report',
      'summary',
      'কোথায়',
      'কিসে',
      'সবচেয়ে',
      'compare',
      'তুলনা',
      'সপ্তাহ',
      'আজকে',
      'গতকাল',
      'এই মাসে',
      'গত মাসে',
      'food',
      'transport',
      'healthcare',
      'shopping',
      'bill',
      'entertainment',
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final lower = question.toLowerCase();
    return keywords.any(lower.contains);
  }

  bool _looksLikeExpenseEntry(String input) {
    final normalized = input.toLowerCase();
    final hasAmount = RegExp(r'\d').hasMatch(normalized);
    final hasEntryVerb = [
      'দিলাম',
      'খেলাম',
      'করলাম',
      'কিনলাম',
      'গেলাম',
      'খরচ হলো',
      'খরচ হল',
      'paid',
      'spent',
    ].any(normalized.contains);
    final hasAnalyticCue = [
      'কত',
      '?',
      'মোট',
      'summary',
      'report',
      'analysis',
      'compare',
      'তুলনা',
      'সবচেয়ে',
      'বেশি',
      'কম',
      'কোথায়',
      'কিসে',
    ].any(normalized.contains);

    return hasAmount && hasEntryVerb && !hasAnalyticCue;
  }

  bool _containsAny(String input, List<String> keywords) {
    final lower = input.toLowerCase();
    return keywords.any(lower.contains);
  }

  DateTime? _resolveRequestedMonth(String userQuestion, DateTime now) {
    final normalized = _normalizeText(userQuestion);

    final numericMonthYear = RegExp(
      r'(?<!\d)(\d{1,2})[/-](\d{4})(?!\d)',
    ).firstMatch(normalized);
    if (numericMonthYear != null) {
      final month = int.tryParse(numericMonthYear.group(1)!);
      final year = int.tryParse(numericMonthYear.group(2)!);
      return _safeMonth(year, month);
    }

    final yearMonthNumeric = RegExp(
      r'(?<!\d)(\d{4})[/-](\d{1,2})(?!\d)',
    ).firstMatch(normalized);
    if (yearMonthNumeric != null) {
      final year = int.tryParse(yearMonthNumeric.group(1)!);
      final month = int.tryParse(yearMonthNumeric.group(2)!);
      return _safeMonth(year, month);
    }

    final yearThenMonthPattern = RegExp(
      r'(\d{4})\s*(?:সালের|year|er|এর)?\s*(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|october|oct|november|nov|december|dec|জানুয়ারি|ফেব্রুয়ারি|মার্চ|এপ্রিল|মে|জুন|জুলাই|আগস্ট|সেপ্টেম্বর|অক্টোবর|নভেম্বর|ডিসেম্বর)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (yearThenMonthPattern != null) {
      final year = int.tryParse(yearThenMonthPattern.group(1)!);
      final monthToken = yearThenMonthPattern.group(2)?.toLowerCase();
      final month = _monthLookup[monthToken];
      return _safeMonth(year, month);
    }

    final monthYearPattern = RegExp(
      r'(january|jan|february|feb|march|mar|april|apr|may|june|jun|july|jul|august|aug|september|sep|october|oct|november|nov|december|dec|জানুয়ারি|ফেব্রুয়ারি|মার্চ|এপ্রিল|মে|জুন|জুলাই|আগস্ট|সেপ্টেম্বর|অক্টোবর|নভেম্বর|ডিসেম্বর)\s*(?:মাস(?:ের|ে)?\s*)?(?:,?\s*(\d{4}))?',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (monthYearPattern != null) {
      final monthToken = monthYearPattern.group(1)?.toLowerCase();
      final month = _monthLookup[monthToken];
      final year = int.tryParse(monthYearPattern.group(2) ?? '') ?? now.year;
      return _safeMonth(year, month);
    }

    return null;
  }

  DateTime? _safeMonth(int? year, int? month) {
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }

    return DateTime(year, month, 1);
  }

  DateTime _previousMonth(DateTime month) {
    return month.month == 1
        ? DateTime(month.year - 1, 12, 1)
        : DateTime(month.year, month.month - 1, 1);
  }

  String _normalizeText(String input) {
    return _convertBanglaDigits(input).toLowerCase();
  }

  String _convertBanglaDigits(String value) {
    const banglaDigits = {
      '০': '0',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
    };

    return value.split('').map((char) => banglaDigits[char] ?? char).join();
  }

  static const Map<String, int> _monthLookup = {
    'january': 1,
    'jan': 1,
    'জানুয়ারি': 1,
    'february': 2,
    'feb': 2,
    'ফেব্রুয়ারি': 2,
    'march': 3,
    'mar': 3,
    'মার্চ': 3,
    'april': 4,
    'apr': 4,
    'এপ্রিল': 4,
    'may': 5,
    'মে': 5,
    'june': 6,
    'jun': 6,
    'জুন': 6,
    'july': 7,
    'jul': 7,
    'জুলাই': 7,
    'august': 8,
    'aug': 8,
    'আগস্ট': 8,
    'september': 9,
    'sep': 9,
    'সেপ্টেম্বর': 9,
    'october': 10,
    'oct': 10,
    'অক্টোবর': 10,
    'november': 11,
    'nov': 11,
    'নভেম্বর': 11,
    'december': 12,
    'dec': 12,
    'ডিসেম্বর': 12,
  };
}
