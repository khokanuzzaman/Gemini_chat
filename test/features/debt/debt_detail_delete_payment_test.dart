// R3 (b): the debt-detail "পরিশোধ মুছুন" action. This is the ONLY place an EMI
// payment is undone (the খরচ list shows EMI rows read-only). Confirming must
// reverse the wallet, the mirror expense and the debt's remaining amount
// TOGETHER; cancelling must change nothing.

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/database/models/expense_record_model.dart';
import 'package:gemini_chat/core/database/models/income_record_model.dart';
import 'package:gemini_chat/core/database/models/wallet_model.dart';
import 'package:gemini_chat/core/providers/database_providers.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/features/debt/data/datasources/debt_local_datasource.dart';
import 'package:gemini_chat/features/debt/data/models/debt_model.dart';
import 'package:gemini_chat/features/debt/data/models/debt_payment_model.dart';
import 'package:gemini_chat/features/debt/domain/entities/debt_entity.dart';
import 'package:gemini_chat/features/debt/presentation/providers/debt_providers.dart';
import 'package:gemini_chat/features/debt/presentation/screens/debt_detail_screen.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

import '../../helpers/app_fonts.dart';

var _instance = 0; // one Isar instance name per test (a slow close can linger)

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory tempDir;
  late ProviderContainer container;
  late int walletId;
  late int debtId;

  setUpAll(() async {
    await loadAppFonts();
    await initializeDateFormatting('bn');
    await Isar.initializeIsarCore(
      libraries: {
        Abi.current():
            '${Platform.environment['HOME']!}/.pub-cache/hosted/pub.dev/isar_community_flutter_libs-3.3.2/macos/libisar.dylib',
      },
    );
  });

  // Isar completes on the real event loop, which testWidgets' fake zone does not
  // drive — resolve the providers the screen reads under runAsync first.
  Future<void> resolveProviders(WidgetTester tester) =>
      tester.runAsync(() async {
        await container.read(debtDetailProvider(debtId).future);
        await container.read(walletProvider.future);
      });

  // iOwe 1000, one 300 payment recorded through the real flow: wallet 1000 ->
  // 700, mirror expense written, remaining 1000 -> 700.
  Future<void> arrange(WidgetTester tester) async {
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('pocketpilot-ai-delpay-');
      isar = await Isar.open(
        [
          WalletModelSchema,
          DebtModelSchema,
          DebtPaymentModelSchema,
          ExpenseRecordModelSchema,
          IncomeRecordModelSchema,
        ],
        directory: tempDir.path,
        name: 'debt_detail_delete_payment_${_instance++}',
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          isarProvider.overrideWithValue(isar),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      final now = DateTime.now();
      walletId = await isar.writeTxn(
        () => isar.walletModels.put(
          WalletModel()
            ..name = 'Cash'
            ..type = WalletType.cash
            ..emoji = '💵'
            ..initialBalance = 1000
            ..currentBalance = 1000
            ..sortOrder = 0
            ..createdAt = now
            ..updatedAt = now,
        ),
      );
      final saved = await DebtLocalDataSource(isar).saveDebt(
        DebtModel()
          ..personName = 'Rahim'
          ..type = DebtType.iOwe
          ..originalAmount = 1000
          ..remainingAmount = 1000
          ..status = DebtStatus.active
          ..createdAt = DateTime(2026, 7, 1)
          ..walletId = walletId
          ..reminderEnabled = false,
      );
      debtId = saved.id;
      final result = await container
          .read(debtMutationControllerProvider)
          .addPayment(debtId, 300);
      expect(result.isSuccess, isTrue);
    });
    addTearDown(() async {
      // Unmount first so no screen read is in flight when Isar closes.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        container.dispose();
        // After the delete flow a screen read can still be parked in the fake
        // zone, which makes Isar.close wait forever. Bound it: this is test
        // teardown of a throwaway temp database, not product behaviour.
        await isar
            .close(deleteFromDisk: true)
            .timeout(const Duration(seconds: 3), onTimeout: () => false);
        try {
          if (await tempDir.exists()) await tempDir.delete(recursive: true);
        } catch (_) {}
      });
    });

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await resolveProviders(tester);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: DebtDetailScreen(debtId: debtId),
        ),
      ),
    );
    await settle(tester);
  }

  Future<double> walletBalance() async =>
      (await isar.walletModels.get(walletId))!.currentBalance;

  testWidgets('the arranged state is what the assertions below assume', (
    tester,
  ) async {
    await arrange(tester);
    await tester.runAsync(() async {
      expect(await walletBalance(), 700);
      expect(await isar.debtPaymentModels.count(), 1);
      expect(await isar.expenseRecordModels.count(), 1);
      expect((await isar.debtModels.get(debtId))!.remainingAmount, 700);
    });
    expect(find.byTooltip('পরিশোধ মুছুন'), findsOneWidget);
  });

  testWidgets(
    'confirm: wallet, mirror expense and remaining reverse together',
    (tester) async {
      await arrange(tester);

      await tester.tap(find.byTooltip('পরিশোধ মুছুন'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('পরিশোধ মুছবেন?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('পরিশোধ মুছুন'),
        ),
      );
      // Poll the database (real time) rather than guessing a delay: under a
      // loaded full-suite run the ledger txn can take well over a second.
      for (var n = 0; n < 200; n++) {
        final remaining = await tester.runAsync(
          () => isar.debtPaymentModels.count(),
        );
        if (remaining == 0) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
      }
      await settle(tester);

      await tester.runAsync(() async {
        expect(await walletBalance(), 1000); // refunded once
        expect(await isar.debtPaymentModels.count(), 0);
        expect(await isar.expenseRecordModels.count(), 0); // mirror gone
        expect((await isar.debtModels.get(debtId))!.remainingAmount, 1000);
      });
      expect(find.byTooltip('পরিশোধ মুছুন'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel ("না") changes nothing', (tester) async {
    await arrange(tester);

    await tester.tap(find.byTooltip('পরিশোধ মুছুন'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('না'));
    await settle(tester);

    await tester.runAsync(() async {
      expect(await walletBalance(), 700);
      expect(await isar.debtPaymentModels.count(), 1);
      expect(await isar.expenseRecordModels.count(), 1);
      expect((await isar.debtModels.get(debtId))!.remainingAmount, 700);
    });
    expect(find.byTooltip('পরিশোধ মুছুন'), findsOneWidget);
  });
}

/// Lets real Isar futures complete (runAsync), then rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 400));
}
