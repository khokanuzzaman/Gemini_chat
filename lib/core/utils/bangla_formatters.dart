import 'package:intl/intl.dart';

class BanglaFormatters {
  const BanglaFormatters._();

  /// Symbol shown before money amounts when none is configured.
  static const String defaultCurrencySymbol = '৳';

  /// The symbol [currency] / [preciseCurrency] prefix onto amounts. Seeded at
  /// app startup from `AppPreferences.currencySymbol()` and updated when the
  /// user changes the "মুদ্রার চিহ্ন" setting.
  static String _currencySymbol = defaultCurrencySymbol;

  /// The currently configured currency symbol.
  static String get currencySymbol => _currencySymbol;

  /// Sets the currency symbol used by [currency] and [preciseCurrency].
  /// A null or blank value falls back to [defaultCurrencySymbol].
  static void configureCurrencySymbol(String? symbol) {
    final trimmed = symbol?.trim() ?? '';
    _currencySymbol = trimmed.isEmpty ? defaultCurrencySymbol : trimmed;
  }

  /// Parses a user-entered money string into a number. Strips the configured
  /// currency symbol (and the legacy ৳), thousands separators and spaces, and
  /// converts Bangla digits. Returns null when no number can be read.
  ///
  /// Keeping this alongside [currency] ensures a value formatted with a
  /// non-৳ symbol (e.g. "Tk ৩০০") parses back to its number instead of failing.
  static double? parseAmount(String raw) {
    var normalized = raw.trim();
    if (_currencySymbol != defaultCurrencySymbol) {
      normalized = normalized.replaceAll(_currencySymbol, '');
    }
    normalized = normalized
        .replaceAll(defaultCurrencySymbol, '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('bn');
  static final NumberFormat _moneyWithDecimals = NumberFormat('#,##0.00', 'bn');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'bn');
  static final DateFormat _fullDateFormat = DateFormat('d MMMM yyyy', 'bn');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', 'bn');
  static final DateFormat _dayMonthLongFormat = DateFormat('d MMMM', 'bn');
  static final DateFormat _timeFormat = DateFormat('h:mm a', 'bn');

  static String currency(num amount) {
    return '$_currencySymbol ${_numberFormat.format(amount.round())}';
  }

  static String preciseCurrency(num amount) {
    final rounded = amount.toDouble();
    final hasFraction = (rounded - rounded.round()).abs() >= 0.01;
    return '$_currencySymbol ${hasFraction ? _moneyWithDecimals.format(rounded) : _numberFormat.format(rounded.round())}';
  }

  static String monthYear(DateTime date) {
    return _monthFormat.format(date);
  }

  static String fullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// "১৬ অক্টোবর" (full month name, no year).
  static String dayMonthLong(DateTime date) {
    return _dayMonthLongFormat.format(date);
  }

  static String dayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  static String time(DateTime date) {
    return _timeFormat.format(date).toLowerCase();
  }

  static String count(int value) {
    return _numberFormat.format(value);
  }

  /// Whole percent in Bengali numerals, e.g. ৮২%. Rounds; non-finite gives ০%.
  static String percent(num value) {
    return '${count(value.isFinite ? value.round() : 0)}%';
  }

  static String relativeFromNow(DateTime time, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(time);
    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    }
    if (difference.inHours < 1) {
      return '${count(difference.inMinutes)} মিনিট আগে';
    }
    if (difference.inDays < 1) {
      return '${count(difference.inHours)} ঘণ্টা আগে';
    }
    return relativeDay(time, now: reference);
  }

  static String relativeDay(DateTime date, {DateTime? now}) {
    final current = _stripTime(now ?? DateTime.now());
    final target = _stripTime(date);
    final difference = current.difference(target).inDays;

    if (difference == 0) {
      return 'আজকে';
    }
    if (difference == 1) {
      return 'গতকাল';
    }
    return fullDate(target);
  }

  static DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
