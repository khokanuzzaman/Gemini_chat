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
}
