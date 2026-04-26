enum SmsSenderBrand { bkash, nagad, rocket, bank, unknown }

enum SmsTransactionDirection { debit, credit, unknown }

enum SmsTransactionKind {
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

class ParsedSmsTransactionEntity {
  const ParsedSmsTransactionEntity({
    required this.messageId,
    required this.senderAddress,
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
    this.confidence = 1,
  });

  final int messageId;
  final String senderAddress;
  final SmsSenderBrand source;
  final SmsTransactionDirection direction;
  final SmsTransactionKind kind;
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
  final double confidence;

  bool get isExpense =>
      direction == SmsTransactionDirection.debit && !isTransferLike;

  bool get isIncome =>
      direction == SmsTransactionDirection.credit && !isTransferLike;

  bool get isTransferLike => switch (kind) {
    SmsTransactionKind.addMoney ||
    SmsTransactionKind.cashIn ||
    SmsTransactionKind.transfer => true,
    _ => false,
  };

  String get sourceLabelBn => switch (source) {
    SmsSenderBrand.bkash => 'বিকাশ',
    SmsSenderBrand.nagad => 'নগদ',
    SmsSenderBrand.rocket => 'রকেট',
    SmsSenderBrand.bank => 'ব্যাংক',
    SmsSenderBrand.unknown => 'অজানা',
  };

  String get kindLabelBn => switch (kind) {
    SmsTransactionKind.sendMoney => 'সেন্ড মানি',
    SmsTransactionKind.receivedMoney => 'টাকা পেয়েছেন',
    SmsTransactionKind.cashOut => 'ক্যাশ আউট',
    SmsTransactionKind.cashIn => 'ক্যাশ ইন',
    SmsTransactionKind.payment => 'পেমেন্ট',
    SmsTransactionKind.addMoney => 'অ্যাড মানি',
    SmsTransactionKind.bankDebit => 'ডেবিট',
    SmsTransactionKind.bankCredit => 'ক্রেডিট',
    SmsTransactionKind.transfer => 'ট্রান্সফার',
    SmsTransactionKind.atmWithdrawal => 'এটিএম উত্তোলন',
    SmsTransactionKind.cardPurchase => 'কার্ড কেনাকাটা',
    SmsTransactionKind.billPay => 'বিল পরিশোধ',
    SmsTransactionKind.unknown => 'লেনদেন',
  };

  String get suggestedDescription {
    final party = merchantName ?? counterparty;
    if (party == null || party.isEmpty) {
      return '$sourceLabelBn ${kindLabelBn.toLowerCase()}';
    }
    return '$sourceLabelBn $party';
  }

  ParsedSmsTransactionEntity copyWith({
    int? messageId,
    String? senderAddress,
    SmsSenderBrand? source,
    SmsTransactionDirection? direction,
    SmsTransactionKind? kind,
    double? amount,
    String? rawMessage,
    DateTime? receivedAt,
    DateTime? occurredAt,
    Object? fee = _parsedSmsUnset,
    Object? balanceAfter = _parsedSmsUnset,
    Object? reference = _parsedSmsUnset,
    Object? counterparty = _parsedSmsUnset,
    Object? merchantName = _parsedSmsUnset,
    Object? accountMask = _parsedSmsUnset,
    double? confidence,
  }) {
    return ParsedSmsTransactionEntity(
      messageId: messageId ?? this.messageId,
      senderAddress: senderAddress ?? this.senderAddress,
      source: source ?? this.source,
      direction: direction ?? this.direction,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      rawMessage: rawMessage ?? this.rawMessage,
      receivedAt: receivedAt ?? this.receivedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      fee: fee == _parsedSmsUnset ? this.fee : fee as double?,
      balanceAfter: balanceAfter == _parsedSmsUnset
          ? this.balanceAfter
          : balanceAfter as double?,
      reference: reference == _parsedSmsUnset
          ? this.reference
          : reference as String?,
      counterparty: counterparty == _parsedSmsUnset
          ? this.counterparty
          : counterparty as String?,
      merchantName: merchantName == _parsedSmsUnset
          ? this.merchantName
          : merchantName as String?,
      accountMask: accountMask == _parsedSmsUnset
          ? this.accountMask
          : accountMask as String?,
      confidence: confidence ?? this.confidence,
    );
  }
}

const _parsedSmsUnset = Object();
