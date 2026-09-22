import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';

void main() {
  // The configured symbol is process-global; restore the default after each
  // test so one case can't leak its symbol into the next.
  tearDown(() => BanglaFormatters.configureCurrencySymbol('৳'));

  group('currency() honors the configured symbol', () {
    test('prefixes the configured symbol instead of the hardcoded ৳', () {
      BanglaFormatters.configureCurrencySymbol('Tk');

      final formatted = BanglaFormatters.currency(1234);

      expect(formatted, startsWith('Tk '));
      expect(formatted, isNot(contains('৳')));
    });

    test('defaults to ৳ so existing users see no change', () {
      BanglaFormatters.configureCurrencySymbol('৳');

      expect(BanglaFormatters.currency(1000), startsWith('৳ '));
    });

    test('falls back to ৳ when the symbol is blank', () {
      BanglaFormatters.configureCurrencySymbol('   ');

      expect(BanglaFormatters.currency(1000), startsWith('৳ '));
    });

    test('falls back to ৳ when the symbol is null', () {
      BanglaFormatters.configureCurrencySymbol('Tk');
      BanglaFormatters.configureCurrencySymbol(null);

      expect(BanglaFormatters.currency(1000), startsWith('৳ '));
    });
  });

  group('preciseCurrency() honors the configured symbol', () {
    test('prefixes the configured symbol on fractional amounts', () {
      BanglaFormatters.configureCurrencySymbol('BDT');

      final formatted = BanglaFormatters.preciseCurrency(12.5);

      expect(formatted, startsWith('BDT '));
      expect(formatted, isNot(contains('৳')));
    });
  });

  group('parseAmount() strips the configured symbol', () {
    test('parses a value prefixed with the configured symbol', () {
      BanglaFormatters.configureCurrencySymbol('Tk');

      expect(BanglaFormatters.parseAmount('Tk 300'), 300);
    });

    test('strips the configured symbol and thousands separators', () {
      BanglaFormatters.configureCurrencySymbol('BDT');

      expect(BanglaFormatters.parseAmount('BDT 1,234'), 1234);
    });

    test('parses the default ৳ symbol byte-identically (existing users)', () {
      BanglaFormatters.configureCurrencySymbol('৳');

      expect(BanglaFormatters.parseAmount('৳ 300'), 300);
      expect(BanglaFormatters.parseAmount('৳ ৩০০'), 300);
    });

    test('round-trips a formatted amount back to its number', () {
      BanglaFormatters.configureCurrencySymbol('Tk');

      final formatted = BanglaFormatters.currency(300); // "Tk ৩০০"
      expect(BanglaFormatters.parseAmount(formatted), 300);
    });

    test('returns null for blank input', () {
      expect(BanglaFormatters.parseAmount('   '), isNull);
    });
  });
}
