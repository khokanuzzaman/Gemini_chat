import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/backup/backup_encryption_service.dart';
import 'package:gemini_chat/core/backup/backup_models.dart';
import 'package:gemini_chat/core/backup/backup_orchestrator.dart';
import 'package:gemini_chat/core/backup/backup_progress.dart';
import 'package:gemini_chat/core/backup/drive_backup_service.dart';
import 'package:gemini_chat/core/backup/google_auth_service.dart';
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

  group('BackupOrchestrator', () {
    late Directory tempDir;
    late Isar isar;
    late _FakeGoogleAuthService authService;
    late _MemoryDriveBackupService driveService;
    late BackupOrchestrator orchestrator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'pocketpilot-ai-backup-orchestrator-',
      );
      isar = await _openIsar(tempDir, 'backup_orchestrator');
      authService = _FakeGoogleAuthService();
      driveService = _MemoryDriveBackupService();
      orchestrator = BackupOrchestrator(
        exportService: IsarExportService(),
        encryptionService: BackupEncryptionService(),
        driveService: driveService,
        authService: authService,
        isar: isar,
      );
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'createBackup uploads encrypted data and restoreBackup restores it',
      () async {
        final now = DateTime(2026, 4, 29, 9, 30);
        final backupProgress = <BackupProgressState>[];
        final restoreProgress = <BackupProgressState>[];
        await isar.writeTxn(() async {
          final expense = ExpenseRecordModel()
            ..id = 101
            ..amount = 880
            ..category = 'Food'
            ..description = 'backup proof expense'
            ..walletId = 1
            ..isManual = true
            ..date = now;
          await isar.expenseRecordModels.put(expense);

          final message = MessageModel()
            ..id = 55
            ..text = 'backup proof message'
            ..isUser = true
            ..isReceipt = false
            ..isVoice = false
            ..usedRagContext = false
            ..isRag = false
            ..ragType = null
            ..isError = false
            ..promptTokenCount = 10
            ..outputTokenCount = 5
            ..totalTokenCount = 15
            ..createdAt = now;
          await isar.messageModels.put(message);

          final ledgerEntry = SmsLedgerEntryModel()
            ..id = 9
            ..signature = 'proof-ledger-signature'
            ..smsId = 9001
            ..sender = 'bKash'
            ..rawMessage = 'Payment of 880'
            ..source = ParsedTransactionSource.bkash
            ..direction = ParsedTransactionDirection.debit
            ..kind = ParsedTransactionKind.payment
            ..type = TransactionType.expense
            ..amount = 880
            ..counterparty = 'Foodpanda'
            ..merchantName = 'Foodpanda'
            ..confidence = 0.98
            ..occurredAt = now
            ..receivedAt = now.add(const Duration(minutes: 1))
            ..isImported = false
            ..isIgnored = false
            ..createdAt = now
            ..updatedAt = now.add(const Duration(minutes: 1));
          await isar.smsLedgerEntryModels.put(ledgerEntry);
        });

        final backupResult = await orchestrator.createBackup(
          onProgress: backupProgress.add,
        );

        expect(backupResult.success, isTrue);
        expect(driveService.latestBytes, isNotNull);
        expect(driveService.latestBytes, isNotEmpty);
        expect(
          String.fromCharCodes(driveService.latestBytes!),
          isNot(contains('backup proof expense')),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt(BackupOrchestrator.backupLastTimeKey),
          backupResult.timestamp?.millisecondsSinceEpoch,
        );
        expect(
          prefs.getInt(BackupOrchestrator.backupLastSizeKey),
          backupResult.sizeBytes,
        );
        expect(_stageSequence(backupProgress), [
          BackupProgressStage.preparing,
          BackupProgressStage.exporting,
          BackupProgressStage.compressing,
          BackupProgressStage.encrypting,
          BackupProgressStage.uploading,
          BackupProgressStage.finalizing,
          BackupProgressStage.completed,
        ]);
        final uploadEvents = backupProgress
            .where((event) => event.stage == BackupProgressStage.uploading)
            .toList(growable: false);
        expect(uploadEvents, isNotEmpty);
        expect(uploadEvents.first.processedBytes, 0);
        expect(uploadEvents.last.processedBytes, uploadEvents.last.totalBytes);

        await isar.writeTxn(() async {
          await isar.expenseRecordModels.clear();
          await isar.messageModels.clear();
          await isar.smsLedgerEntryModels.clear();
        });
        expect(await isar.expenseRecordModels.count(), 0);
        expect(await isar.messageModels.count(), 0);
        expect(await isar.smsLedgerEntryModels.count(), 0);

        final restoreResult = await orchestrator.restoreBackup(
          onProgress: restoreProgress.add,
        );

        expect(restoreResult.success, isTrue);
        final restoredExpense = await isar.expenseRecordModels.get(101);
        expect(restoredExpense, isNotNull);
        expect(restoredExpense!.description, 'backup proof expense');
        expect(restoredExpense.date.isUtc, isFalse);

        final restoredMessage = await isar.messageModels.get(55);
        expect(restoredMessage, isNotNull);
        expect(restoredMessage!.text, 'backup proof message');

        final restoredLedger = await isar.smsLedgerEntryModels.get(9);
        expect(restoredLedger, isNotNull);
        expect(restoredLedger!.counterparty, 'Foodpanda');
        expect(restoredLedger.source, ParsedTransactionSource.bkash);
        expect(_stageSequence(restoreProgress), [
          BackupProgressStage.preparing,
          BackupProgressStage.downloading,
          BackupProgressStage.decrypting,
          BackupProgressStage.decoding,
          BackupProgressStage.importing,
          BackupProgressStage.finalizing,
          BackupProgressStage.completed,
        ]);
        final downloadEvents = restoreProgress
            .where((event) => event.stage == BackupProgressStage.downloading)
            .toList(growable: false);
        expect(downloadEvents, isNotEmpty);
        expect(
          downloadEvents.last.processedBytes,
          downloadEvents.last.totalBytes,
        );
      },
    );
  });
}

class _FakeGoogleAuthService implements GoogleAuthService {
  @override
  String? get displayName => 'Backup Test User';

  @override
  Future<http.Client?> getDriveHttpClient() async => null;

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<bool> signIn() async => true;

  @override
  Future<void> signInSilently() async {}

  @override
  Future<void> signOut() async {}

  @override
  String? get userEmail => 'backup-test@example.com';

  @override
  String? get userId => 'backup-user-1';
}

class _MemoryDriveBackupService implements DriveBackupService {
  Uint8List? latestBytes;
  BackupFileInfo? latestInfo;

  @override
  Future<void> deleteAllBackups() async {
    latestBytes = null;
    latestInfo = null;
  }

  @override
  Future<Uint8List?> downloadLatestBackup({
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final data = latestBytes;
    if (data == null) {
      return null;
    }
    final halfway = data.length ~/ 2;
    onProgress?.call(halfway, data.length);
    onProgress?.call(data.length, data.length);
    return data;
  }

  @override
  Future<BackupFileInfo?> getLatestBackupInfo() async => latestInfo;

  @override
  Future<List<BackupFileInfo>> listAllBackups() async {
    if (latestInfo == null) {
      return const [];
    }
    return [latestInfo!];
  }

  @override
  Future<BackupUploadResult> uploadBackup(
    Uint8List data, {
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final halfway = data.length ~/ 2;
    onProgress?.call(halfway, data.length);
    onProgress?.call(data.length, data.length);
    latestBytes = Uint8List.fromList(data);
    final uploadedAt = DateTime(2026, 4, 29, 10, 0);
    latestInfo = BackupFileInfo(
      fileId: 'memory-backup-file',
      name: 'backup_latest.enc',
      sizeBytes: data.length,
      modifiedAt: uploadedAt,
    );
    return BackupUploadResult(
      fileId: 'memory-backup-file',
      sizeBytes: data.length,
      uploadedAt: uploadedAt,
    );
  }
}

List<BackupProgressStage> _stageSequence(List<BackupProgressState> events) {
  final stages = <BackupProgressStage>[];
  for (final event in events) {
    if (stages.isEmpty || stages.last != event.stage) {
      stages.add(event.stage);
    }
  }
  return stages;
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
    ],
    directory: directory.path,
    name: '${name}_${DateTime.now().microsecondsSinceEpoch}',
  );
}
