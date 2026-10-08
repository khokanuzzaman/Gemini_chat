import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gemini_chat/core/utils/bangla_formatters.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_defaults.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('bn');
  });

  test(
    'seeded Cash and Bank Account are SHOWN in Bengali, stored unchanged',
    () {
      final cash = defaultWallets.firstWhere((w) => w.type == WalletType.cash);
      final bank = defaultWallets.firstWhere((w) => w.type == WalletType.bank);
      expect(cash.shownName, 'নগদ টাকা');
      expect(bank.shownName, 'ব্যাংক অ্যাকাউন্ট');
      expect(cash.displayName, '💵 নগদ টাকা');
      // The stored value is the key SMS matching / backups rely on — untouched.
      expect(cash.name, 'Cash');
      expect(bank.name, 'Bank Account');
    },
  );

  test('bKash and user-typed names are never rewritten', () {
    final bkash = defaultWallets.firstWhere((w) => w.type == WalletType.bkash);
    expect(bkash.shownName, 'bKash');
    final mine = defaultWallets.first.copyWith(name: 'আমার ব্যাগ');
    expect(mine.shownName, 'আমার ব্যাগ');
    // "Cash" typed on a non-cash wallet is the user's own name.
    final odd = defaultWallets
        .firstWhere((w) => w.type == WalletType.bkash)
        .copyWith(name: 'Cash');
    expect(odd.shownName, 'Cash');
  });

  test('BanglaFormatters.percent: Bengali numerals, rounded, safe', () {
    expect(BanglaFormatters.percent(82), '৮২%');
    expect(BanglaFormatters.percent(79.6), '৮০%');
    expect(BanglaFormatters.percent(0), '০%');
    expect(BanglaFormatters.percent(double.nan), '০%');
    expect(BanglaFormatters.percent(130), '১৩০%');
  });
}
