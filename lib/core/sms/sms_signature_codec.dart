import 'sms_message.dart';

class SmsSignatureCodec {
  const SmsSignatureCodec();

  String generateSignature(SmsMessage sms) {
    final bodyHash = _stableHash(sms.body);
    final raw = '${sms.address}|${sms.date.millisecondsSinceEpoch}|$bodyHash';
    return _stableHash(raw).toRadixString(16);
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
