class ExpenseData {
  const ExpenseData({
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  final double amount;
  final String category;
  final String description;
  final String date;

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
    );
  }

  ExpenseData copyWith({
    double? amount,
    String? category,
    String? description,
    String? date,
  }) {
    return ExpenseData(
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  DateTime get parsedDate => parseDateValue(date);

  String get displayDate {
    final parsed = parsedDate;
    final now = _stripTime(DateTime.now());
    final yesterday = now.subtract(const Duration(days: 1));

    if (isSameDay(parsed, now)) {
      return 'আজকে';
    }

    if (isSameDay(parsed, yesterday)) {
      return 'গতকাল';
    }

    return '${_toBanglaNumber(parsed.day)} ${_monthName(parsed.month)}, ${_toBanglaNumber(parsed.year)}';
  }

  bool get isPastDate {
    final today = _stripTime(DateTime.now());
    return _stripTime(
      parsedDate,
    ).isBefore(today.subtract(const Duration(days: 1)));
  }

  bool get isFutureDate =>
      _stripTime(parsedDate).isAfter(_stripTime(DateTime.now()));

  bool get hasInvalidDate {
    final normalized = _normalizeDate(date);
    if (normalized.isEmpty || normalized == 'today') {
      return false;
    }

    return _tryParseDate(normalized) == null;
  }

  String? get dateFallbackNote =>
      hasInvalidDate ? 'তারিখ বোঝা যায়নি, আজকের তারিখ দেওয়া হয়েছে' : null;

  String get isoDate => _formatIsoDate(parsedDate);

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
    final parsed = _tryParseDate(_normalizeDate(value));
    return parsed ?? _stripTime(DateTime.now());
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _monthName(int month) {
    const names = [
      '',
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
    ];
    return names[month];
  }

  static String _normalizeDate(String input) {
    return _convertBanglaDigits(input).trim().toLowerCase();
  }

  static double _parseAmountString(String value) {
    final normalized = _convertBanglaDigits(value).replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }

  static DateTime? _tryParseDate(String normalized) {
    if (normalized.isEmpty || normalized == 'today') {
      return _stripTime(DateTime.now());
    }

    if (normalized == 'গতকাল') {
      return _stripTime(DateTime.now().subtract(const Duration(days: 1)));
    }

    if (normalized == 'পরশু') {
      return _stripTime(DateTime.now().subtract(const Duration(days: 2)));
    }

    if (normalized == 'গত সপ্তাহে' || normalized == 'last week') {
      return _stripTime(DateTime.now().subtract(const Duration(days: 7)));
    }

    final direct = DateTime.tryParse(normalized);
    if (direct != null) {
      return _stripTime(direct);
    }

    final dayMonthYearMatch = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$',
    ).firstMatch(normalized);
    if (dayMonthYearMatch != null) {
      final day = int.tryParse(dayMonthYearMatch.group(1)!);
      final month = int.tryParse(dayMonthYearMatch.group(2)!);
      final year = int.tryParse(dayMonthYearMatch.group(3)!);
      return _safeDate(year, month, day);
    }

    final banglaMonthMatch = RegExp(
      r'^(\d{1,2})\s+([a-z\u0980-\u09ff]+)(?:\s*,?\s*(\d{4}))?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (banglaMonthMatch != null) {
      final day = int.tryParse(banglaMonthMatch.group(1)!);
      final month = _monthLookup[banglaMonthMatch.group(2)!];
      final year =
          int.tryParse(banglaMonthMatch.group(3) ?? '') ?? DateTime.now().year;
      return _safeDate(year, month, day);
    }

    final englishMonthMatch = RegExp(
      r'^([a-z]+)\s+(\d{1,2}),?\s*(\d{4})?$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (englishMonthMatch != null) {
      final month = _monthLookup[englishMonthMatch.group(1)!];
      final day = int.tryParse(englishMonthMatch.group(2)!);
      final year =
          int.tryParse(englishMonthMatch.group(3) ?? '') ?? DateTime.now().year;
      return _safeDate(year, month, day);
    }

    final lastWeekdayMatch = RegExp(
      r'^গত\s+([a-z\u0980-\u09ff]+)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (lastWeekdayMatch != null) {
      final weekday = _weekdayLookup[lastWeekdayMatch.group(1)!];
      if (weekday != null) {
        return _lastWeekday(weekday);
      }
    }

    final englishWeekdayMatch = RegExp(
      r'^last\s+([a-z]+)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (englishWeekdayMatch != null) {
      final weekday = _weekdayLookup[englishWeekdayMatch.group(1)!];
      if (weekday != null) {
        return _lastWeekday(weekday);
      }
    }

    return null;
  }

  static DateTime? _safeDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static DateTime _lastWeekday(int weekday) {
    final today = _stripTime(DateTime.now());
    var difference = today.weekday - weekday;
    if (difference <= 0) {
      difference += 7;
    }
    return today.subtract(Duration(days: difference));
  }

  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _convertBanglaDigits(String value) {
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

  static String _toBanglaNumber(int value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit == null ? char : digits[digit];
    }).join();
  }

  static const Map<String, int> _monthLookup = {
    'january': 1,
    'jan': 1,
    'জানুয়ারি': 1,
    'february': 2,
    'feb': 2,
    'ফেব্রুয়ারি': 2,
    'মার্চ': 3,
    'march': 3,
    'mar': 3,
    'এপ্রিল': 4,
    'april': 4,
    'apr': 4,
    'মে': 5,
    'may': 5,
    'জুন': 6,
    'june': 6,
    'jun': 6,
    'জুলাই': 7,
    'july': 7,
    'jul': 7,
    'আগস্ট': 8,
    'august': 8,
    'aug': 8,
    'সেপ্টেম্বর': 9,
    'september': 9,
    'sep': 9,
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

  static const Map<String, int> _weekdayLookup = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'সোমবার': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'মঙ্গলবার': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'বুধবার': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'বৃহস্পতিবার': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'শুক্রবার': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'শনিবার': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
    'রবিবার': DateTime.sunday,
  };
}

class ExpenseResult {
  const ExpenseResult({
    required this.isExpense,
    this.expenses = const [],
    this.isMultiple = false,
    this.conversationalText,
    this.isReceipt = false,
    this.receiptData,
  });

  final bool isExpense;
  final List<ExpenseData> expenses;
  final bool isMultiple;
  final String? conversationalText;
  final bool isReceipt;
  final Map<String, dynamic>? receiptData;
}
