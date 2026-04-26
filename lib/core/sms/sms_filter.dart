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
    'eblbank',
    'dutchbangla',
    'dbbl',
    'islamibank',
    'ucb',
    'mtbl',
    'pubalibank',
    'onebank',
    'primebank',
    'southeast',
    'standardchar',
    'hsbcbd',
  };

  static const List<String> _containsSenderIds = ['bkash', 'nagad', 'rocket'];

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
    'credited',
    'debited',
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

    if (!_isKnownFinancialSender(sender)) {
      return false;
    }

    if (_containsAny(lowerBody, _rejectKeywords)) {
      return false;
    }

    if (!_containsAny(lowerBody, _amountIndicators)) {
      return false;
    }

    if (!_containsAny(lowerBody, _transactionKeywords)) {
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

  String _normalizeSender(String sender) {
    return BanglaDateParser.convertBanglaDigits(
      sender,
    ).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
