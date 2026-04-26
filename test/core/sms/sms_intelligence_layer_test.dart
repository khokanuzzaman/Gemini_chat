import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/imported_sms_model.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/sms/sms_category_mapper.dart';
import 'package:gemini_chat/core/sms/sms_duplicate_detector.dart';
import 'package:gemini_chat/core/sms/sms_filter.dart';
import 'package:gemini_chat/core/sms/sms_import_orchestrator.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';
import 'package:gemini_chat/core/sms/sms_parser.dart';
import 'package:gemini_chat/core/sms/sms_reader_service.dart';
import 'package:gemini_chat/core/sms/sms_wallet_matcher.dart';
import 'package:gemini_chat/features/category/domain/category_registry.dart';
import 'package:gemini_chat/features/category/domain/entities/category_entity.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
  });

  group('SmsCategoryMapper', () {
    const mapper = SmsCategoryMapper();

    setUp(() {
      CategoryRegistry.setCategories([
        ...defaultCategories,
        CategoryEntity(
          id: 99,
          name: 'Fuel',
          icon: 'local_gas_station',
          colorValue: 0xFF455A64,
          isDefault: false,
          sortOrder: 99,
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
    });

    tearDown(() {
      CategoryRegistry.setCategories(defaultCategories);
    });

    test(
      'prefers matching custom categories before builtin merchant keywords',
      () {
        final transaction = _transaction(
          smsId: 1,
          counterparty: 'Shell Fuel Station',
          direction: ParsedTransactionDirection.debit,
          kind: ParsedTransactionKind.cardPurchase,
        );

        expect(mapper.mapToExpenseCategory(transaction), 'Fuel');
      },
    );

    test('maps merchant keywords to default expense categories', () {
      final transaction = _transaction(
        smsId: 2,
        counterparty: 'Foodpanda Restaurant',
        direction: ParsedTransactionDirection.debit,
        kind: ParsedTransactionKind.payment,
      );

      expect(mapper.mapToExpenseCategory(transaction), 'Food');
    });

    test('maps income keywords to the correct income source', () {
      final transaction = _transaction(
        smsId: 3,
        counterparty: 'Upwork project payment',
        direction: ParsedTransactionDirection.credit,
        kind: ParsedTransactionKind.bankCredit,
      );

      expect(mapper.mapToIncomeSource(transaction), 'Freelance');
    });
  });

  group('SmsWalletMatcher', () {
    const matcher = SmsWalletMatcher();
    final wallets = [
      _wallet(
        id: 1,
        name: 'Main bKash',
        type: WalletType.bkash,
        accountNumber: '01711111111',
        sortOrder: 1,
      ),
      _wallet(
        id: 2,
        name: 'BRAC Bank Payroll',
        type: WalletType.bank,
        accountNumber: '1234',
        sortOrder: 2,
      ),
      _wallet(
        id: 3,
        name: 'Card Wallet',
        type: WalletType.card,
        accountNumber: null,
        sortOrder: 3,
      ),
    ];

    test('matches mobile wallet by parsed source', () {
      final transaction = _transaction(
        smsId: 4,
        source: ParsedTransactionSource.bkash,
        direction: ParsedTransactionDirection.debit,
        kind: ParsedTransactionKind.payment,
      );

      expect(matcher.matchWallet(transaction, wallets)?.id, 1);
    });

    test('matches bank wallet by account suffix before name fallback', () {
      final transaction = _transaction(
        smsId: 5,
        sender: 'BRACBANK',
        source: ParsedTransactionSource.bank,
        accountMask: 'A/C XXXX1234',
        direction: ParsedTransactionDirection.credit,
        kind: ParsedTransactionKind.bankCredit,
      );

      expect(matcher.matchWallet(transaction, wallets)?.id, 2);
    });

    test('returns null when no wallets exist', () {
      final transaction = _transaction(
        smsId: 6,
        direction: ParsedTransactionDirection.debit,
        kind: ParsedTransactionKind.payment,
      );

      expect(matcher.matchWallet(transaction, const []), isNull);
    });
  });

  group('SmsDuplicateDetector', () {
    late Directory tempDir;
    late Isar isar;
    late SmsDuplicateDetector detector;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-sms-');
      isar = await Isar.open(
        [ImportedSmsModelSchema],
        directory: tempDir.path,
        name:
            'sms_duplicate_detector_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      detector = SmsDuplicateDetector(isar);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('marks imported sms and exposes import stats', () async {
      final older = _sms(
        id: 11,
        address: 'bKash',
        body: 'Cash out Tk 500 completed',
        date: DateTime(2026, 4, 1, 10),
      );
      final newer = _sms(
        id: 12,
        address: 'NAGAD',
        body: 'Received Tk 1200 salary credit',
        date: DateTime(2026, 4, 2, 9),
      );

      await detector.markImported(older, expenseId: 7);
      await detector.markBatchImported([older, newer]);

      expect(await detector.isDuplicate(older), isTrue);
      expect(await detector.getImportedCount(), 2);
      expect(await detector.getLastImportDate(), newer.date);
    });

    test(
      'filterNew excludes already imported and repeated sms signatures',
      () async {
        final importedSms = _sms(
          id: 21,
          address: 'bKash',
          body: 'Payment Tk 250 at Foodpanda',
          date: DateTime(2026, 4, 10, 12),
        );
        final freshSms = _sms(
          id: 22,
          address: 'BRACBANK',
          body: 'Salary credited Tk 5000 to A/C XXXX1234',
          date: DateTime(2026, 4, 11, 9),
        );
        final repeatedFreshSms = freshSms.copyWith(id: 23);

        await detector.markImported(importedSms, expenseId: 1);

        final transactions = [
          _transaction(
            smsId: importedSms.id,
            counterparty: 'Foodpanda',
            direction: ParsedTransactionDirection.debit,
            kind: ParsedTransactionKind.payment,
          ),
          _transaction(
            smsId: freshSms.id,
            sender: freshSms.address,
            counterparty: 'Payroll',
            accountMask: 'XXXX1234',
            direction: ParsedTransactionDirection.credit,
            kind: ParsedTransactionKind.bankCredit,
          ),
          _transaction(
            smsId: repeatedFreshSms.id,
            sender: repeatedFreshSms.address,
            counterparty: 'Payroll duplicate',
            accountMask: 'XXXX1234',
            direction: ParsedTransactionDirection.credit,
            kind: ParsedTransactionKind.bankCredit,
          ),
        ];

        final filtered = await detector.filterNew(transactions, [
          importedSms,
          freshSms,
          repeatedFreshSms,
        ]);

        expect(filtered.map((item) => item.smsId), [freshSms.id]);
      },
    );
  });

  group('SmsImportOrchestrator', () {
    late Directory tempDir;
    late Isar isar;
    late SmsDuplicateDetector detector;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-sms-orchestrator-',
      );
      isar = await Isar.open(
        [ImportedSmsModelSchema],
        directory: tempDir.path,
        name:
            'sms_import_orchestrator_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      detector = SmsDuplicateDetector(isar);
      CategoryRegistry.setCategories(defaultCategories);
    });

    tearDown(() async {
      CategoryRegistry.setCategories(defaultCategories);
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'scans, deduplicates, categorizes, and wallet-matches new transactions',
      () async {
        final importedSms = _sms(
          id: 31,
          address: 'bKash',
          body: 'Payment Tk 100 at random shop',
          date: DateTime(2026, 4, 12, 8),
        );
        final newSms = _sms(
          id: 32,
          address: 'bKash',
          body: 'Payment Tk 350 at Foodpanda Restaurant',
          date: DateTime(2026, 4, 12, 9),
        );
        await detector.markImported(importedSms, expenseId: 10);

        final reader = _FakeReader([importedSms, newSms]);
        final orchestrator = SmsImportOrchestrator(
          reader: reader,
          filter: _FakeFilter([importedSms, newSms]),
          parser: _FakeParser([
            _transaction(
              smsId: importedSms.id,
              sender: importedSms.address,
              counterparty: 'Unknown Merchant',
              direction: ParsedTransactionDirection.debit,
              kind: ParsedTransactionKind.payment,
            ),
            _transaction(
              smsId: newSms.id,
              sender: newSms.address,
              counterparty: 'Foodpanda Restaurant',
              direction: ParsedTransactionDirection.debit,
              kind: ParsedTransactionKind.payment,
              source: ParsedTransactionSource.bkash,
            ),
          ]),
          categoryMapper: const SmsCategoryMapper(),
          walletMatcher: const SmsWalletMatcher(),
          duplicateDetector: detector,
        );

        final result = await orchestrator.scanForNewTransactions([
          _wallet(
            id: 41,
            name: 'Personal bKash',
            type: WalletType.bkash,
            accountNumber: '01700000000',
            sortOrder: 1,
          ),
        ]);

        expect(reader.lastSince, importedSms.date);
        expect(result.scannedCount, 2);
        expect(result.parsedCount, 2);
        expect(result.duplicateCount, 1);
        expect(result.newCount, 1);
        expect(result.candidates.single.suggestedCategory, 'Food');
        expect(
          result.candidates.single.suggestedWallet?.type,
          WalletType.bkash,
        );
      },
    );
  });
}

ParsedTransaction _transaction({
  required int smsId,
  String sender = 'bKash',
  ParsedTransactionSource source = ParsedTransactionSource.bkash,
  ParsedTransactionDirection direction = ParsedTransactionDirection.debit,
  ParsedTransactionKind kind = ParsedTransactionKind.payment,
  double amount = 120,
  String rawMessage = 'Mock message',
  DateTime? receivedAt,
  DateTime? occurredAt,
  String? counterparty,
  String? merchantName,
  String? accountMask,
}) {
  final timestamp = receivedAt ?? DateTime(2026, 4, 1, 10);
  return ParsedTransaction(
    smsId: smsId,
    sender: sender,
    source: source,
    direction: direction,
    kind: kind,
    amount: amount,
    rawMessage: rawMessage,
    receivedAt: timestamp,
    occurredAt: occurredAt ?? timestamp,
    counterparty: counterparty,
    merchantName: merchantName,
    accountMask: accountMask,
  );
}

SmsMessage _sms({
  required int id,
  required String address,
  required String body,
  required DateTime date,
}) {
  return SmsMessage(id: id, address: address, body: body, date: date);
}

WalletEntity _wallet({
  required int id,
  required String name,
  required WalletType type,
  required String? accountNumber,
  required int sortOrder,
  bool isArchived = false,
}) {
  final now = DateTime(2026, 4, 1);
  return WalletEntity(
    id: id,
    name: name,
    type: type,
    emoji: type.defaultEmoji,
    initialBalance: 0,
    currentBalance: 0,
    accountNumber: accountNumber,
    note: null,
    sortOrder: sortOrder,
    isArchived: isArchived,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeReader extends SmsReaderService {
  _FakeReader(this.messages);

  final List<SmsMessage> messages;
  DateTime? lastSince;

  @override
  Future<List<SmsMessage>> readSmsSince(DateTime since) async {
    lastSince = since;
    return messages;
  }
}

class _FakeFilter extends SmsFilter {
  const _FakeFilter(this.messages);

  final List<SmsMessage> messages;

  @override
  List<SmsMessage> filterFinancialSms(List<SmsMessage> input) => messages;
}

class _FakeParser extends SmsParserEngine {
  _FakeParser(this.transactions);

  final List<ParsedTransaction> transactions;

  @override
  List<ParsedTransaction> parseAll(List<SmsMessage> messages) => transactions;
}
