import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/core/sms/sms_filter.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';

void main() {
  const filter = SmsFilter();

  SmsMessage message({
    required int id,
    required String address,
    required String body,
  }) {
    return SmsMessage(
      id: id,
      address: address,
      body: body,
      date: DateTime(2026, 5, 4, 10),
    );
  }

  test('keeps EBL bank credit messages in financial scan results', () {
    final result = filter.filterFinancialSms([
      message(
        id: 1,
        address: 'EBL',
        body:
            'EBL: Salary credited to A/C XX9876 by BDT 25,000.00 on 27/04/2026 09:00. Avl Bal BDT 78,000.00. Ref SALAPR',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.first.address, 'EBL');
  });

  test('keeps SCB DR style bank debit messages in financial scan results', () {
    final result = filter.filterFinancialSms([
      message(
        id: 2,
        address: 'SCB',
        body:
            'SCB: A/C XX1234 DR by BDT 1,250.00 on 27/04/2026 15:45 at DARAZ. Avl Bal BDT 45,500.75. Ref 998877',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.first.address, 'SCB');
  });

  test('rejects bank otp messages', () {
    final result = filter.filterFinancialSms([
      message(
        id: 3,
        address: 'HSBC',
        body: 'Your OTP is 123456 for card verification. Do not share it.',
      ),
    ]);

    expect(result, isEmpty);
  });
}
