import 'dart:math' as math;

class EmiCalculator {
  const EmiCalculator._();

  static double calculateEMI({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final normalizedPrincipal = math.max(0, principal).toDouble();
    final normalizedRate = math.max(0, annualRate).toDouble();

    if (months <= 0) {
      return normalizedPrincipal.roundToDouble();
    }

    if (normalizedRate == 0) {
      return (normalizedPrincipal / months).roundToDouble();
    }

    final monthlyRate = normalizedRate / 12 / 100;
    final factor = math.pow(1 + monthlyRate, months).toDouble();
    final emi = normalizedPrincipal * monthlyRate * factor / (factor - 1);

    if (!emi.isFinite) {
      return normalizedPrincipal.roundToDouble();
    }

    return emi.roundToDouble();
  }
}
