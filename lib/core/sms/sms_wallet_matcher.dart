import '../../features/wallet/domain/entities/wallet_entity.dart';
import 'parsed_transaction.dart';

class SmsWalletMatcher {
  const SmsWalletMatcher();

  static const Map<String, List<String>> _bankKeywordMap = {
    'brac bank': ['bracbank', 'brac bank'],
    'city bank': ['citybank', 'city bank'],
    'ebl': ['eblbank', 'ebl', 'eastern bank'],
    'dbbl': ['dbbl', 'dutchbangla', 'dutch-bangla'],
    'islami bank': ['islamibank', 'islami bank'],
    'ucb': ['ucb', 'united commercial bank'],
    'mtb': ['mtbl', 'mutual trust bank'],
    'pubali bank': ['pubalibank', 'pubali bank'],
    'one bank': ['onebank', 'one bank'],
    'prime bank': ['primebank', 'prime bank'],
    'southeast bank': ['southeast', 'southeast bank'],
    'standard chartered': ['standardchar', 'standard chartered'],
    'hsbc': ['hsbcbd', 'hsbc'],
  };

  WalletEntity? matchWallet(
    ParsedTransaction transaction,
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) {
    if (wallets.isEmpty) {
      return null;
    }

    final activeWallets = wallets
        .where((wallet) => !wallet.isArchived)
        .toList(growable: false);
    final candidateWallets = activeWallets.isEmpty ? wallets : activeWallets;

    final exactSourceMatch = _matchBySource(transaction, candidateWallets);
    if (exactSourceMatch != null) {
      return exactSourceMatch;
    }

    final accountMatch = _matchByAccountNumber(transaction, candidateWallets);
    if (accountMatch != null) {
      return accountMatch;
    }

    final bankNameMatch = _matchByInstitutionName(
      transaction,
      candidateWallets,
    );
    if (bankNameMatch != null) {
      return bankNameMatch;
    }

    final onlyBankWallet = _matchSingleBankWallet(
      candidateWallets,
      transaction,
    );
    if (onlyBankWallet != null) {
      return onlyBankWallet;
    }

    return defaultWallet ?? _fallbackWallet(candidateWallets);
  }

  WalletEntity? _matchBySource(
    ParsedTransaction transaction,
    List<WalletEntity> wallets,
  ) {
    final expectedType = switch (transaction.source) {
      ParsedTransactionSource.bkash => WalletType.bkash,
      ParsedTransactionSource.nagad => WalletType.nagad,
      ParsedTransactionSource.rocket => WalletType.rocket,
      _ => null,
    };
    if (expectedType == null) {
      return null;
    }
    return wallets.where((wallet) => wallet.type == expectedType).firstOrNull;
  }

  WalletEntity? _matchByAccountNumber(
    ParsedTransaction transaction,
    List<WalletEntity> wallets,
  ) {
    final target = _normalizeDigits(transaction.accountNumber);
    if (target == null || target.isEmpty) {
      return null;
    }

    for (final wallet in wallets) {
      final walletDigits = _normalizeDigits(wallet.accountNumber);
      if (walletDigits == null || walletDigits.isEmpty) {
        continue;
      }
      if (walletDigits == target || walletDigits.endsWith(target)) {
        return wallet;
      }
    }
    return null;
  }

  WalletEntity? _matchByInstitutionName(
    ParsedTransaction transaction,
    List<WalletEntity> wallets,
  ) {
    final hint = _extractBankHint(transaction);
    if (hint == null) {
      return null;
    }

    for (final wallet in wallets) {
      if (wallet.type != WalletType.bank) {
        continue;
      }
      final normalizedName = wallet.name.trim().toLowerCase();
      if (normalizedName.contains(hint)) {
        return wallet;
      }
      final aliases = _bankKeywordMap[hint] ?? const <String>[];
      if (aliases.any(normalizedName.contains)) {
        return wallet;
      }
    }
    return null;
  }

  WalletEntity? _matchSingleBankWallet(
    List<WalletEntity> wallets,
    ParsedTransaction transaction,
  ) {
    if (transaction.source != ParsedTransactionSource.bank) {
      return null;
    }
    final bankWallets = wallets
        .where((wallet) => wallet.type == WalletType.bank)
        .toList(growable: false);
    if (bankWallets.length == 1) {
      return bankWallets.first;
    }
    return null;
  }

  WalletEntity? _fallbackWallet(List<WalletEntity> wallets) {
    final sorted = [...wallets]
      ..sort((first, second) => first.sortOrder.compareTo(second.sortOrder));
    return sorted.firstOrNull;
  }

  String? _extractBankHint(ParsedTransaction transaction) {
    final haystack = [
      transaction.sender,
      transaction.sourceLabel,
      transaction.rawMessage,
      transaction.counterparty,
      transaction.merchantName,
    ].whereType<String>().join(' ').toLowerCase();

    for (final entry in _bankKeywordMap.entries) {
      if (entry.value.any(haystack.contains)) {
        return entry.key;
      }
    }
    return null;
  }

  String? _normalizeDigits(String? value) {
    if (value == null) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
