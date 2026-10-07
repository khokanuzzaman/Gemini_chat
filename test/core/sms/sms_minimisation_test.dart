// Store-prep: the SMS text is NOT stored. These tests pin the three things that
// could go wrong when it stopped being kept: (1) nothing sentence-like reaches
// disk, (2) suggestions are the same without it, (3) duplicate detection survives
// — including for rows that were written before the change.

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/imported_sms_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_entry_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_sync_state_model.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/sms/sms_body_minimiser.dart';
import 'package:gemini_chat/core/sms/sms_category_mapper.dart';
import 'package:gemini_chat/core/sms/sms_filter.dart';
import 'package:gemini_chat/core/sms/sms_ledger_service.dart';
import 'package:gemini_chat/core/sms/sms_match_hints.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';
import 'package:gemini_chat/core/sms/sms_parser.dart';
import 'package:gemini_chat/core/sms/sms_reader_service.dart';
import 'package:gemini_chat/core/sms/sms_signature_codec.dart';
import 'package:gemini_chat/core/sms/sms_wallet_matcher.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';

const _bracBody =
    'BRAC Bank: Salary credit of BDT 65,000.00 from Acme Technologies Ltd to A/C '
    '1234567890 on 05-Oct-26. Balance BDT 71,250.40. Ref SAL998877.';
const _foodBody =
    'bKash: You have paid Tk 450.00 to Foodpanda restaurant. Fee Tk 0.00. '
    'Balance Tk 1,450.00. TrxID 8KD3JD92 at 05/10/2026 13:05';

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

  group('SmsMatchHints', () {
    test('keeps only known matcher words — no sentence, number or name', () {
      final hints = SmsMatchHints.extract(_bracBody);
      expect(hints, isNotEmpty);
      final vocabulary = {
        for (final words in SmsWalletMatcher.bankKeywordMap.values) ...words,
        for (final words in SmsCategoryMapper.expenseKeywordMap.values)
          ...words,
        ...SmsCategoryMapper.salaryKeywords,
        ...SmsCategoryMapper.freelanceKeywords,
        ...SmsCategoryMapper.companyMarkers,
      }.map((w) => w.toLowerCase()).toSet();
      for (final word in hints.split(SmsMatchHints.separator)) {
        expect(vocabulary, contains(word));
      }
      // None of the sensitive specifics survive.
      for (final secret in ['1234567890', '71,250', 'SAL998877', 'Acme']) {
        expect(hints.toLowerCase().contains(secret.toLowerCase()), isFalse);
      }
    });

    test('empty / unknown text -> empty hints', () {
      expect(SmsMatchHints.extract(''), '');
      expect(SmsMatchHints.extract('zzz qqq 123'), '');
    });

    test('custom category names are hinted too', () {
      expect(
        SmsMatchHints.extract(
          'payment at My Gym today',
          customCategoryNames: const ['My Gym'],
        ),
        'my gym',
      );
    });

    test('suggestions are IDENTICAL with the hints instead of the body', () {
      const mapper = SmsCategoryMapper();
      const matcher = SmsWalletMatcher();
      final wallets = [
        _wallet(1, 'নগদ টাকা', WalletType.cash),
        _wallet(2, 'BRAC Bank', WalletType.bank),
        _wallet(3, 'City Bank', WalletType.bank),
      ];
      final bodies = [
        _bracBody,
        _foodBody,
        'CITY BANK: Debited BDT 2,200 at Daraz shopping on 04-Oct',
        'Upwork payout received Tk 12000 from freelance project payment',
        'Payment of Tk 600 to Uber ride, balance Tk 900',
        'EBL: Received Tk 5000 from Rahim Software Solutions',
        'udemy course purchase Tk 1,500 charged to card',
        'hospital bill Tk 3,000 paid, pharmacy included',
        'এই মাসের বেতন জমা হয়েছে ৫০০০০ টাকা',
        'completely generic message with nothing known 4500',
      ];
      for (final body in bodies) {
        for (final type in [TransactionType.expense, TransactionType.income]) {
          final withBody = _tx(body, type);
          final withHints = _tx(SmsMatchHints.extract(body), type);
          expect(
            mapper.mapToExpenseCategory(withHints),
            mapper.mapToExpenseCategory(withBody),
            reason: 'expense category for: $body',
          );
          expect(
            mapper.mapToIncomeSource(withHints),
            mapper.mapToIncomeSource(withBody),
            reason: 'income source for: $body',
          );
          expect(
            matcher.matchWallet(withHints, wallets)?.id,
            matcher.matchWallet(withBody, wallets)?.id,
            reason: 'wallet for: $body',
          );
        }
      }
    });
  });

  group('ledger', () {
    late Directory tempDir;
    late Isar isar;
    late SharedPreferences prefs;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-min-');
      isar = await Isar.open(
        [
          ImportedSmsModelSchema,
          SmsLedgerEntryModelSchema,
          SmsLedgerSyncStateModelSchema,
        ],
        directory: tempDir.path,
        name: 'sms_min_${DateTime.now().microsecondsSinceEpoch}',
      );
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final messages = [
      SmsMessage(
        id: 1,
        address: 'BRAC BANK',
        body: _bracBody,
        date: DateTime(2026, 10, 5, 9),
      ),
      SmsMessage(
        id: 2,
        address: 'bKash',
        body: _foodBody,
        date: DateTime(2026, 10, 5, 13),
      ),
    ];

    SmsLedgerService service(List<SmsMessage> inbox) => SmsLedgerService(
      isar: isar,
      reader: _Reader(inbox),
      filter: const _PassThrough(),
      parser: _Parser({
        1: _parsed(
          1,
          ParsedTransactionSource.bank,
          TransactionType.income,
          65000,
          messages[0].date,
          ref: 'SAL998877',
          balance: 71250.40,
          mask: '••7890',
        ),
        2: _parsed(
          2,
          ParsedTransactionSource.bkash,
          TransactionType.expense,
          450,
          messages[1].date,
          ref: '8KD3JD92',
        ),
      }),
      categoryMapper: const SmsCategoryMapper(),
      walletMatcher: const SmsWalletMatcher(),
    );

    test(
      'a sync stores NO message text — only parsed fields + hints',
      () async {
        await service(messages).syncLedger();

        final rows = await isar.smsLedgerEntryModels.where().findAll();
        expect(rows, hasLength(2));
        for (final row in rows) {
          expect(row.rawMessage, '');
          expect(row.matchHints, isNotNull);
          expect(row.toSmsMessage().body, '');
        }
        final brac = rows.firstWhere((r) => r.smsId == 1);
        expect(brac.amount, 65000);
        expect(brac.reference, 'SAL998877');
        expect(brac.sender, 'BRAC BANK');
        expect(brac.matchHints, contains('salary'));
        expect(brac.matchHints, isNot(contains('1234567890')));
      },
    );

    test('a sync stores NO balance, but keeps the account mask', () async {
      await service(messages).syncLedger();
      final brac = (await isar.smsLedgerEntryModels.where().findAll())
          .firstWhere((r) => r.smsId == 1);
      expect(brac.balanceAfter, isNull, reason: 'parsed 71,250.40, not stored');
      expect(brac.accountMask, '••7890', reason: 'wallet matching needs it');
      expect(brac.toParsedTransaction().balanceAfter, isNull);
    });

    test('DEDUPE: syncing the same inbox again adds nothing', () async {
      final first = await service(messages).syncLedger();
      expect(first.insertedEntries, 2);
      final second = await service(messages).syncLedger();
      expect(second.insertedEntries, 0);
      expect(await isar.smsLedgerEntryModels.count(), 2);
    });

    test(
      'DEDUPE: rows written BEFORE the change, minimised, are not duplicated',
      () async {
        final codec = const SmsSignatureCodec();
        // A row exactly as the previous version wrote it: full text, already imported.
        await isar.writeTxn(() async {
          await isar.smsLedgerEntryModels.put(
            SmsLedgerEntryModel()
              ..signature = codec.generateSignature(messages[0])
              ..smsId = 1
              ..sender = 'BRAC BANK'
              ..rawMessage = _bracBody
              ..source = ParsedTransactionSource.bank
              ..direction = ParsedTransactionDirection.credit
              ..kind = ParsedTransactionKind.bankCredit
              ..type = TransactionType.income
              ..amount = 65000
              ..reference = 'SAL998877'
              ..confidence = 1
              ..occurredAt = messages[0].date
              ..receivedAt = messages[0].date
              ..isImported = true
              ..importedAt = DateTime(2026, 10, 6)
              ..createdAt = DateTime(2026, 10, 5)
              ..updatedAt = DateTime(2026, 10, 5),
          );
        });

        final stripped = await SmsBodyMinimiser.run(isar, prefs);
        expect(stripped, 1);

        final before =
            (await isar.smsLedgerEntryModels.where().findAll()).single;
        expect(before.rawMessage, '');
        expect(
          before.matchHints,
          contains('salary'),
        ); // derived BEFORE blanking
        expect(before.signature, codec.generateSignature(messages[0]));
        expect(before.isImported, isTrue);

        // The inbox still holds the real message; a sync must recognise it.
        final result = await service([messages[0]]).syncLedger();
        expect(result.insertedEntries, 0, reason: 'recognised, not re-added');
        expect(result.updatedEntries, 1);
        final rows = await isar.smsLedgerEntryModels.where().findAll();
        expect(rows, hasLength(1));
        expect(
          rows.single.isImported,
          isTrue,
          reason: 'imported state survives',
        );
        expect(rows.single.importedAt, DateTime(2026, 10, 6));
        expect(rows.single.rawMessage, '');
      },
    );

    test(
      'confirming an import from a stripped row does NOT create a second row',
      () async {
        final svc = service(messages);
        await svc.syncLedger();
        final entry = (await isar.smsLedgerEntryModels.where().findAll())
            .firstWhere((r) => r.smsId == 2);
        final candidate = svc.buildImportCandidate(entry, const []);

        expect(
          candidate.sms.body,
          '',
          reason: 'no text is kept to rebuild from',
        );
        expect(candidate.signature, entry.signature);

        await svc.upsertCandidate(
          candidate,
          isImported: true,
          importedAt: DateTime(2026, 10, 7),
        );

        final rows = await isar.smsLedgerEntryModels.where().findAll();
        expect(rows, hasLength(2), reason: 'same row updated in place');
        final after = rows.firstWhere((r) => r.smsId == 2);
        expect(after.id, entry.id);
        expect(after.isImported, isTrue);
        expect(after.rawMessage, '');
        expect(after.matchHints, entry.matchHints, reason: 'hints are kept');
      },
    );

    test('the OLD behaviour would have duplicated (guard the guard)', () async {
      // Hashing the (blank) text of a stripped candidate gives a DIFFERENT
      // signature — which is exactly why candidates now carry the row's own.
      final codec = const SmsSignatureCodec();
      final live = codec.generateSignature(messages[1]);
      final blank = codec.generateSignature(messages[1].copyWith(body: ''));
      expect(blank, isNot(live));
    });

    group('SmsBodyMinimiser', () {
      Future<void> seed(int n) => isar.writeTxn(() async {
        for (var i = 1; i <= n; i++) {
          await isar.smsLedgerEntryModels.put(
            SmsLedgerEntryModel()
              ..signature = 'sig-$i'
              ..smsId = i
              ..sender = 'bKash'
              ..rawMessage = i.isEven ? _foodBody : _bracBody
              ..source = ParsedTransactionSource.bkash
              ..direction = ParsedTransactionDirection.debit
              ..kind = ParsedTransactionKind.payment
              ..type = TransactionType.expense
              ..amount = 100.0 + i
              ..confidence = 1
              ..occurredAt = DateTime(2026, 10, 1)
              ..receivedAt = DateTime(2026, 10, 1)
              ..createdAt = DateTime(2026, 10, 1)
              ..updatedAt = DateTime(2026, 10, 1),
          );
        }
      });

      test(
        'strips every row (across batches), keeps everything else',
        () async {
          await seed(450); // > 2 batches of 200
          final stripped = await SmsBodyMinimiser.run(isar, prefs);
          expect(stripped, 450);

          final rows = await isar.smsLedgerEntryModels.where().findAll();
          expect(rows, hasLength(450));
          expect(rows.every((r) => r.rawMessage.isEmpty), isTrue);
          expect(rows.every((r) => r.matchHints != null), isTrue);
          expect(rows.map((r) => r.signature).toSet(), hasLength(450));
          expect(rows.firstWhere((r) => r.smsId == 7).amount, 107);
        },
      );

      test(
        'strips the stored balance too — keeps mask, hints and everything else',
        () async {
          await isar.writeTxn(() async {
            await isar.smsLedgerEntryModels.put(
              SmsLedgerEntryModel()
                ..signature = 'sig-bal'
                ..smsId = 9
                ..sender = 'BRAC BANK'
                ..rawMessage =
                    '' // text already gone (an upgraded v1 device)
                ..matchHints = 'brac bank | salary'
                ..source = ParsedTransactionSource.bank
                ..direction = ParsedTransactionDirection.credit
                ..kind = ParsedTransactionKind.bankCredit
                ..type = TransactionType.income
                ..amount = 65000
                ..balanceAfter = 71250.40
                ..accountMask = '••7890'
                ..reference = 'R1'
                ..confidence = 1
                ..isImported = true
                ..occurredAt = DateTime(2026, 10, 1)
                ..receivedAt = DateTime(2026, 10, 1)
                ..createdAt = DateTime(2026, 10, 1)
                ..updatedAt = DateTime(2026, 10, 1),
            );
          });
          // A v1 device: the previous flag is set, the v2 one is not.
          await prefs.setBool('sms_bodies_stripped_v1', true);

          expect(await SmsBodyMinimiser.run(isar, prefs), 1);

          final row =
              (await isar.smsLedgerEntryModels.where().findAll()).single;
          expect(row.balanceAfter, isNull);
          expect(row.accountMask, '••7890');
          expect(
            row.matchHints,
            'brac bank | salary',
            reason: 'not recomputed from nothing',
          );
          expect(row.amount, 65000);
          expect(row.reference, 'R1');
          expect(row.isImported, isTrue);
          expect(row.signature, 'sig-bal');
        },
      );

      test('runs once: flag set, second run touches nothing', () async {
        await seed(3);
        expect(await SmsBodyMinimiser.run(isar, prefs), 3);
        expect(prefs.getBool(SmsBodyMinimiser.doneKey), isTrue);
        expect(await SmsBodyMinimiser.run(isar, prefs), 0);
      });

      test(
        'safe without the flag too (idempotent: nothing left to strip)',
        () async {
          await seed(2);
          await SmsBodyMinimiser.run(isar, prefs);
          await prefs.remove(SmsBodyMinimiser.doneKey);
          expect(await SmsBodyMinimiser.run(isar, prefs), 0);
        },
      );

      test('an empty database is fine', () async {
        expect(await SmsBodyMinimiser.run(isar, prefs), 0);
        expect(prefs.getBool(SmsBodyMinimiser.doneKey), isTrue);
      });
    });
  });
}

WalletEntity _wallet(int id, String name, WalletType type) => WalletEntity(
  id: id,
  name: name,
  type: type,
  emoji: '💵',
  initialBalance: 0,
  currentBalance: 0,
  accountNumber: null,
  note: null,
  sortOrder: id,
  isArchived: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

ParsedTransaction _tx(String rawMessage, TransactionType type) =>
    ParsedTransaction(
      smsId: 1,
      sender: 'sender',
      source: ParsedTransactionSource.bank,
      direction: type == TransactionType.income
          ? ParsedTransactionDirection.credit
          : ParsedTransactionDirection.debit,
      kind: type == TransactionType.income
          ? ParsedTransactionKind.bankCredit
          : ParsedTransactionKind.payment,
      amount: 100,
      rawMessage: rawMessage,
      receivedAt: DateTime(2026, 10, 5),
      occurredAt: DateTime(2026, 10, 5),
    );

ParsedTransaction _parsed(
  int smsId,
  ParsedTransactionSource source,
  TransactionType type,
  double amount,
  DateTime at, {
  String? ref,
  double? balance,
  String? mask,
}) => ParsedTransaction(
  smsId: smsId,
  sender: source.label,
  source: source,
  direction: type == TransactionType.income
      ? ParsedTransactionDirection.credit
      : ParsedTransactionDirection.debit,
  kind: type == TransactionType.income
      ? ParsedTransactionKind.bankCredit
      : ParsedTransactionKind.payment,
  amount: amount,
  rawMessage: 'ignored — the ledger must not persist this',
  receivedAt: at,
  occurredAt: at,
  reference: ref,
  balanceAfter: balance,
  accountMask: mask,
);

class _Reader extends SmsReaderService {
  _Reader(this.messages);
  final List<SmsMessage> messages;

  @override
  Future<List<SmsMessage>> readSmsPage({
    int maxCount = 500,
    DateTime? since,
    DateTime? before,
    int? beforeMessageId,
  }) async {
    final sorted = [...messages]..sort((a, b) => b.date.compareTo(a.date));
    return sorted
        .where((m) => since == null || !m.date.isBefore(since))
        .where((m) => before == null || m.date.isBefore(before))
        .take(maxCount)
        .toList(growable: false);
  }
}

class _PassThrough extends SmsFilter {
  const _PassThrough();
  @override
  List<SmsMessage> filterFinancialSms(List<SmsMessage> input) => input;
}

class _Parser extends SmsParserEngine {
  _Parser(this.byId);
  final Map<int, ParsedTransaction> byId;
  @override
  List<ParsedTransaction> parseAll(List<SmsMessage> messages) => [
    for (final m in messages)
      if (byId[m.id] != null) byId[m.id]!,
  ];
}
