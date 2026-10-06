/// The app's money is whole taka.
///
/// Expense and income RECORDS store an integer (`amount.round()` in the mapper),
/// while the wallet ledger applies a `double` delta. If a fractional amount ever
/// reached both, the record would say ৳121 and the wallet would move ৳120.50 — the
/// exact record/wallet mismatch the ledger exists to prevent.
///
/// So every money path calls [wholeTaka] ONCE, at the boundary, BEFORE building the
/// entity, and passes that same value to the record and to the ledger delta. It is
/// the same `.round()` (half away from zero) the mapper has always applied, so the
/// stored records are identical to what they were before this existed.
///
/// (A wallet's opening balance is deliberately NOT rounded: it is a starting point,
/// not a transaction.)
double wholeTaka(double amount) {
  if (!amount.isFinite) {
    return 0;
  }
  return amount.round().toDouble();
}

/// True when [amount] has no paisa part.
bool isWholeTaka(double amount) =>
    amount.isFinite && amount == amount.roundToDouble();

/// A recordable amount is at least ৳1 after rounding (0.4 would round to a
/// zero-taka record).
bool isRecordableAmount(double amount) => wholeTaka(amount) >= 1;
