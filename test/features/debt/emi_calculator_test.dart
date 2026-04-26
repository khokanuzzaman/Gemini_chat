import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/debt/domain/utils/emi_calculator.dart';

void main() {
  test('zero-interest EMI splits principal evenly', () {
    final emi = EmiCalculator.calculateEMI(
      principal: 12000,
      annualRate: 0,
      months: 12,
    );

    expect(emi, 1000);
  });

  test('interest-bearing EMI stays finite and rounded', () {
    final emi = EmiCalculator.calculateEMI(
      principal: 100000,
      annualRate: 12,
      months: 12,
    );

    expect(emi, 8885);
  });

  test('invalid months falls back to the principal amount', () {
    final emi = EmiCalculator.calculateEMI(
      principal: 5000,
      annualRate: 18,
      months: 0,
    );

    expect(emi, 5000);
  });
}
