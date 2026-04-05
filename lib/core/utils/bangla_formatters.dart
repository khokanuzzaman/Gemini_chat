import 'package:intl/intl.dart';

class BanglaFormatters {
  const BanglaFormatters._();

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('bn');
  static final NumberFormat _moneyWithDecimals = NumberFormat('#,##0.00', 'bn');
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'bn');
  static final DateFormat _fullDateFormat = DateFormat('d MMMM yyyy', 'bn');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', 'bn');
  static final DateFormat _timeFormat = DateFormat('h:mm a', 'bn');

  static String currency(num amount) {
    return '৳ ${_numberFormat.format(amount.round())}';
  }

  static String preciseCurrency(num amount) {
    final rounded = amount.toDouble();
    final hasFraction = (rounded - rounded.round()).abs() >= 0.01;
    return '৳ ${hasFraction ? _moneyWithDecimals.format(rounded) : _numberFormat.format(rounded.round())}';
  }

  static String monthYear(DateTime date) {
    return _monthFormat.format(date);
  }

  static String fullDate(DateTime date) {
    return _fullDateFormat.format(date);
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
