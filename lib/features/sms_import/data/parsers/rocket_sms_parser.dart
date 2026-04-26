import '../../domain/entities/parsed_sms_transaction_entity.dart';
import '../../domain/entities/sms_message_entity.dart';
import 'financial_sms_message_parser.dart';
import 'sms_parser_utils.dart';

class RocketSmsParser extends FinancialSmsMessageParser {
  const RocketSmsParser();

  static const _brandKeywords = [
    'rocket',
    'dbbl mobile banking',
    'dutch-bangla mobile banking',
  ];

  @override
  bool canParse(SmsMessageEntity message) {
    return SmsParserUtils.containsAny(
      '${message.address} ${message.body}',
      _brandKeywords,
    );
  }

  @override
  ParsedSmsTransactionEntity? parse(SmsMessageEntity message) {
    if (!canParse(message)) {
      return null;
    }

    final body = SmsParserUtils.normalize(message.body);
    final lower = body.toLowerCase();
    final amount = SmsParserUtils.extractFirstAmount(body);
    if (amount == null) {
      return null;
    }

    if (_contains(lower, const ['send money', 'sendmoney', 'transfer'])) {
      return _build(
        message,
        amount: amount,
        kind: SmsTransactionKind.sendMoney,
        direction: SmsTransactionDirection.debit,
        counterparty: SmsParserUtils.extractPartyAfterTo(body),
      );
    }

    if (_contains(lower, const ['cash out', 'cashout', 'cash-out'])) {
      return _build(
        message,
        amount: amount,
        kind: SmsTransactionKind.cashOut,
        direction: SmsTransactionDirection.debit,
        counterparty: SmsParserUtils.extractPartyAfterFrom(body),
      );
    }

    if (_contains(lower, const ['payment'])) {
      return _build(
        message,
        amount: amount,
        kind: SmsTransactionKind.payment,
        direction: SmsTransactionDirection.debit,
        merchantName:
            SmsParserUtils.extractPartyAfterTo(body) ??
            SmsParserUtils.extractMerchant(body),
      );
    }

    if (_contains(lower, const ['cash in', 'cashin', 'add money'])) {
      return _build(
        message,
        amount: amount,
        kind: SmsTransactionKind.cashIn,
        direction: SmsTransactionDirection.credit,
        counterparty: SmsParserUtils.extractPartyAfterFrom(body),
      );
    }

    if (_contains(lower, const ['received', 'received money'])) {
      return _build(
        message,
        amount: amount,
        kind: SmsTransactionKind.receivedMoney,
        direction: SmsTransactionDirection.credit,
        counterparty: SmsParserUtils.extractPartyAfterFrom(body),
      );
    }

    return null;
  }

  ParsedSmsTransactionEntity _build(
    SmsMessageEntity message, {
    required double amount,
    required SmsTransactionKind kind,
    required SmsTransactionDirection direction,
    String? counterparty,
    String? merchantName,
  }) {
    return ParsedSmsTransactionEntity(
      messageId: message.id,
      senderAddress: message.address,
      source: SmsSenderBrand.rocket,
      direction: direction,
      kind: kind,
      amount: amount,
      rawMessage: message.body,
      receivedAt: message.receivedAt,
      occurredAt: SmsParserUtils.resolveOccurredAt(message),
      fee: SmsParserUtils.extractFee(message.body),
      balanceAfter: SmsParserUtils.extractBalance(message.body),
      reference: SmsParserUtils.extractReference(message.body),
      counterparty: counterparty,
      merchantName: merchantName,
      accountMask: SmsParserUtils.extractAccountMask(message.body),
    );
  }

  bool _contains(String body, Iterable<String> keywords) {
    return keywords.any(body.contains);
  }
}
