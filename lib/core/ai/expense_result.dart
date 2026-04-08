import 'bangla_date_parser.dart';
import 'income_data.dart';

class ExpenseData {
  const ExpenseData({
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.isSplit = false,
    this.splitPersons,
  });

  final double amount;
  final String category;
  final String description;
  final String date;
  final bool isSplit;
  final int? splitPersons;

  factory ExpenseData.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    return ExpenseData(
      amount: switch (amountValue) {
        num value => value.toDouble(),
        String value => _parseAmountString(value),
        _ => 0,
      },
      category: json['category'] as String? ?? 'Other',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? 'today',
      isSplit: json['isSplit'] as bool? ?? false,
      splitPersons: switch (json['splitPersons']) {
        num value => value.toInt(),
        String value => int.tryParse(value),
        _ => null,
      },
    );
  }

  ExpenseData copyWith({
    double? amount,
    String? category,
    String? description,
    String? date,
    bool? isSplit,
    int? splitPersons,
  }) {
    return ExpenseData(
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isSplit: isSplit ?? this.isSplit,
      splitPersons: splitPersons ?? this.splitPersons,
    );
  }

  DateTime get parsedDate => parseDateValue(date);

  String get displayDate => BanglaDateParser.displayDateFor(parsedDate);

  bool get isPastDate {
    final today = BanglaDateParser.stripTime(DateTime.now());
    return BanglaDateParser.stripTime(
      parsedDate,
    ).isBefore(today.subtract(const Duration(days: 1)));
  }

  bool get isFutureDate =>
      BanglaDateParser.stripTime(parsedDate)
          .isAfter(BanglaDateParser.stripTime(DateTime.now()));

  bool get hasInvalidDate {
    final normalized = BanglaDateParser.normalizeDate(date);
    if (normalized.isEmpty || normalized == 'today') {
      return false;
    }

    return BanglaDateParser.tryParseDate(normalized) == null;
  }

  String? get dateFallbackNote =>
      hasInvalidDate ? 'তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে' : null;

  String get isoDate => BanglaDateParser.formatIsoDate(parsedDate);

  bool get isValid =>
      amount > 0 && description.trim().isNotEmpty && !_isSummaryEntry();

  bool _isSummaryEntry() {
    final normalized = description.trim().toLowerCase();
    return normalized == 'মোট' ||
        normalized == 'total' ||
        normalized == 'subtotal' ||
        normalized == 'grand total' ||
        normalized.startsWith('মোট ');
  }

  static DateTime parseDateValue(String value) {
    return BanglaDateParser.parseDateValue(value);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return BanglaDateParser.isSameDay(a, b);
  }

  static double parseAmountString(String value) {
    return _parseAmountString(value);
  }

  static double _parseAmountString(String value) {
    final normalized =
        _convertBanglaDigits(value).replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  static String _convertBanglaDigits(String value) {
    return BanglaDateParser.convertBanglaDigits(value);
  }

}

class ExpenseResult {
  const ExpenseResult({
    required this.isExpense,
    this.expenses = const [],
    this.incomes = const [],
    this.isMultiple = false,
    this.conversationalText,
    this.isReceipt = false,
    this.receiptData,
    this.isSplit = false,
    this.splitPersons,
    this.isIncome = false,
    this.hasMixedEntries = false,
  });

  final bool isExpense;
  final List<ExpenseData> expenses;
  final List<IncomeData> incomes;
  final bool isMultiple;
  final String? conversationalText;
  final bool isReceipt;
  final Map<String, dynamic>? receiptData;
  final bool isSplit;
  final int? splitPersons;
  final bool isIncome;
  final bool hasMixedEntries;
}
