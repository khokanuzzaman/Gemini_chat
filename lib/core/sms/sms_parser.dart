import '../../features/sms_import/data/parsers/bangladesh_financial_sms_parser.dart';
import '../../features/sms_import/domain/entities/parsed_sms_transaction_entity.dart';
import '../../features/sms_import/domain/entities/sms_message_entity.dart';
import 'parsed_transaction.dart';
import 'sms_filter.dart';
import 'sms_message.dart';

class SmsParserEngine {
  SmsParserEngine({BangladeshFinancialSmsParser? parser})
    : _parser = parser ?? BangladeshFinancialSmsParser();

  final BangladeshFinancialSmsParser _parser;

  ParsedTransaction? tryParse(SmsMessage sms) {
    final parsed = _parser.parseMessage(_toEntity(sms));
    if (parsed == null) {
      return null;
    }
    return _fromEntity(parsed);
  }

  List<ParsedTransaction> parseAll(List<SmsMessage> messages) {
    final parsed = messages
        .map(tryParse)
        .whereType<ParsedTransaction>()
        .toList(growable: false);
    parsed.sort((first, second) => second.occurredAt.compareTo(first.occurredAt));
    return parsed;
  }

  SmsMessageEntity _toEntity(SmsMessage sms) {
    return SmsMessageEntity(
      id: sms.id,
      address: sms.address,
      body: sms.body,
      receivedAt: sms.date,
      threadId: sms.threadId,
    );
  }

  ParsedTransaction _fromEntity(ParsedSmsTransactionEntity parsed) {
    return ParsedTransaction(
      smsId: parsed.messageId,
      sender: parsed.senderAddress,
      source: _mapSource(parsed.source),
      direction: _mapDirection(parsed.direction),
      kind: _mapKind(parsed.kind),
      amount: parsed.amount,
      rawMessage: parsed.rawMessage,
      receivedAt: parsed.receivedAt,
      occurredAt: parsed.occurredAt,
      fee: parsed.fee,
      balanceAfter: parsed.balanceAfter,
      reference: parsed.reference,
      counterparty: parsed.counterparty,
      merchantName: parsed.merchantName,
      accountMask: parsed.accountMask,
      rawCategory: _mapRawCategory(parsed),
      confidence: parsed.confidence,
    );
  }

  ParsedTransactionSource _mapSource(SmsSenderBrand source) {
    return switch (source) {
      SmsSenderBrand.bkash => ParsedTransactionSource.bkash,
      SmsSenderBrand.nagad => ParsedTransactionSource.nagad,
      SmsSenderBrand.rocket => ParsedTransactionSource.rocket,
      SmsSenderBrand.bank => ParsedTransactionSource.bank,
      SmsSenderBrand.unknown => ParsedTransactionSource.unknown,
    };
  }

  ParsedTransactionDirection _mapDirection(SmsTransactionDirection direction) {
    return switch (direction) {
      SmsTransactionDirection.debit => ParsedTransactionDirection.debit,
      SmsTransactionDirection.credit => ParsedTransactionDirection.credit,
      SmsTransactionDirection.unknown => ParsedTransactionDirection.unknown,
    };
  }

  ParsedTransactionKind _mapKind(SmsTransactionKind kind) {
    return switch (kind) {
      SmsTransactionKind.sendMoney => ParsedTransactionKind.sendMoney,
      SmsTransactionKind.receivedMoney => ParsedTransactionKind.receivedMoney,
      SmsTransactionKind.cashOut => ParsedTransactionKind.cashOut,
      SmsTransactionKind.cashIn => ParsedTransactionKind.cashIn,
      SmsTransactionKind.payment => ParsedTransactionKind.payment,
      SmsTransactionKind.addMoney => ParsedTransactionKind.addMoney,
      SmsTransactionKind.bankDebit => ParsedTransactionKind.bankDebit,
      SmsTransactionKind.bankCredit => ParsedTransactionKind.bankCredit,
      SmsTransactionKind.transfer => ParsedTransactionKind.transfer,
      SmsTransactionKind.atmWithdrawal => ParsedTransactionKind.atmWithdrawal,
      SmsTransactionKind.cardPurchase => ParsedTransactionKind.cardPurchase,
      SmsTransactionKind.billPay => ParsedTransactionKind.billPay,
      SmsTransactionKind.unknown => ParsedTransactionKind.unknown,
    };
  }

  String? _mapRawCategory(ParsedSmsTransactionEntity parsed) {
    if (parsed.merchantName != null && parsed.merchantName!.trim().isNotEmpty) {
      return parsed.merchantName;
    }
    return switch (parsed.kind) {
      SmsTransactionKind.sendMoney => 'Send Money',
      SmsTransactionKind.receivedMoney => 'Received Money',
      SmsTransactionKind.cashOut => 'Cash Out',
      SmsTransactionKind.cashIn => 'Cash In',
      SmsTransactionKind.payment => 'Payment',
      SmsTransactionKind.addMoney => 'Add Money',
      SmsTransactionKind.bankDebit => 'Bank Debit',
      SmsTransactionKind.bankCredit => 'Bank Credit',
      SmsTransactionKind.transfer => 'Transfer',
      SmsTransactionKind.atmWithdrawal => 'ATM Withdrawal',
      SmsTransactionKind.cardPurchase => 'Card Purchase',
      SmsTransactionKind.billPay => 'Bill Pay',
      SmsTransactionKind.unknown => null,
    };
  }
}

class SmsParser extends SmsParserEngine {
  SmsParser({super.parser, SmsFilter? filter})
    : _filter = filter ?? const SmsFilter();

  final SmsFilter _filter;

  ParsedTransaction? parseMessage(SmsMessage message) => tryParse(message);

  List<ParsedTransaction> parseMessages(
    List<SmsMessage> messages, {
    bool applyFilter = true,
  }) {
    final source = applyFilter
        ? _filter.filterFinancialSms(messages)
        : List<SmsMessage>.from(messages);
    return parseAll(source);
  }
}
