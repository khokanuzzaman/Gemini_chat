import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/imported_sms_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_entry_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_sync_state_model.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/sms/sms_category_mapper.dart';
import 'package:gemini_chat/core/sms/sms_filter.dart';
import 'package:gemini_chat/core/sms/sms_ledger_service.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';
import 'package:gemini_chat/core/sms/sms_parser.dart';
import 'package:gemini_chat/core/sms/sms_reader_service.dart';
import 'package:gemini_chat/core/sms/sms_wallet_matcher.dart';

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

  group('SmsLedgerService', () {
    late Directory tempDir;
    late Isar isar;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-ledger-');
      isar = await Isar.open(
        [
          ImportedSmsModelSchema,
          SmsLedgerEntryModelSchema,
          SmsLedgerSyncStateModelSchema,
        ],
        directory: tempDir.path,
        name: 'sms_ledger_test_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('first sync backfills more than 500 SMS by paging', () async {
      final messages = [
        for (var index = 0; index < 620; index++)
          _sms(
            id: index + 1,
            address: 'bKash',
            body: 'Payment ${index + 1}',
            date: DateTime(2026, 4, 28, 12).subtract(Duration(minutes: index)),
          ),
      ];
      final service = SmsLedgerService(
        isar: isar,
        reader: _PagedFakeReader(messages),
        filter: const _PassThroughFilter(),
        parser: _MappedParser({
          for (final message in messages)
            message.id: _transaction(
              smsId: message.id,
              source: ParsedTransactionSource.bkash,
              kind: ParsedTransactionKind.payment,
              type: TransactionType.expense,
              amount: 100 + message.id.toDouble(),
              occurredAt: message.date,
            ),
        }),
        categoryMapper: const SmsCategoryMapper(),
        walletMatcher: const SmsWalletMatcher(),
      );

      final result = await service.syncLedger();

      expect(result.isInitialBackfill, isTrue);
      expect(result.batchCount, 2);
      expect(result.insertedEntries, 620);
      expect(await isar.smsLedgerEntryModels.count(), 620);

      final syncState = await isar.smsLedgerSyncStateModels.get(1);
      expect(syncState?.initialBackfillComplete, isTrue);
      expect(syncState?.lastSyncedSmsDate, messages.first.date);
    });

    test('incremental sync adds only newer SMS and avoids duplicates', () async {
      final initialMessages = [
        _sms(
          id: 1,
          address: 'bKash',
          body: 'Payment 1',
          date: DateTime(2026, 4, 20, 10),
        ),
        _sms(
          id: 2,
          address: 'Nagad',
          body: 'Payment 2',
          date: DateTime(2026, 4, 19, 11),
        ),
      ];
      final reader = _PagedFakeReader(initialMessages);
      final parser = _MappedParser({
        1: _transaction(
          smsId: 1,
          source: ParsedTransactionSource.bkash,
          kind: ParsedTransactionKind.payment,
          type: TransactionType.expense,
          amount: 450,
          occurredAt: initialMessages[0].date,
        ),
        2: _transaction(
          smsId: 2,
          source: ParsedTransactionSource.nagad,
          kind: ParsedTransactionKind.sendMoney,
          type: TransactionType.expense,
          amount: 700,
          occurredAt: initialMessages[1].date,
        ),
        3: _transaction(
          smsId: 3,
          source: ParsedTransactionSource.bank,
          kind: ParsedTransactionKind.bankCredit,
          type: TransactionType.income,
          amount: 42000,
          occurredAt: DateTime(2026, 4, 21, 9),
        ),
      });
      final service = SmsLedgerService(
        isar: isar,
        reader: reader,
        filter: const _PassThroughFilter(),
        parser: parser,
        categoryMapper: const SmsCategoryMapper(),
        walletMatcher: const SmsWalletMatcher(),
      );

      await service.syncLedger();
      reader.messages = [
        _sms(
          id: 3,
          address: 'Bank',
          body: 'Salary credit',
          date: DateTime(2026, 4, 21, 9),
        ),
        ...initialMessages,
      ];

      final result = await service.syncLedger();

      expect(result.isInitialBackfill, isFalse);
      expect(result.insertedEntries, 1);
      expect(await isar.smsLedgerEntryModels.count(), 3);
      final salaryEntry = await isar.smsLedgerEntryModels
          .filter()
          .smsIdEqualTo(3)
          .findFirst();
      expect(salaryEntry?.source, ParsedTransactionSource.bank);
    });

    test('overview excludes ignored rows and reflects imported rows', () async {
      final messages = [
        _sms(
          id: 11,
          address: 'bKash',
          body: 'Foodpanda payment',
          date: DateTime(2026, 4, 18, 13, 45),
        ),
        _sms(
          id: 12,
          address: 'BRACBANK',
          body: 'Salary credit',
          date: DateTime(2026, 4, 19, 9, 10),
        ),
        _sms(
          id: 13,
          address: 'Nagad',
          body: 'Send money',
          date: DateTime(2026, 4, 17, 8, 30),
        ),
      ];
      final service = SmsLedgerService(
        isar: isar,
        reader: _PagedFakeReader(messages),
        filter: const _PassThroughFilter(),
        parser: _MappedParser({
          11: _transaction(
            smsId: 11,
            source: ParsedTransactionSource.bkash,
            kind: ParsedTransactionKind.payment,
            type: TransactionType.expense,
            amount: 680,
            occurredAt: messages[0].date,
          ),
          12: _transaction(
            smsId: 12,
            source: ParsedTransactionSource.bank,
            kind: ParsedTransactionKind.bankCredit,
            type: TransactionType.income,
            amount: 42000,
            occurredAt: messages[1].date,
          ),
          13: _transaction(
            smsId: 13,
            source: ParsedTransactionSource.nagad,
            kind: ParsedTransactionKind.sendMoney,
            type: TransactionType.expense,
            amount: 500,
            occurredAt: messages[2].date,
          ),
        }),
        categoryMapper: const SmsCategoryMapper(),
        walletMatcher: const SmsWalletMatcher(),
      );

      await service.syncLedger();
      final salaryEntry = await isar.smsLedgerEntryModels
          .filter()
          .smsIdEqualTo(12)
          .findFirst();
      final sendMoneyEntry = await isar.smsLedgerEntryModels
          .filter()
          .smsIdEqualTo(13)
          .findFirst();

      expect(salaryEntry, isNotNull);
      expect(sendMoneyEntry, isNotNull);

      await service.markImportedBySignature(salaryEntry!.signature);
      await service.setIgnored(sendMoneyEntry!.id, true);

      final overview = await service.buildOverview(DateTime(2026, 4));

      expect(overview.totalEntries, 3);
      expect(overview.visibleEntries, 2);
      expect(overview.hiddenEntries, 1);
      expect(overview.importedEntries, 1);
      expect(overview.monthlyOutflow, 680);
      expect(overview.monthlyInflow, 42000);
      expect(overview.monthlyActivityTotal, 42680);
      expect(
        overview.kindTotals.map((item) => item.kind),
        containsAll([
          ParsedTransactionKind.payment,
          ParsedTransactionKind.bankCredit,
        ]),
      );
      expect(
        overview.kindTotals.map((item) => item.kind),
        isNot(contains(ParsedTransactionKind.sendMoney)),
      );
      expect(
        overview.sourceTotals.map((item) => item.source),
        containsAll([
          ParsedTransactionSource.bkash,
          ParsedTransactionSource.bank,
        ]),
      );
    });
  });
}

class _PagedFakeReader extends SmsReaderService {
  _PagedFakeReader(this.messages);

  List<SmsMessage> messages;

  @override
  Future<List<SmsMessage>> readSmsPage({
    int maxCount = 500,
    DateTime? since,
    DateTime? before,
    int? beforeMessageId,
  }) async {
    final sorted = [...messages]
      ..sort((first, second) {
        final dateComparison = second.date.compareTo(first.date);
        if (dateComparison != 0) {
          return dateComparison;
        }
        return second.id.compareTo(first.id);
      });

    return sorted.where((message) {
      if (since != null && message.date.isBefore(since)) {
        return false;
      }
      if (before == null) {
        return true;
      }
      if (message.date.isBefore(before)) {
        return true;
      }
      if (!message.date.isAtSameMomentAs(before)) {
        return false;
      }
      if (beforeMessageId == null) {
        return false;
      }
      return message.id < beforeMessageId;
    }).take(maxCount).toList(growable: false);
  }
}

class _PassThroughFilter extends SmsFilter {
  const _PassThroughFilter();

  @override
  List<SmsMessage> filterFinancialSms(List<SmsMessage> input) => input;
}

class _MappedParser extends SmsParserEngine {
  _MappedParser(this.transactions);

  final Map<int, ParsedTransaction> transactions;

  @override
  List<ParsedTransaction> parseAll(List<SmsMessage> messages) {
    return [
      for (final message in messages)
        if (transactions[message.id] != null) transactions[message.id]!,
    ];
  }
}

ParsedTransaction _transaction({
  required int smsId,
  required ParsedTransactionSource source,
  required ParsedTransactionKind kind,
  required TransactionType type,
  required double amount,
  required DateTime occurredAt,
}) {
  return ParsedTransaction(
    smsId: smsId,
    sender: source.label,
    source: source,
    direction: type == TransactionType.income
        ? ParsedTransactionDirection.credit
        : ParsedTransactionDirection.debit,
    kind: kind,
    amount: amount,
    rawMessage: 'Mock $smsId',
    receivedAt: occurredAt,
    occurredAt: occurredAt,
    counterparty: 'Counterparty $smsId',
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
