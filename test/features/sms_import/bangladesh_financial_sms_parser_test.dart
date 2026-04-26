import 'package:flutter_test/flutter_test.dart';

import 'package:gemini_chat/features/sms_import/data/parsers/bangladesh_financial_sms_parser.dart';
import 'package:gemini_chat/features/sms_import/domain/entities/parsed_sms_transaction_entity.dart';
import 'package:gemini_chat/features/sms_import/domain/entities/sms_message_entity.dart';

void main() {
  final parser = BangladeshFinancialSmsParser();

  SmsMessageEntity message({
    required int id,
    required String address,
    required String body,
    required DateTime date,
  }) {
    return SmsMessageEntity(
      id: id,
      address: address,
      body: body,
      receivedAt: date,
    );
  }

  test('parses bKash send money sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 1,
        address: 'bKash',
        body:
            'bKash: Send Money Tk 1,250.00 to 01711223344 successful. Fee Tk 5.00. Balance Tk 8,745.50. TrxID 9ABC123DEF at 27/04/2026 10:15',
        date: DateTime(2026, 4, 27, 10, 16),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.source, SmsSenderBrand.bkash);
    expect(parsed.kind, SmsTransactionKind.sendMoney);
    expect(parsed.direction, SmsTransactionDirection.debit);
    expect(parsed.amount, 1250);
    expect(parsed.fee, 5);
    expect(parsed.balanceAfter, 8745.50);
    expect(parsed.counterparty, '01711223344');
    expect(parsed.reference, '9ABC123DEF');
    expect(parsed.occurredAt, DateTime(2026, 4, 27, 10, 15));
    expect(parsed.isExpense, isTrue);
  });

  test('parses bKash received money sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 2,
        address: 'bKash',
        body:
            'bKash: Received Tk 2,000.00 from 01899887766. Fee Tk 0.00. Balance Tk 10,745.50. TrxID 8XYZ123ABC at 27/04/2026 11:00',
        date: DateTime(2026, 4, 27, 11, 1),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.kind, SmsTransactionKind.receivedMoney);
    expect(parsed.direction, SmsTransactionDirection.credit);
    expect(parsed.amount, 2000);
    expect(parsed.counterparty, '01899887766');
    expect(parsed.isIncome, isTrue);
  });

  test('parses Nagad add money as transfer-like credit', () {
    final parsed = parser.parseMessage(
      message(
        id: 3,
        address: 'Nagad',
        body:
            'Nagad: Add Money Tk 3,000.00 from BRAC Bank successful. Current Balance Tk 6,490.00. TrxID NG54321 at 27/04/2026 13:00',
        date: DateTime(2026, 4, 27, 13, 2),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.source, SmsSenderBrand.nagad);
    expect(parsed.kind, SmsTransactionKind.addMoney);
    expect(parsed.direction, SmsTransactionDirection.credit);
    expect(parsed.amount, 3000);
    expect(parsed.counterparty, 'BRAC Bank');
    expect(parsed.isTransferLike, isTrue);
    expect(parsed.isIncome, isFalse);
  });

  test('parses Rocket received money sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 4,
        address: 'Rocket',
        body:
            'Rocket: Received Tk 1,100.00 from 01900112233. Balance Tk 7,600.00. TxnID RK654321 at 27/04/2026 14:00',
        date: DateTime(2026, 4, 27, 14, 1),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.source, SmsSenderBrand.rocket);
    expect(parsed.kind, SmsTransactionKind.receivedMoney);
    expect(parsed.amount, 1100);
    expect(parsed.counterparty, '01900112233');
    expect(parsed.reference, 'RK654321');
  });

  test('parses bank card purchase sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 5,
        address: 'BRACBANK',
        body:
            'BRAC Bank: POS Purchase of BDT 2,450.00 using Card XX1234 on 27/04/2026 15:45 at DARAZ. Avl Bal BDT 45,500.75. Ref 998877',
        date: DateTime(2026, 4, 27, 15, 46),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.source, SmsSenderBrand.bank);
    expect(parsed.kind, SmsTransactionKind.cardPurchase);
    expect(parsed.direction, SmsTransactionDirection.debit);
    expect(parsed.amount, 2450);
    expect(parsed.merchantName, 'DARAZ');
    expect(parsed.accountMask, 'XX1234');
    expect(parsed.balanceAfter, 45500.75);
    expect(parsed.reference, '998877');
  });

  test('parses bank credit sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 6,
        address: 'EBL',
        body:
            'EBL: Salary credited to A/C XX9876 by BDT 25,000.00 on 27/04/2026 09:00. Avl Bal BDT 78,000.00. Ref SALAPR',
        date: DateTime(2026, 4, 27, 9, 1),
      ),
    );

    expect(parsed, isNotNull);
    expect(parsed!.kind, SmsTransactionKind.bankCredit);
    expect(parsed.direction, SmsTransactionDirection.credit);
    expect(parsed.amount, 25000);
    expect(parsed.accountMask, 'XX9876');
    expect(parsed.balanceAfter, 78000);
  });

  test('returns null for non financial sms', () {
    final parsed = parser.parseMessage(
      message(
        id: 7,
        address: 'Google',
        body: 'Your OTP is 123456 for login. Do not share it with anyone.',
        date: DateTime(2026, 4, 27, 16),
      ),
    );

    expect(parsed, isNull);
  });

  test('parseMessages filters unknown sms and sorts by occurred time', () {
    final parsed = parser.parseMessages([
      message(
        id: 8,
        address: 'bKash',
        body:
            'bKash: Received Tk 500.00 from 01700000000. Balance Tk 1,500.00. TrxID R1 at 27/04/2026 08:00',
        date: DateTime(2026, 4, 27, 8, 1),
      ),
      message(
        id: 9,
        address: 'Google',
        body: 'Plain text message',
        date: DateTime(2026, 4, 27, 9),
      ),
      message(
        id: 10,
        address: 'Nagad',
        body:
            'Nagad: Cash Out Tk 600.00 from 01700112233 successful. Fee Tk 10.00. Current Balance Tk 2,490.00. TrxID NG12345 at 27/04/2026 12:00',
        date: DateTime(2026, 4, 27, 12, 1),
      ),
    ]);

    expect(parsed, hasLength(2));
    expect(parsed.first.messageId, 10);
    expect(parsed.last.messageId, 8);
  });
}
