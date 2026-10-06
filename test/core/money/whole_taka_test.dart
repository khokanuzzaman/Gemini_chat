import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/money/whole_taka.dart';
import 'package:gemini_chat/features/debt/domain/utils/debt_amounts.dart';

void main() {
  group('wholeTaka (the same .round() the mapper applies)', () {
    test('rounds half away from zero, like int.round()', () {
      expect(wholeTaka(120.5), 121);
      expect(wholeTaka(120.49), 120);
      expect(wholeTaka(99.6), 100);
      expect(wholeTaka(1250.4), 1250);
      expect(wholeTaka(0.5), 1);
      expect(wholeTaka(1000), 1000);
    });

    test(
      'identical to what the record stores (no behaviour change for old data)',
      () {
        for (final v in [0.0, 0.49, 0.5, 1.5, 2.5, 120.5, 999.999, 100000.5]) {
          expect(wholeTaka(v), v.round().toDouble(), reason: '$v');
        }
      },
    );

    test('non-finite input is 0, never a throw', () {
      expect(wholeTaka(double.nan), 0);
      expect(wholeTaka(double.infinity), 0);
    });

    test('isWholeTaka / isRecordableAmount', () {
      expect(isWholeTaka(250), isTrue);
      expect(isWholeTaka(250.5), isFalse);
      expect(isRecordableAmount(0.4), isFalse, reason: 'rounds to a ৳0 record');
      expect(isRecordableAmount(0.5), isTrue);
      expect(isRecordableAmount(1), isTrue);
      expect(isRecordableAmount(-5), isFalse);
    });
  });

  group('debt amounts', () {
    test('maxWholeTakaPayment: floor, and ৳1 for dust so it can be closed', () {
      expect(maxWholeTakaPayment(1250.4), 1250);
      expect(maxWholeTakaPayment(1250), 1250);
      expect(maxWholeTakaPayment(0.4), 1);
      expect(maxWholeTakaPayment(0), 0);
    });

    test(
      'installmentPaymentAmount: whole taka, never 0 while something is owed',
      () {
        expect(
          installmentPaymentAmount(emiAmount: 5000, remaining: 12000),
          5000,
        );
        expect(
          installmentPaymentAmount(emiAmount: 5000, remaining: 1250.4),
          1250,
        );
        expect(
          installmentPaymentAmount(emiAmount: 5000, remaining: 1250.6),
          1251,
        );
        expect(installmentPaymentAmount(emiAmount: 5000, remaining: 0.4), 1);
        expect(installmentPaymentAmount(emiAmount: 5000, remaining: 0), 0);
        expect(installmentPaymentAmount(emiAmount: 0, remaining: 100), 0);
      },
    );
  });
}
