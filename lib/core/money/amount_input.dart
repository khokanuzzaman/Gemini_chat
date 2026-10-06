import '../utils/bangla_formatters.dart';

/// The amount being typed on the add-entry keypad: whole taka, digits only.
///
/// Pure and immutable so every rule is unit-tested (no decimal key — records store
/// whole taka, see `wholeTaka`). Digits are kept as ASCII internally; [display]
/// shows Bengali digits with Indian grouping (১,২৪,৯৫০).
class AmountInput {
  const AmountInput._(this.digits);

  const AmountInput.empty() : digits = '';

  /// Starts from an existing amount (e.g. editing).
  factory AmountInput.fromValue(int value) {
    if (value <= 0) {
      return const AmountInput.empty();
    }
    final text = '$value';
    return AmountInput._(
      text.length > maxDigits ? text.substring(0, maxDigits) : text,
    );
  }

  /// ৳৯৯,৯৯,৯৯,৯৯৯ — enough for any personal ledger, and it stays inside an int.
  static const maxDigits = 9;

  /// ASCII digits, no leading zero; empty means "nothing typed yet".
  final String digits;

  bool get isEmpty => digits.isEmpty;

  int get value => digits.isEmpty ? 0 : int.parse(digits);

  /// What the amount shows: "০" until something is typed.
  String get display => isEmpty ? '০' : BanglaFormatters.count(value);

  /// Appends one key: a digit `0`–`9` or the `00` key. Anything else is ignored.
  /// A leading zero is dropped (typing `0` on an empty amount does nothing), and
  /// input past [maxDigits] is ignored (a `00` with room for one digit adds one).
  AmountInput append(String key) {
    if (key.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(key)) {
      return this;
    }
    var next = digits;
    for (final char in key.split('')) {
      if (next.length >= maxDigits) {
        break;
      }
      if (next.isEmpty && char == '0') {
        continue;
      }
      next += char;
    }
    return next == digits ? this : AmountInput._(next);
  }

  AmountInput backspace() => digits.isEmpty
      ? this
      : AmountInput._(digits.substring(0, digits.length - 1));

  AmountInput clear() => const AmountInput.empty();

  @override
  bool operator ==(Object other) =>
      other is AmountInput && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => 'AmountInput($digits)';
}
