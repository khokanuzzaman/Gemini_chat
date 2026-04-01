class ReceiptFormatCheckResult {
  const ReceiptFormatCheckResult({
    required this.score,
    required this.isLikelyReceipt,
    this.warnings = const [],
  });

  final int score;
  final bool isLikelyReceipt;
  final List<String> warnings;
}

class ReceiptFormatChecker {
  const ReceiptFormatChecker();

  static final _amountPattern = RegExp(
    r'(?<!\d)(?:\d{1,3}(?:[.,]\d{3})*|\d+)(?:[.,]\d{1,2})?(?!\d)',
  );
  static final _datePattern = RegExp(
    r'(\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b)|(\b\d{4}[/-]\d{1,2}[/-]\d{1,2}\b)',
    caseSensitive: false,
  );
  static final _totalPattern = RegExp(
    r'(total|subtotal|grand total|net total|vat|bill|amount due|cash)',
    caseSensitive: false,
  );
  static final _currencyPattern = RegExp(
    r'(tk|taka|৳|bdt)',
    caseSensitive: false,
  );

  ReceiptFormatCheckResult check(String extractedText) {
    final normalized = extractedText.trim();
    if (normalized.isEmpty) {
      return const ReceiptFormatCheckResult(score: 0, isLikelyReceipt: false);
    }

    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    var score = 0;
    final warnings = <String>[];

    if (lines.length >= 4) {
      score += 18;
    } else {
      warnings.add('লাইন কম পাওয়া গেছে');
    }

    final merchantLine = lines.isEmpty ? '' : lines.first;
    if (_looksLikeMerchant(merchantLine)) {
      score += 14;
    } else {
      warnings.add('দোকানের নাম স্পষ্ট না');
    }

    final amountMatches = _amountPattern.allMatches(normalized).length;
    if (amountMatches >= 3) {
      score += 18;
    } else if (amountMatches >= 1) {
      score += 8;
      warnings.add('দামের তথ্য কম পাওয়া গেছে');
    } else {
      warnings.add('দামের তথ্য পাওয়া যায়নি');
    }

    final lineItemCount = lines.where(_looksLikeLineItem).length;
    if (lineItemCount >= 2) {
      score += 16;
    } else {
      warnings.add('item + price pattern কম');
    }

    if (_totalPattern.hasMatch(normalized)) {
      score += 18;
    } else {
      warnings.add('total/subtotal keyword নেই');
    }

    if (_currencyPattern.hasMatch(normalized)) {
      score += 8;
    }

    if (_datePattern.hasMatch(normalized)) {
      score += 8;
    } else {
      warnings.add('date পাওয়া যায়নি');
    }

    if (score < 40) {
      return ReceiptFormatCheckResult(
        score: score,
        isLikelyReceipt: false,
        warnings: warnings,
      );
    }

    if (score < 60) {
      warnings.add('receipt format দুর্বল, result ভুল হতে পারে');
    }

    return ReceiptFormatCheckResult(
      score: score > 100 ? 100 : score,
      isLikelyReceipt: true,
      warnings: warnings,
    );
  }

  bool _looksLikeMerchant(String line) {
    if (line.isEmpty || line.length < 3 || line.length > 40) {
      return false;
    }

    final digitCount = RegExp(r'\d').allMatches(line).length;
    return digitCount <= line.length ~/ 3;
  }

  bool _looksLikeLineItem(String line) {
    final hasAmount = _amountPattern.hasMatch(line);
    final hasLetters = RegExp(r'[A-Za-z\u0980-\u09FF]').hasMatch(line);
    return hasAmount && hasLetters;
  }
}
