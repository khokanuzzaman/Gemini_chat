import 'dart:math' as math;

import '../../../../core/money/whole_taka.dart';

/// A debt balance below this is dust: it can't be paid in whole taka, so it counts
/// as settled (remaining 0). Lets a debt that already carries paisa (e.g. ৳1,250.40)
/// always be closed.
const debtDustThreshold = 1.0;

/// The most a whole-taka payment may be for a debt with [remaining] left:
/// `floor(remaining)` — paying ৳1,250 on ৳1,250.40 leaves ৳0.40, which is dust and
/// settles. A debt already below ৳1 accepts a ৳1 payment, so it can still be closed.
double maxWholeTakaPayment(double remaining) {
  if (remaining <= 0) {
    return 0;
  }
  return remaining < debtDustThreshold ? 1 : remaining.floorToDouble();
}

/// The whole-taka amount of an EMI instalment: `min(emi, remaining)` rounded.
/// ONE definition used by the controller (wallet delta) AND the datasource (payment
/// row), so the two can never differ. 0 when there is nothing scheduled.
double installmentPaymentAmount({
  required double emiAmount,
  required double remaining,
}) {
  final scheduled = math.min(
    math.max(0.0, emiAmount),
    math.max(0.0, remaining),
  );
  if (scheduled <= 0) {
    return 0;
  }
  final rounded = wholeTaka(scheduled);
  return rounded < 1 ? 1 : rounded;
}
