// 5a migration guard: adding walletId to GoalSavingModel is additive and
// non-destructive. Legacy savings (written before the field existed, and any
// call site that doesn't set it) must read back as walletId == null — those are
// never wallet-debited and never refunded on goal deletion.

import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/database/models/goal_saving_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;

  setUp(() async {
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
    tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-goalsave-');
    isar = await Isar.open(
      [GoalSavingModelSchema],
      directory: tempDir.path,
      name: 'goal_saving_wallet_migration_test',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('legacy-style saving (no walletId set) reads back as null', () async {
    final legacy = GoalSavingModel()
      ..goalId = 1
      ..amount = 500
      ..date = DateTime(2026, 7, 1); // walletId intentionally unset

    final id = await isar.writeTxn(() => isar.goalSavingModels.put(legacy));
    final loaded = await isar.goalSavingModels.get(id);

    expect(loaded, isNotNull);
    expect(loaded!.walletId, isNull);
  });

  test('wallet-debited saving round-trips its walletId and is queryable', () async {
    final saving = GoalSavingModel()
      ..goalId = 1
      ..amount = 300
      ..date = DateTime(2026, 7, 2)
      ..walletId = 7;

    final id = await isar.writeTxn(() => isar.goalSavingModels.put(saving));

    expect((await isar.goalSavingModels.get(id))!.walletId, 7);
    final debited = await isar.goalSavingModels
        .filter()
        .walletIdIsNotNull()
        .findAll();
    expect(debited, hasLength(1));
    expect(debited.single.walletId, 7);
  });
}
