import '../../features/income/domain/entities/income_source.dart';
import 'bangla_date_parser.dart';

class IncomeData {
  const IncomeData({
    required this.amount,
    required this.source,
    required this.description,
    required this.date,
    this.isRecurring = false,
  });

  final double amount;
  final String source;
  final String description;
  final String date;
  final bool isRecurring;

  factory IncomeData.fromJson(Map<String, dynamic> json) {
    final amountValue = json['amount'];
    return IncomeData(
      amount: switch (amountValue) {
        num value => value.toDouble(),
        String value => _parseAmountString(value),
        _ => 0,
      },
      source: json['source'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? 'today',
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  IncomeData copyWith({
    double? amount,
    String? source,
    String? description,
    String? date,
    bool? isRecurring,
  }) {
    return IncomeData(
      amount: amount ?? this.amount,
      source: source ?? this.source,
      description: description ?? this.description,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  DateTime get parsedDate => BanglaDateParser.parseDateValue(date);

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
      amount > 0 &&
      description.trim().isNotEmpty &&
      findIncomeSourceByName(source) != null;

  static double _parseAmountString(String value) {
    final normalized =
        BanglaDateParser.convertBanglaDigits(value).replaceAll(',', '').trim();
    return double.tryParse(normalized) ?? 0;
  }
}
