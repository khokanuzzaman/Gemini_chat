enum ParsedTransactionSource { bkash, nagad, rocket, bank, unknown }

extension ParsedTransactionSourceX on ParsedTransactionSource {
  String get label => switch (this) {
    ParsedTransactionSource.bkash => 'bKash',
    ParsedTransactionSource.nagad => 'Nagad',
    ParsedTransactionSource.rocket => 'Rocket',
    ParsedTransactionSource.bank => 'Bank',
    ParsedTransactionSource.unknown => 'Unknown',
  };

  String get labelBn => switch (this) {
    ParsedTransactionSource.bkash => 'বিকাশ',
    ParsedTransactionSource.nagad => 'নগদ',
    ParsedTransactionSource.rocket => 'রকেট',
    ParsedTransactionSource.bank => 'ব্যাংক',
    ParsedTransactionSource.unknown => 'অজানা',
  };
}

enum ParsedTransactionDirection { debit, credit, unknown }

enum ParsedTransactionKind {
  sendMoney,
  receivedMoney,
  cashOut,
  cashIn,
  payment,
  addMoney,
  bankDebit,
  bankCredit,
  transfer,
  atmWithdrawal,
  cardPurchase,
  billPay,
  unknown,
}

extension ParsedTransactionKindX on ParsedTransactionKind {
  String get label => switch (this) {
    ParsedTransactionKind.sendMoney => 'Send Money',
    ParsedTransactionKind.receivedMoney => 'Received Money',
    ParsedTransactionKind.cashOut => 'Cash Out',
    ParsedTransactionKind.cashIn => 'Cash In',
    ParsedTransactionKind.payment => 'Payment',
    ParsedTransactionKind.addMoney => 'Add Money',
    ParsedTransactionKind.bankDebit => 'Bank Debit',
    ParsedTransactionKind.bankCredit => 'Bank Credit',
    ParsedTransactionKind.transfer => 'Transfer',
    ParsedTransactionKind.atmWithdrawal => 'ATM Withdrawal',
    ParsedTransactionKind.cardPurchase => 'Card Purchase',
    ParsedTransactionKind.billPay => 'Bill Pay',
    ParsedTransactionKind.unknown => 'Unknown',
  };

  String get labelBn => switch (this) {
    ParsedTransactionKind.sendMoney => 'সেন্ড মানি',
    ParsedTransactionKind.receivedMoney => 'টাকা পেয়েছেন',
    ParsedTransactionKind.cashOut => 'ক্যাশ আউট',
    ParsedTransactionKind.cashIn => 'ক্যাশ ইন',
    ParsedTransactionKind.payment => 'পেমেন্ট',
    ParsedTransactionKind.addMoney => 'অ্যাড মানি',
    ParsedTransactionKind.bankDebit => 'ডেবিট',
    ParsedTransactionKind.bankCredit => 'ক্রেডিট',
    ParsedTransactionKind.transfer => 'ট্রান্সফার',
    ParsedTransactionKind.atmWithdrawal => 'এটিএম উত্তোলন',
    ParsedTransactionKind.cardPurchase => 'কার্ড কেনাকাটা',
    ParsedTransactionKind.billPay => 'বিল পরিশোধ',
    ParsedTransactionKind.unknown => 'লেনদেন',
  };
}

enum TransactionType { expense, income, transfer, unknown }

class ParsedTransaction {
  const ParsedTransaction({
    required this.smsId,
    required this.sender,
    required this.source,
    required this.direction,
    required this.kind,
    required this.amount,
    required this.rawMessage,
    required this.receivedAt,
    required this.occurredAt,
    this.fee,
    this.balanceAfter,
    this.reference,
    this.counterparty,
    this.merchantName,
    this.accountMask,
    this.rawCategory,
    this.confidence = 1,
  });

  final int smsId;
  final String sender;
  final ParsedTransactionSource source;
  final ParsedTransactionDirection direction;
  final ParsedTransactionKind kind;
  final double amount;
  final String rawMessage;
  final DateTime receivedAt;
  final DateTime occurredAt;
  final double? fee;
  final double? balanceAfter;
  final String? reference;
  final String? counterparty;
  final String? merchantName;
  final String? accountMask;
  final String? rawCategory;
  final double confidence;

  TransactionType get type {
    if (isExpense) {
      return TransactionType.expense;
    }
    if (isIncome) {
      return TransactionType.income;
    }
    if (isTransferLike) {
      return TransactionType.transfer;
    }
    return TransactionType.unknown;
  }

  double? get balance => balanceAfter;

  String get sourceLabel => source.label;

  String? get accountNumber {
    final digits = accountMask?.replaceAll(RegExp(r'\D'), '');
    if (digits == null || digits.isEmpty) {
      return null;
    }
    if (digits.length <= 4) {
      return digits;
    }
    return digits.substring(digits.length - 4);
  }

  bool get isExpense =>
      direction == ParsedTransactionDirection.debit && !isTransferLike;

  bool get isIncome =>
      direction == ParsedTransactionDirection.credit && !isTransferLike;

  bool get isTransferLike => switch (kind) {
    ParsedTransactionKind.addMoney ||
    ParsedTransactionKind.cashIn ||
    ParsedTransactionKind.transfer => true,
    _ => false,
  };

  ParsedTransaction copyWith({
    int? smsId,
    String? sender,
    ParsedTransactionSource? source,
    ParsedTransactionDirection? direction,
    ParsedTransactionKind? kind,
    double? amount,
    String? rawMessage,
    DateTime? receivedAt,
    DateTime? occurredAt,
    Object? fee = _parsedTransactionUnset,
    Object? balanceAfter = _parsedTransactionUnset,
    Object? reference = _parsedTransactionUnset,
    Object? counterparty = _parsedTransactionUnset,
    Object? merchantName = _parsedTransactionUnset,
    Object? accountMask = _parsedTransactionUnset,
    Object? rawCategory = _parsedTransactionUnset,
    double? confidence,
  }) {
    return ParsedTransaction(
      smsId: smsId ?? this.smsId,
      sender: sender ?? this.sender,
      source: source ?? this.source,
      direction: direction ?? this.direction,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      rawMessage: rawMessage ?? this.rawMessage,
      receivedAt: receivedAt ?? this.receivedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      fee: fee == _parsedTransactionUnset ? this.fee : fee as double?,
      balanceAfter: balanceAfter == _parsedTransactionUnset
          ? this.balanceAfter
          : balanceAfter as double?,
      reference: reference == _parsedTransactionUnset
          ? this.reference
          : reference as String?,
      counterparty: counterparty == _parsedTransactionUnset
          ? this.counterparty
          : counterparty as String?,
      merchantName: merchantName == _parsedTransactionUnset
          ? this.merchantName
          : merchantName as String?,
      accountMask: accountMask == _parsedTransactionUnset
          ? this.accountMask
          : accountMask as String?,
      rawCategory: rawCategory == _parsedTransactionUnset
          ? this.rawCategory
          : rawCategory as String?,
      confidence: confidence ?? this.confidence,
    );
  }
}

const _parsedTransactionUnset = Object();
