import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/money/amount_input.dart';

AmountInput _type(
  String keys, {
  AmountInput start = const AmountInput.empty(),
}) {
  var input = start;
  for (final key in keys.split(' ')) {
    input = input.append(key);
  }
  return input;
}

void main() {
  setUpAll(() => initializeDateFormatting('bn'));

  group('AmountInput', () {
    test('starts empty and shows ০', () {
      const input = AmountInput.empty();
      expect(input.isEmpty, isTrue);
      expect(input.value, 0);
      expect(input.display, '০');
    });

    test('digits build the number', () {
      final input = _type('1 4 5 0');
      expect(input.value, 1450);
      expect(input.digits, '1450');
    });

    test('shows Bengali digits with Indian grouping, live', () {
      expect(_type('1 4 5 0').display, '১,৪৫০');
      expect(_type('1 2 4 9 5 0').display, '১,২৪,৯৫০');
      expect(_type('5').display, '৫');
      expect(_type('9 9 9 9 9 9 9 9 9').display, '৯৯,৯৯,৯৯,৯৯৯');
    });

    test('a leading zero is ignored (no "0045")', () {
      expect(_type('0').isEmpty, isTrue);
      expect(_type('0 0 0').isEmpty, isTrue);
      expect(_type('0 7').value, 7);
      expect(_type('00').isEmpty, isTrue);
    });

    test(
      'the 00 key appends two zeros (and does nothing on an empty amount)',
      () {
        expect(_type('5 00').value, 500);
        expect(_type('5 00 00').value, 50000);
        expect(_type('00 5').value, 5);
      },
    );

    test('capped at 9 digits; 00 with room for one adds one', () {
      final full = _type('1 2 3 4 5 6 7 8 9');
      expect(full.value, 123456789);
      expect(full.append('5'), full);
      expect(_type('1 2 3 4 5 6 7 8').append('00').digits, '123456780');
    });

    test('backspace removes the last digit; on empty it is a no-op', () {
      expect(_type('1 4 5').backspace().value, 14);
      expect(_type('5').backspace().isEmpty, isTrue);
      expect(const AmountInput.empty().backspace().isEmpty, isTrue);
    });

    test('clear empties it', () {
      expect(_type('1 2 3').clear().isEmpty, isTrue);
    });

    test(
      'anything that is not a digit is ignored (no decimal point, no letters)',
      () {
        expect(_type('1 . 5').value, 15);
        expect(
          const AmountInput.empty().append('.'),
          const AmountInput.empty(),
        );
        expect(_type('1').append('a').value, 1);
        expect(_type('1').append('').value, 1);
        expect(_type('1').append('-').value, 1);
      },
    );

    test('immutable: operations return new values', () {
      const start = AmountInput.empty();
      final next = start.append('5');
      expect(start.isEmpty, isTrue);
      expect(next.value, 5);
    });

    test('fromValue clamps and round-trips', () {
      expect(AmountInput.fromValue(0).isEmpty, isTrue);
      expect(AmountInput.fromValue(-5).isEmpty, isTrue);
      expect(AmountInput.fromValue(1250).value, 1250);
      expect(
        AmountInput.fromValue(1234567890123).digits.length,
        AmountInput.maxDigits,
      );
    });

    test('the value is always a whole, positive int the ledger can take', () {
      for (final keys in ['1', '9 9', '1 0 0 0', '5 00']) {
        final v = _type(keys).value;
        expect(v, greaterThan(0));
        expect(v.toDouble(), v.toDouble().roundToDouble());
      }
    });
  });

  test(
    'keyboard import is available (sanity for the sheet\'s hardware keys)',
    () {
      expect(LogicalKeyboardKey.digit5.keyLabel, '5');
    },
  );
}
