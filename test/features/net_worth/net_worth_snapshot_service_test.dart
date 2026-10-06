import 'dart:ffi';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:gemini_chat/core/backup/isar_export_service.dart';
import 'package:gemini_chat/core/database/clear_all_data.dart';
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
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/features/category/data/models/category_model.dart';
import 'package:gemini_chat/features/chat/data/models/message_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/net_worth/data/models/net_worth_snapshot_model.dart';
import 'package:gemini_chat/features/net_worth/data/net_worth_snapshot_service.dart';
import 'package:gemini_chat/features/prediction/data/models/prediction_cache_model.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

/// Every schema the app opens EXCEPT the snapshot one — the "before G1" app.
final _preG1Schemas = <CollectionSchema<dynamic>>[
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
];

final _currentSchemas = [..._preG1Schemas, NetWorthSnapshotModelSchema];

WalletModel _wallet(
  String name,
  double balance, {
  required int sortOrder,
  bool archived = false,
}) {
  final now = DateTime(2026, 10, 1);
  return WalletModel()
    ..name = name
    ..type = WalletType.cash
    ..emoji = '👛'
    ..initialBalance = 0
    ..currentBalance = balance
    ..sortOrder = sortOrder
    ..isArchived = archived
    ..createdAt = now
    ..updatedAt = now;
}

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
  late DateTime now;
  late NetWorthSnapshotService service;

  Future<Isar> open(List<CollectionSchema<dynamic>> schemas, String name) {
    return Isar.open(schemas, directory: dir.path, name: name);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pocketpilot-networth-');
    isar = await open(
      _currentSchemas,
      'nw_${DateTime.now().microsecondsSinceEpoch}',
    );
    now = DateTime(2026, 10, 6, 9, 0);
    service = NetWorthSnapshotService(isar: isar, clock: () => now);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  Future<void> putWallets(List<WalletModel> wallets) =>
      isar.writeTxn(() => isar.walletModels.putAll(wallets));

  group('capture', () {
    test('writes one snapshot per day and is idempotent', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);

      expect(await service.captureIfNeeded(force: true), isTrue);
      expect(await service.captureIfNeeded(force: true), isFalse);
      expect(await service.captureIfNeeded(), isFalse);

      final rows = await service.all();
      expect(rows, hasLength(1));
      expect(rows.single.dayKey, 20261006);
      expect(rows.single.total, 1000);
    });

    test(
      'same-day refresh updates the row only when balances changed',
      () async {
        await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
        await service.captureIfNeeded(force: true);
        final first = (await service.all()).single;

        now = DateTime(2026, 10, 6, 21, 30);
        final wallet = (await isar.walletModels.where().findFirst())!;
        wallet.currentBalance = 850;
        await isar.writeTxn(() => isar.walletModels.put(wallet));

        expect(await service.captureIfNeeded(force: true), isTrue);
        final rows = await service.all();
        expect(rows, hasLength(1), reason: 'still one row for the day');
        expect(rows.single.id, first.id);
        expect(rows.single.total, 850);
        expect(
          rows.single.createdAt,
          first.createdAt,
          reason: 'first write kept',
        );
        expect(rows.single.capturedAt, now, reason: 'real latest capture time');
      },
    );

    test('resume throttle: a quick second resume does not re-read', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
      await service.captureIfNeeded();
      final wallet = (await isar.walletModels.where().findFirst())!;
      wallet.currentBalance = 5;
      await isar.writeTxn(() => isar.walletModels.put(wallet));

      now = now.add(const Duration(seconds: 5));
      expect(await service.captureIfNeeded(), isFalse);
      expect((await service.all()).single.total, 1000);

      now = now.add(const Duration(minutes: 1));
      expect(await service.captureIfNeeded(), isTrue);
      expect((await service.all()).single.total, 5);
    });

    test('no wallets at all -> nothing recorded', () async {
      expect(await service.captureIfNeeded(force: true), isFalse);
      expect(await service.all(), isEmpty);
    });

    test('archived wallets are excluded from total and perWallet', () async {
      await putWallets([
        _wallet('নগদ', 700, sortOrder: 0),
        _wallet('পুরনো', 9999, sortOrder: 1, archived: true),
        _wallet('বিকাশ', 300.5, sortOrder: 2),
      ]);
      await service.captureIfNeeded(force: true);

      final row = (await service.all()).single;
      expect(row.total, 1000.5);
      expect(row.perWallet.map((w) => w.name), ['নগদ', 'বিকাশ']);
      expect(row.perWallet.fold<double>(0, (s, w) => s + w.balance), row.total);
    });

    test('all wallets archived is a real zero, not a skip', () async {
      await putWallets([_wallet('পুরনো', 50, sortOrder: 0, archived: true)]);
      await service.captureIfNeeded(force: true);
      expect((await service.all()).single.total, 0);
    });

    test('clock moved backwards never overwrites or back-dates', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
      await service.captureIfNeeded(force: true);

      now = DateTime(2026, 10, 3, 9);
      expect(await service.captureIfNeeded(force: true), isFalse);
      expect((await service.all()).map((r) => r.dayKey), [20261006]);
    });

    test('first open after a month-end keeps its REAL date', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
      now = DateTime(2026, 10, 28, 20);
      await service.captureIfNeeded(force: true);
      now = DateTime(2026, 11, 2, 8); // app not opened Oct 29–Nov 1
      await service.captureIfNeeded(force: true);

      expect((await service.all()).map((r) => r.dayKey), [20261028, 20261102]);
    });

    test('never throws, even when storage is gone', () async {
      await putWallets([_wallet('নগদ', 1, sortOrder: 0)]);
      await isar.close();
      expect(await service.captureIfNeeded(force: true), isFalse);
      isar = await open(
        _currentSchemas,
        'nw_reopen_${DateTime.now().microsecondsSinceEpoch}',
      );
    });
  });

  group('equals totalBalanceProvider exactly', () {
    test(
      'mixed archived/active wallets inserted out of order, fractional',
      () async {
        await putWallets([
          _wallet('গ', 0.3, sortOrder: 2),
          _wallet('ক', 0.1, sortOrder: 0),
          _wallet('আর্কাইভড', 777, sortOrder: 1, archived: true),
          _wallet('খ', 0.2, sortOrder: 1),
          _wallet('ঘ', 1234567.89, sortOrder: 3),
        ]);

        final container = ProviderContainer(
          overrides: [isarProvider.overrideWithValue(isar)],
        );
        addTearDown(container.dispose);
        await container.read(walletProvider.future);
        final providerTotal = container.read(totalBalanceProvider);

        await service.captureIfNeeded(force: true);
        final snapshotTotal = (await service.all()).single.total;

        expect(snapshotTotal, providerTotal, reason: 'bit-for-bit, not approx');
      },
    );
  });

  group('retention through the service', () {
    test('thins old rows when a new day is written', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
      // 200 consecutive daily rows ending 150 days ago (all in the thinning window).
      final base = DateTime(2026, 10, 6);
      await isar.writeTxn(() async {
        for (var i = 150; i < 350; i++) {
          final day = DateTime(base.year, base.month, base.day - i);
          await isar.netWorthSnapshotModels.put(
            NetWorthSnapshotModel()
              ..dayKey = dayKeyOf(day)
              ..capturedAt = day
              ..createdAt = day
              ..total = i.toDouble()
              ..perWalletJson = '[]',
          );
        }
      });

      await service.captureIfNeeded(force: true); // inserts today -> retention
      final rows = await service.all();
      expect(rows.length, lessThan(70));
      expect(rows.last.dayKey, 20261006);

      // A second run changes nothing.
      now = DateTime(2026, 10, 7, 9);
      await service.captureIfNeeded(force: true);
      expect(await service.all(), hasLength(rows.length + 1));
    });
  });

  group('backup / restore', () {
    Future<Isar> openTarget() => open(
      _currentSchemas,
      'nw_target_${DateTime.now().microsecondsSinceEpoch}',
    );

    test('round-trips snapshots', () async {
      await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
      await service.captureIfNeeded(force: true);
      now = DateTime(2026, 10, 7, 9);
      await service.captureIfNeeded(force: true);

      final exported = await IsarExportService().exportAll(isar);
      expect(
        (exported['collections'] as Map).containsKey('netWorthSnapshots'),
        isTrue,
      );

      final target = await openTarget();
      addTearDown(() => target.close(deleteFromDisk: true));
      await IsarExportService().importAll(target, exported);

      final restored = await target.netWorthSnapshotModels
          .where()
          .sortByDayKey()
          .findAll();
      expect(restored.map((r) => r.dayKey), [20261006, 20261007]);
      expect(restored.first.total, 1000);
      expect(restored.first.perWallet.single.name, 'নগদ');
    });

    test(
      'an OLD backup (no snapshot key) leaves local history alone',
      () async {
        await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
        await service.captureIfNeeded(force: true);

        final exported = await IsarExportService().exportAll(isar);
        (exported['collections'] as Map).remove('netWorthSnapshots');

        await IsarExportService().importAll(isar, exported);
        expect((await service.all()).map((r) => r.dayKey), [20261006]);
      },
    );

    test(
      'a NEW backup replaces local history; duplicate days collapse',
      () async {
        await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
        await service.captureIfNeeded(force: true);

        final exported = await IsarExportService().exportAll(isar);
        (exported['collections'] as Map)['netWorthSnapshots'] = [
          {
            'dayKey': 20260101,
            'capturedAt': '2026-01-01T08:00:00.000',
            'createdAt': '2026-01-01T08:00:00.000',
            'total': 10.0,
            'perWalletJson': '[]',
          },
          {
            'dayKey': 20260101,
            'capturedAt': '2026-01-01T20:00:00.000',
            'createdAt': '2026-01-01T08:00:00.000',
            'total': 12.0,
            'perWalletJson': '[]',
          },
        ];

        await IsarExportService().importAll(isar, exported);
        final restored = await service.all();
        expect(restored, hasLength(1));
        expect(restored.single.dayKey, 20260101);
        expect(
          restored.single.total,
          12,
          reason: 'latest refresh of the day wins',
        );
      },
    );
  });

  test('delete-all removes snapshots', () async {
    await putWallets([_wallet('নগদ', 1000, sortOrder: 0)]);
    await service.captureIfNeeded(force: true);
    expect(await service.all(), isNotEmpty);

    await clearAllUserCollections(isar);
    expect(await service.all(), isEmpty);
    expect(await isar.walletModels.count(), 0);
  });

  test(
    'schema is additive: an existing pre-G1 database upgrades in place',
    () async {
      final name = 'nw_upgrade_${DateTime.now().microsecondsSinceEpoch}';
      final old = await open(_preG1Schemas, name);
      await old.writeTxn(() async {
        await old.walletModels.putAll([
          _wallet('নগদ', 1500, sortOrder: 0),
          _wallet('বিকাশ', 250, sortOrder: 1),
        ]);
        await old.expenseRecordModels.put(
          ExpenseRecordModel()
            ..amount = 99
            ..category = 'Food'
            ..description = 'পুরনো খরচ'
            ..walletId = 1
            ..isManual = true
            ..date = DateTime(2026, 9, 30),
        );
      });
      await old.close(); // keep the files: this is the user's existing data

      final upgraded = await open(_currentSchemas, name);
      addTearDown(() => upgraded.close(deleteFromDisk: true));

      expect(await upgraded.walletModels.count(), 2);
      expect(await upgraded.expenseRecordModels.count(), 1);
      expect(
        (await upgraded.walletModels.where().findAll()).map(
          (w) => w.currentBalance,
        ),
        unorderedEquals([1500, 250]),
      );
      expect(await upgraded.netWorthSnapshotModels.count(), 0);

      final upgradedService = NetWorthSnapshotService(
        isar: upgraded,
        clock: () => now,
      );
      expect(await upgradedService.captureIfNeeded(force: true), isTrue);
      expect((await upgradedService.all()).single.total, 1750);
    },
  );
}
