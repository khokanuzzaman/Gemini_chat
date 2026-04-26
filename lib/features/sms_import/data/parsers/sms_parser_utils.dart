import '../../domain/entities/sms_message_entity.dart';

class SmsParserUtils {
  const SmsParserUtils._();

  static final RegExp _multiWhitespace = RegExp(r'\s+');
  static final RegExp _currencyPattern = RegExp(
    r'(?:tk|bdt)\s*([0-9,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static String normalize(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll(_multiWhitespace, ' ')
        .trim();
  }

  static String normalizeLower(String input) => normalize(input).toLowerCase();

  static bool containsAny(String value, Iterable<String> keywords) {
    final haystack = normalizeLower(value);
    return keywords.any((keyword) => haystack.contains(keyword.toLowerCase()));
  }

  static double? extractFirstAmount(String body, [List<RegExp>? patterns]) {
    final candidates = patterns ?? [_currencyPattern];
    for (final pattern in candidates) {
      final match = pattern.firstMatch(body);
      final value = parseAmount(match?.group(1));
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static double? extractFee(String body) {
    return extractFirstAmount(body, [
      RegExp(
        r'fee(?: amount)?[: ]*(?:tk|bdt)?\s*([0-9,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'charge(?: amount)?[: ]*(?:tk|bdt)?\s*([0-9,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ]);
  }

  static double? extractBalance(String body) {
    return extractFirstAmount(body, [
      RegExp(
        r'(?:available|current|avl\.?|ac|a/c)?\s*balance[: ]*(?:is )?(?:tk|bdt)?\s*([0-9,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'avl\.?\s*bal(?:ance)?[: ]*(?:tk|bdt)?\s*([0-9,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractReference(String body) {
    return extractFirstText(body, [
      RegExp(
        r'(?:trxid|txnid|txn id|ref(?:erence)?)[ :#-]*([A-Za-z0-9-]+)',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractAccountMask(String body) {
    return extractFirstText(body, [
      RegExp(
        r'(?:a/c|account|acct|card)\s*(?:no\.?|number)?\s*[:#-]?\s*([A-Za-z0-9*Xx-]{4,})',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:using|from)\s+card\s*([A-Za-z0-9*Xx-]{4,})',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractPartyAfterTo(String body) {
    return extractFirstText(body, [
      RegExp(
        r'\bto\s+(.+?)(?=(?:\.|,| successful| fee| charge| balance| current balance| avl| trxid| txnid| ref| on \d| at \d|$))',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractPartyAfterFrom(String body) {
    return extractFirstText(body, [
      RegExp(
        r'\bfrom\s+(.+?)(?=(?:\.|,| successful| fee| charge| balance| current balance| avl| trxid| txnid| ref| on \d| at \d|$))',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractMerchant(String body) {
    return extractFirstText(body, [
      RegExp(
        r'\bat\s+(.+?)(?=(?:\.|,| balance| avl| trxid| txnid| ref|$))',
        caseSensitive: false,
      ),
      RegExp(
        r'\bmerchant[: ]+(.+?)(?=(?:\.|,| balance| avl| trxid| txnid| ref|$))',
        caseSensitive: false,
      ),
    ]);
  }

  static String? extractFirstText(String body, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      final value = _cleanText(match?.group(1));
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static double? parseAmount(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  static DateTime resolveOccurredAt(SmsMessageEntity message) {
    return extractDateTime(message.body) ?? message.receivedAt;
  }

  static DateTime? extractDateTime(String body) {
    final normalized = normalize(body);
    final slashDateMatch = RegExp(
      r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?:[ ,T-]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?)?',
    ).firstMatch(normalized);
    if (slashDateMatch != null) {
      final year = _normalizeYear(int.parse(slashDateMatch.group(3)!));
      final hour = _to24Hour(
        int.tryParse(slashDateMatch.group(4) ?? '0') ?? 0,
        slashDateMatch.group(7),
      );
      return DateTime(
        year,
        int.parse(slashDateMatch.group(2)!),
        int.parse(slashDateMatch.group(1)!),
        hour,
        int.tryParse(slashDateMatch.group(5) ?? '0') ?? 0,
        int.tryParse(slashDateMatch.group(6) ?? '0') ?? 0,
      );
    }

    final namedMonthMatch = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{2,4})(?:[ ,]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?)?',
    ).firstMatch(normalized);
    if (namedMonthMatch != null) {
      final month = _monthNameToNumber(namedMonthMatch.group(2)!);
      if (month == null) {
        return null;
      }
      final year = _normalizeYear(int.parse(namedMonthMatch.group(3)!));
      final hour = _to24Hour(
        int.tryParse(namedMonthMatch.group(4) ?? '0') ?? 0,
        namedMonthMatch.group(7),
      );
      return DateTime(
        year,
        month,
        int.parse(namedMonthMatch.group(1)!),
        hour,
        int.tryParse(namedMonthMatch.group(5) ?? '0') ?? 0,
        int.tryParse(namedMonthMatch.group(6) ?? '0') ?? 0,
      );
    }

    return null;
  }

  static int _normalizeYear(int year) => year < 100 ? 2000 + year : year;

  static int _to24Hour(int hour, String? meridiem) {
    final normalized = meridiem?.toLowerCase();
    if (normalized == 'pm' && hour < 12) {
      return hour + 12;
    }
    if (normalized == 'am' && hour == 12) {
      return 0;
    }
    return hour;
  }

  static int? _monthNameToNumber(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'jan':
      case 'january':
        return 1;
      case 'feb':
      case 'february':
        return 2;
      case 'mar':
      case 'march':
        return 3;
      case 'apr':
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'jun':
      case 'june':
        return 6;
      case 'jul':
      case 'july':
        return 7;
      case 'aug':
      case 'august':
        return 8;
      case 'sep':
      case 'sept':
      case 'september':
        return 9;
      case 'oct':
      case 'october':
        return 10;
      case 'nov':
      case 'november':
        return 11;
      case 'dec':
      case 'december':
        return 12;
      default:
        return null;
    }
  }

  static String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }

    final cleaned = normalize(
      value
          .replaceAll(RegExp(r'^[\s:,-]+'), '')
          .replaceAll(RegExp(r'[\s:;,.!-]+$'), ''),
    );
    return cleaned.isEmpty ? null : cleaned;
  }
}
