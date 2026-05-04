import '../ai/bangla_date_parser.dart';
import 'sms_message.dart';

class SmsFilter {
  const SmsFilter();

  static final Set<String> _knownSenderIds = {
    'bkash',
    '16247',
    '01313016247',
    'nagad',
    '16167',
    'rocket',
    '16216',
    'bracbank',
    'citybank',
    'ebl',
    'eblbank',
    'easternbank',
    'dutchbangla',
    'dbbl',
    'islamibank',
    'ucb',
    'mtbl',
    'mutualtrust',
    'mutualtrustbank',
    'pubalibank',
    'onebank',
    'primebank',
    'southeastbank',
    'southeast',
    'scb',
    'standardchar',
    'standardchartered',
    'standardcharteredbank',
    'trustbank',
    'bankasia',
    'hsbc',
    'hsbcbd',
  };

  static const List<String> _containsSenderIds = [
    'bkash',
    'nagad',
    'rocket',
    'bracbank',
    'citybank',
    'ebl',
    'easternbank',
    'dbbl',
    'dutchbangla',
    'islamibank',
    'ucb',
    'mtbl',
    'mutualtrust',
    'pubalibank',
    'onebank',
    'primebank',
    'southeast',
    'scb',
    'standardchar',
    'standardchartered',
    'trustbank',
    'bankasia',
    'hsbc',
  ];

  static const List<String> _amountIndicators = [
    'tk',
    'bdt',
    '৳',
    'taka',
    'টাকা',
  ];

  static const List<String> _transactionKeywords = [
    'sent',
    'send money',
    'sendmoney',
    'received',
    'payment',
    'cashout',
    'cash out',
    'cashin',
    'cash in',
    'transfer',
    'withdraw',
    'deposit',
    'purchase',
    'refund',
    'credit',
    'credited',
    'debit',
    'debited',
    'withdrawal',
    'atm',
    'pos',
    'add money',
    'salary',
    'disbursement',
    'টাকা',
    'পেয়েছেন',
    'পেয়েছেন',
    'পরিশোধ',
    'উত্তোলন',
    'জমা',
  ];

  static const List<String> _bankContextKeywords = [
    'a/c',
    'acct',
    'account',
    'card',
    'avl bal',
    'available balance',
    'current balance',
    'brac bank',
    'city bank',
    'ebl',
    'eastern bank',
    'dutch-bangla',
    'hsbc',
    'standard chartered',
    'trust bank',
    'mutual trust',
    'bank asia',
    'islami bank',
    'one bank',
    'prime bank',
    'southeast bank',
    'pubali bank',
  ];

  static const List<String> _bankTransactionKeywords = [
    'credit',
    'credited',
    'debit',
    'debited',
    'withdraw',
    'withdrawal',
    'purchase',
    'pos',
    'transfer',
    'deposit',
    'salary',
  ];

  static final RegExp _bankDrCrPattern = RegExp(
    r'\b(?:dr|cr)\b',
    caseSensitive: false,
  );

  static const List<String> _rejectKeywords = [
    'otp',
    'pin',
    'password',
    'promotional',
    'offer',
    'discount',
    'cashback offer',
    'balance inquiry',
    'পাসওয়ার্ড',
    'পাসওয়ার্ড',
  ];

  List<SmsMessage> filterFinancialSms(List<SmsMessage> messages) {
    final filtered = messages.where(_isFinancialMessage).toList(growable: false);
    filtered.sort((first, second) => second.date.compareTo(first.date));
    return filtered;
  }

  bool _isFinancialMessage(SmsMessage message) {
    final sender = _normalizeSender(message.address);
    final body = message.body.trim();
    final lowerBody = BanglaDateParser.convertBanglaDigits(body).toLowerCase();

    if (body.length < 20) {
      return false;
    }

    final looksLikeBankMessage = _looksLikeBankMessage(lowerBody);

    if (!_isKnownFinancialSender(sender) && !looksLikeBankMessage) {
      return false;
    }

    if (_containsAny(lowerBody, _rejectKeywords)) {
      return false;
    }

    if (!_containsAny(lowerBody, _amountIndicators)) {
      return false;
    }

    final hasTransactionKeyword =
        _containsAny(lowerBody, _transactionKeywords) ||
        _bankDrCrPattern.hasMatch(lowerBody);

    if (!hasTransactionKeyword && !looksLikeBankMessage) {
      return false;
    }

    return true;
  }

  bool _isKnownFinancialSender(String sender) {
    if (_knownSenderIds.contains(sender)) {
      return true;
    }
    return _containsSenderIds.any(sender.contains);
  }

  bool _containsAny(String body, List<String> keywords) {
    return keywords.any(body.contains);
  }

  bool _looksLikeBankMessage(String body) {
    if (!_containsAny(body, _bankContextKeywords)) {
      return false;
    }
    return _containsAny(body, _bankTransactionKeywords) ||
        _bankDrCrPattern.hasMatch(body);
  }

  String _normalizeSender(String sender) {
    return BanglaDateParser.convertBanglaDigits(
      sender,
    ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
