import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/backup/auto_backup_coordinator.dart';
import 'package:gemini_chat/core/backup/backup_reminder_provider.dart';
import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/goal_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';

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

  late Directory dir;
  late Isar isar;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pocketpilot-reminder-');
    isar = await Isar.open(
      [
        ExpenseRecordModelSchema,
        IncomeRecordModelSchema,
        DebtModelSchema,
        GoalModelSchema,
      ],
      directory: dir.path,
      name: 'reminder_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  Future<void> addExpenses(int count) {
    return isar.writeTxn(() async {
      for (var i = 0; i < count; i++) {
        await isar.expenseRecordModels.put(
          ExpenseRecordModel()
            ..amount = 10
            ..category = 'Food'
            ..description = 'x'
            ..walletId = 1
            ..isManual = true
            ..date = DateTime(2026, 9, 1),
        );
      }
    });
  }

  Future<ProviderContainer> container(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  final longAgo = DateTime.now()
      .subtract(const Duration(days: 40))
      .millisecondsSinceEpoch;

  test('data + 40 days since first seen + never backed up -> shown', () async {
    await addExpenses(12);
    final c = await container({AutoBackupKeys.firstSeenAt: longAgo});
    final decision = await c.read(backupReminderProvider.future);
    expect(decision, isNotNull);
    expect(decision!.daysSinceBackup, isNull);
  });

  test('too little data -> nothing', () async {
    await addExpenses(3);
    final c = await container({AutoBackupKeys.firstSeenAt: longAgo});
    expect(await c.read(backupReminderProvider.future), isNull);
  });

  test('a recent successful backup -> nothing', () async {
    await addExpenses(40);
    final c = await container({
      AutoBackupKeys.firstSeenAt: longAgo,
      AutoBackupKeys.lastSuccessAt: DateTime.now()
          .subtract(const Duration(days: 2))
          .millisecondsSinceEpoch,
    });
    expect(await c.read(backupReminderProvider.future), isNull);
  });

  test('a snooze hides it', () async {
    await addExpenses(12);
    final c = await container({
      AutoBackupKeys.firstSeenAt: longAgo,
      backupReminderSnoozedUntilKey: DateTime.now()
          .add(const Duration(days: 3))
          .millisecondsSinceEpoch,
    });
    expect(await c.read(backupReminderProvider.future), isNull);
  });
}
