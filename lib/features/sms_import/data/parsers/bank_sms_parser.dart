import '../../domain/entities/parsed_sms_transaction_entity.dart';
import '../../domain/entities/sms_message_entity.dart';
import 'financial_sms_message_parser.dart';
import 'sms_parser_utils.dart';

class BankSmsParser extends FinancialSmsMessageParser {
  const BankSmsParser();

  static const _bankKeywords = [
    'bank',
    'brac',
    'ebl',
    'city bank',
    'dbbl',
    'dutch-bangla',
    'hsbc',
    'standard chartered',
    'scb',
    'one bank',
    'prime bank',
    'trust bank',
    'mutual trust',
    'southeast bank',
    'ucb',
    'bank asia',
    'islami bank',
    'a/c',
    'acct',
    'account',
    'card',
  ];

  static final RegExp _hasDirectionKeyword = RegExp(
    r'\b(debit(?:ed)?|credit(?:ed)?|withdraw(?:n|al)?|purchase|pos|transfer|deposit(?:ed)?|salary)\b',
    caseSensitive: false,
  );

  @override
  bool canParse(SmsMessageEntity message) {
    final haystack = '${message.address} ${message.body}';
    if (SmsParserUtils.containsAny(haystack, _bankKeywords)) {
      return true;
    }
    return _hasDirectionKeyword.hasMatch(message.body) &&
        SmsParserUtils.extractFirstAmount(message.body) != null;
  }

  @override
  ParsedSmsTransactionEntity? parse(SmsMessageEntity message) {
    if (!canParse(message)) {
      return null;
    }

    final body = SmsParserUtils.normalize(message.body);
    final lower = body.toLowerCase();
    final amount = SmsParserUtils.extractFirstAmount(body, [
      RegExp(
        r'(?:purchase(?: of)?|debited(?: by)?|credited(?: by)?|withdrawn(?: by)?|deposit(?:ed)?(?: by)?|transferred(?: by)?|transfer(?: of)?|salary credited(?: by)?)[^0-9A-Za-z]{0,12}(?:tk|bdt)\s*([0-9,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(r'(?:tk|bdt)\s*([0-9,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ]);
    if (amount == null) {
      return null;
    }

    final direction = _resolveDirection(lower);
    final kind = _resolveKind(lower, direction);
    if (direction == SmsTransactionDirection.unknown &&
        kind == SmsTransactionKind.unknown) {
      return null;
    }

    return ParsedSmsTransactionEntity(
      messageId: message.id,
      senderAddress: message.address,
      source: SmsSenderBrand.bank,
      direction: direction,
      kind: kind,
      amount: amount,
      rawMessage: message.body,
      receivedAt: message.receivedAt,
      occurredAt: SmsParserUtils.resolveOccurredAt(message),
      fee: SmsParserUtils.extractFee(message.body),
      balanceAfter: SmsParserUtils.extractBalance(message.body),
      reference: SmsParserUtils.extractReference(message.body),
      counterparty: _extractCounterparty(body, direction),
      merchantName: _extractMerchant(body, lower),
      accountMask: SmsParserUtils.extractAccountMask(message.body),
      confidence: 0.9,
    );
  }

  SmsTransactionDirection _resolveDirection(String body) {
    if (_contains(body, const ['credited', 'credit', 'deposit', 'received'])) {
      return SmsTransactionDirection.credit;
    }
    if (_contains(body, const ['debited', 'debit', 'withdraw', 'purchase'])) {
      return SmsTransactionDirection.debit;
    }
    if (body.contains('transfer')) {
      if (_contains(body, const ['to '])) {
        return SmsTransactionDirection.debit;
      }
      if (_contains(body, const ['from '])) {
        return SmsTransactionDirection.credit;
      }
    }
    return SmsTransactionDirection.unknown;
  }

  SmsTransactionKind _resolveKind(
    String body,
    SmsTransactionDirection direction,
  ) {
    if (_contains(body, const ['atm', 'withdrawal', 'withdrawn'])) {
      return SmsTransactionKind.atmWithdrawal;
    }
    if (_contains(body, const ['pos', 'purchase', 'using card'])) {
      return SmsTransactionKind.cardPurchase;
    }
    if (_contains(body, const ['bill pay', 'bill payment'])) {
      return SmsTransactionKind.billPay;
    }
    if (body.contains('transfer')) {
      return SmsTransactionKind.transfer;
    }
    if (direction == SmsTransactionDirection.credit) {
      return SmsTransactionKind.bankCredit;
    }
    if (direction == SmsTransactionDirection.debit) {
      return SmsTransactionKind.bankDebit;
    }
    return SmsTransactionKind.unknown;
  }

  String? _extractCounterparty(String body, SmsTransactionDirection direction) {
    if (direction == SmsTransactionDirection.credit) {
      return SmsParserUtils.extractPartyAfterFrom(body);
    }
    if (direction == SmsTransactionDirection.debit &&
        body.toLowerCase().contains('transfer')) {
      return SmsParserUtils.extractPartyAfterTo(body);
    }
    return null;
  }

  String? _extractMerchant(String body, String lower) {
    if (_contains(lower, const ['purchase', 'pos', 'merchant'])) {
      return SmsParserUtils.extractMerchant(body);
    }
    return null;
  }

  bool _contains(String body, Iterable<String> keywords) {
    return keywords.any(body.contains);
  }
}
