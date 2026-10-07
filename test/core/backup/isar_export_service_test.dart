import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/backup/isar_export_service.dart';
import 'package:gemini_chat/core/database/models/budget_plan_model.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/goal_model.dart';
import 'package:gemini_chat/core/database/models/goal_saving_model.dart';
import 'package:gemini_chat/core/database/models/imported_sms_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/database/models/recurring_expense_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_entry_model.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_sync_state_model.dart';
import 'package:gemini_chat/core/database/models/split_bill_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/features/category/data/models/category_model.dart';
import 'package:gemini_chat/features/chat/data/models/message_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/net_worth/data/models/net_worth_snapshot_model.dart';
import 'package:gemini_chat/features/prediction/data/models/prediction_cache_model.dart';

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

  group('IsarExportService', () {
    late Directory sourceDir;
    late Directory targetDir;
    late Isar sourceIsar;
    late Isar targetIsar;
    late IsarExportService service;

    setUp(() async {
      sourceDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-backup-source-',
      );
      targetDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-backup-target-',
      );
      sourceIsar = await _openIsar(sourceDir, 'backup_source');
      targetIsar = await _openIsar(targetDir, 'backup_target');
      service = IsarExportService();
    });

    tearDown(() async {
      await sourceIsar.close(deleteFromDisk: true);
      await targetIsar.close(deleteFromDisk: true);
      if (await sourceDir.exists()) {
        await sourceDir.delete(recursive: true);
      }
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }
    });

    test(
      'a backup contains NO SMS text, even if a row still has some',
      () async {
        await sourceIsar.writeTxn(() async {
          await sourceIsar.smsLedgerEntryModels.put(
            _ledgerEntry(
              rawMessage: 'BRAC Bank salary credit BDT 65,000 A/C 1234',
            ),
          );
        });

        final exported = await service.exportAll(sourceIsar);
        final json = jsonEncode(exported);

        expect(json.contains('BRAC Bank salary credit'), isFalse);
        expect(json.contains('A/C 1234'), isFalse);
        final row =
            ((exported['collections'] as Map)['smsLedgerEntries'] as List)
                    .single
                as Map;
        expect(row['rawMessage'], '');
        expect(row['amount'], 65000); // the parsed fields are all still there
        expect(row['reference'], 'SAL1');
      },
    );

    test('restoring a pre-change backup keeps hints, never the text', () async {
      final legacy = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime(2026, 10, 1).toUtc().toIso8601String(),
        'collections': <String, dynamic>{
          'smsLedgerEntries': [
            {
              'id': 5,
              'signature': 'sig-legacy',
              'smsId': 55,
              'sender': 'BRAC BANK',
              'rawMessage': 'BRAC Bank salary credit BDT 65,000 A/C 1234',
              'source': 'bank',
              'direction': 'credit',
              'kind': 'bankCredit',
              'type': 'income',
              'amount': 65000.0,
              'confidence': 1.0,
              'occurredAt': DateTime(2026, 10, 5).toUtc().toIso8601String(),
              'receivedAt': DateTime(2026, 10, 5).toUtc().toIso8601String(),
              'isImported': true,
              'isIgnored': false,
              'createdAt': DateTime(2026, 10, 5).toUtc().toIso8601String(),
              'updatedAt': DateTime(2026, 10, 5).toUtc().toIso8601String(),
            },
          ],
        },
      };

      await service.importAll(targetIsar, legacy);

      final restored =
          (await targetIsar.smsLedgerEntryModels.where().findAll()).single;
      expect(restored.rawMessage, '');
      expect(restored.matchHints, contains('salary'));
      expect(restored.signature, 'sig-legacy'); // dedupe key intact
      expect(restored.isImported, isTrue);
    });

    test(
      'round-trips goal savings, prediction cache, and sms ledger collections',
      () async {
        final localDate = DateTime(2026, 4, 29, 0, 15);
        await sourceIsar.writeTxn(() async {
          final expense = ExpenseRecordModel()
            ..id = 11
            ..amount = 320
            ..category = 'Food'
            ..description = 'late dinner'
            ..walletId = 1
            ..isManual = true
            ..date = localDate;
          await sourceIsar.expenseRecordModels.put(expense);

          final goalSaving = GoalSavingModel()
            ..id = 7
            ..goalId = 77
            ..amount = 1200
            ..date = localDate
            ..note = 'মাসিক জমা';
          await sourceIsar.goalSavingModels.put(goalSaving);

          final ledgerEntry = SmsLedgerEntryModel()
            ..id = 21
            ..signature = 'sms-signature-21'
            ..smsId = 2101
            ..sender = 'bKash'
            ..rawMessage = 'Payment to Foodpanda'
            ..source = ParsedTransactionSource.bkash
            ..direction = ParsedTransactionDirection.debit
            ..kind = ParsedTransactionKind.payment
            ..type = TransactionType.expense
            ..amount = 550
            ..fee = 0
            ..balanceAfter = 1450
            ..reference = 'ABC123'
            ..counterparty = 'Foodpanda'
            ..merchantName = 'Foodpanda'
            ..accountMask = '1234'
            ..rawCategory = 'food'
            ..confidence = 0.92
            ..occurredAt = localDate
            ..receivedAt = localDate.add(const Duration(minutes: 2))
            ..isImported = true
            ..importedAt = localDate.add(const Duration(minutes: 5))
            ..isIgnored = false
            ..ignoredAt = null
            ..createdAt = localDate
            ..updatedAt = localDate.add(const Duration(minutes: 5));
          await sourceIsar.smsLedgerEntryModels.put(ledgerEntry);

          final syncState = SmsLedgerSyncStateModel()
            ..id = 1
            ..initialBackfillComplete = true
            ..lastSuccessfulSyncAt = localDate.add(const Duration(hours: 1))
            ..lastSyncedSmsDate = localDate.add(const Duration(minutes: 2))
            ..lastSyncedSmsId = 2101
            ..createdAt = localDate
            ..updatedAt = localDate.add(const Duration(hours: 1));
          await sourceIsar.smsLedgerSyncStateModels.put(syncState);

          final predictionCache = PredictionCacheModel()
            ..id = 1
            ..predictedTotal = 20000
            ..currentTotal = 9000
            ..lastMonthTotal = 15000
            ..dailyAverage = 450
            ..projectedDailyAverage = 666
            ..trend = 'up'
            ..confidence = 'high'
            ..categoryPredictionsJson = '{"Food": 3500}'
            ..aiInsight = 'খরচ বাড়ছে'
            ..generatedAt = localDate
            ..currentDay = 14
            ..daysInMonth = 30
            ..daysRemaining = 16;
          await sourceIsar.predictionCacheModels.put(predictionCache);
        });

        final exported = await service.exportAll(sourceIsar);
        final collections = exported['collections']! as Map<String, dynamic>;

        expect(collections['goalSavings'], isNotEmpty);
        expect(collections['smsLedgerEntries'], isNotEmpty);
        expect(collections['smsLedgerSyncStates'], isNotEmpty);
        expect(collections['predictionCaches'], isNotEmpty);

        await service.importAll(targetIsar, exported);

        final restoredExpense = await targetIsar.expenseRecordModels.get(11);
        expect(restoredExpense, isNotNull);
        expect(restoredExpense!.date.isUtc, isFalse);
        expect(restoredExpense.date.year, localDate.year);
        expect(restoredExpense.date.month, localDate.month);
        expect(restoredExpense.date.day, localDate.day);
        expect(restoredExpense.date.hour, localDate.hour);
        expect(restoredExpense.date.minute, localDate.minute);

        final restoredGoalSaving = await targetIsar.goalSavingModels.get(7);
        expect(restoredGoalSaving, isNotNull);
        expect(restoredGoalSaving!.goalId, 77);
        expect(restoredGoalSaving.note, 'মাসিক জমা');
        expect(restoredGoalSaving.date.isUtc, isFalse);
        expect(restoredGoalSaving.date.hour, localDate.hour);
        expect(restoredGoalSaving.date.minute, localDate.minute);

        final restoredLedgerEntry = await targetIsar.smsLedgerEntryModels.get(
          21,
        );
        expect(restoredLedgerEntry, isNotNull);
        expect(restoredLedgerEntry!.source, ParsedTransactionSource.bkash);
        expect(restoredLedgerEntry.kind, ParsedTransactionKind.payment);
        expect(restoredLedgerEntry.isImported, isTrue);
        expect(restoredLedgerEntry.counterparty, 'Foodpanda');
        expect(restoredLedgerEntry.occurredAt.isUtc, isFalse);
        expect(restoredLedgerEntry.occurredAt.hour, localDate.hour);
        expect(restoredLedgerEntry.importedAt, isNotNull);

        final restoredSyncState = await targetIsar.smsLedgerSyncStateModels.get(
          1,
        );
        expect(restoredSyncState, isNotNull);
        expect(restoredSyncState!.initialBackfillComplete, isTrue);
        expect(restoredSyncState.lastSyncedSmsId, 2101);

        final restoredPrediction = await targetIsar.predictionCacheModels.get(
          1,
        );
        expect(restoredPrediction, isNotNull);
        expect(restoredPrediction!.aiInsight, 'খরচ বাড়ছে');
        expect(restoredPrediction.generatedAt.isUtc, isFalse);
      },
    );
  });
}

Future<Isar> _openIsar(Directory directory, String name) {
  return Isar.open(
    [
      MessageModelSchema,
      ExpenseRecordModelSchema,
      CategoryModelSchema,
      BudgetPlanModelSchema,
      GoalModelSchema,
      GoalSavingModelSchema,
      RecurringExpenseModelSchema,
      SplitBillModelSchema,
      WalletModelSchema,
      ImportedSmsModelSchema,
      SmsLedgerEntryModelSchema,
      SmsLedgerSyncStateModelSchema,
      PredictionCacheModelSchema,
      IncomeRecordModelSchema,
      DebtModelSchema,
      DebtPaymentModelSchema,
      NetWorthSnapshotModelSchema,
    ],
    directory: directory.path,
    name: '${name}_${DateTime.now().microsecondsSinceEpoch}',
  );
}

SmsLedgerEntryModel _ledgerEntry({required String rawMessage}) {
  final at = DateTime(2026, 10, 5, 9);
  return SmsLedgerEntryModel()
    ..id = 1
    ..signature = 'sig-1'
    ..smsId = 1
    ..sender = 'BRAC BANK'
    ..rawMessage = rawMessage
    ..source = ParsedTransactionSource.bank
    ..direction = ParsedTransactionDirection.credit
    ..kind = ParsedTransactionKind.bankCredit
    ..type = TransactionType.income
    ..amount = 65000
    ..reference = 'SAL1'
    ..confidence = 1
    ..occurredAt = at
    ..receivedAt = at
    ..createdAt = at
    ..updatedAt = at;
}
