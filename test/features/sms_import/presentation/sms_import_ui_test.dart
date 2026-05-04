import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gemini_chat/core/ai/expense_result.dart';
import 'package:gemini_chat/core/database/models/sms_ledger_entry_model.dart';
import 'package:gemini_chat/core/providers/shared_preferences_provider.dart';
import 'package:gemini_chat/core/sms/parsed_transaction.dart';
import 'package:gemini_chat/core/sms/sms_background_listener.dart';
import 'package:gemini_chat/core/sms/sms_category_mapper.dart';
import 'package:gemini_chat/core/sms/sms_duplicate_detector.dart';
import 'package:gemini_chat/core/sms/sms_filter.dart';
import 'package:gemini_chat/core/sms/sms_import_entry.dart';
import 'package:gemini_chat/core/sms/sms_import_orchestrator.dart';
import 'package:gemini_chat/core/sms/sms_import_result.dart';
import 'package:gemini_chat/core/sms/sms_ledger_models.dart';
import 'package:gemini_chat/core/sms/sms_ledger_service.dart';
import 'package:gemini_chat/core/sms/sms_message.dart';
import 'package:gemini_chat/core/sms/sms_parser.dart';
import 'package:gemini_chat/core/sms/sms_permission_handler.dart';
import 'package:gemini_chat/core/sms/sms_reader_service.dart';
import 'package:gemini_chat/core/sms/sms_wallet_matcher.dart';
import 'package:gemini_chat/core/theme/app_theme.dart';
import 'package:gemini_chat/core/widgets/app_action_button.dart';
import 'package:gemini_chat/features/expense/presentation/providers/expense_providers.dart';
import 'package:gemini_chat/features/expense/domain/entities/expense_entity.dart';
import 'package:gemini_chat/features/income/domain/entities/income_entity.dart';
import 'package:gemini_chat/features/income/presentation/providers/income_providers.dart';
import 'package:gemini_chat/features/sms_import/domain/entities/sms_permission_state.dart';
import 'package:gemini_chat/features/sms_import/presentation/models/sms_history_models.dart';
import 'package:gemini_chat/features/sms_import/presentation/models/sms_import_models.dart';
import 'package:gemini_chat/features/sms_import/presentation/providers/sms_history_provider.dart';
import 'package:gemini_chat/features/sms_import/presentation/providers/sms_import_provider.dart';
import 'package:gemini_chat/features/sms_import/presentation/screens/sms_history_screen.dart';
import 'package:gemini_chat/features/sms_import/presentation/screens/sms_import_screen.dart';
import 'package:gemini_chat/features/sms_import/presentation/widgets/sms_import_entry_widgets.dart';
import 'package:gemini_chat/features/sms_import/presentation/widgets/sms_import_edit_sheet.dart';
import 'package:gemini_chat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:gemini_chat/features/wallet/presentation/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  setUpAll(() async {
    await initializeDateFormatting('bn');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (_) async => null);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    _TestWalletNotifier.wallets = [
      _wallet(id: 1, name: 'Cash', type: WalletType.cash, sortOrder: 1),
      _wallet(id: 2, name: 'bKash', type: WalletType.bkash, sortOrder: 2),
      _wallet(id: 3, name: 'BRAC Bank', type: WalletType.bank, sortOrder: 3),
    ];
  });

  group('SmsImportController', () {
    test('refreshStatus loads permission and import stats', () async {
      final permissionHandler = _FakeSmsPermissionHandler(
        status: PermissionStatus.denied,
      );
      final duplicateDetector = _FakeSmsDuplicateDetector(
        importedCount: 4,
        lastImportDate: DateTime(2026, 4, 12, 9, 0),
      );
      final ledgerService = _FakeSmsLedgerService(
        entries: [_ledgerEntry(id: 1, smsId: 1)],
        lastSuccessfulSyncAt: DateTime(2026, 4, 13, 8),
      );
      await preferences.setInt('sms_imported_count', 4);
      final container = _buildContainer(
        preferences: preferences,
        permissionHandler: permissionHandler,
        duplicateDetector: duplicateDetector,
        ledgerService: ledgerService,
      );
      addTearDown(container.dispose);

      final controller = container.read(smsImportControllerProvider.notifier);
      await controller.refreshStatus(showLoading: true);

      final state = container.read(smsImportControllerProvider);
      expect(state.permissionState, SmsPermissionState.denied);
      expect(state.importedCount, 4);
      expect(state.lastImportDate, DateTime(2026, 4, 12, 9, 0));
    });

    test(
      'scanForNewTransactions keeps only expense and income candidates',
      () async {
        final expenseCandidate = _candidate(
          id: 101,
          type: TransactionType.expense,
          source: ParsedTransactionSource.bkash,
          counterparty: 'Foodpanda',
          amount: 420,
          suggestedWallet: _TestWalletNotifier.wallets[1],
          suggestedCategory: 'Food',
        );
        final incomeCandidate = _candidate(
          id: 102,
          type: TransactionType.income,
          source: ParsedTransactionSource.bank,
          counterparty: 'Acme Payroll',
          amount: 28000,
          suggestedWallet: _TestWalletNotifier.wallets[2],
          suggestedIncomeSource: 'Salary',
        );
        final transferCandidate = _candidate(
          id: 103,
          type: TransactionType.transfer,
          source: ParsedTransactionSource.nagad,
          counterparty: 'Transfer',
          amount: 2000,
          suggestedWallet: _TestWalletNotifier.wallets[0],
        );
        final orchestrator = _FakeSmsImportOrchestrator(
          result: _result(
            candidates: [expenseCandidate, incomeCandidate, transferCandidate],
            duplicateCount: 1,
          ),
        );
        final container = _buildContainer(
          preferences: preferences,
          permissionHandler: _FakeSmsPermissionHandler(
            status: PermissionStatus.granted,
          ),
          orchestrator: orchestrator,
        );
        addTearDown(container.dispose);

        final controller = container.read(smsImportControllerProvider.notifier);
        await controller.scanForNewTransactions();

        final state = container.read(smsImportControllerProvider);
        expect(orchestrator.scanCalls, 1);
        expect(state.permissionState, SmsPermissionState.granted);
        expect(state.candidates.map((item) => item.sms.id), [101, 102]);
        expect(state.selectedIds, {101, 102});
        expect(state.lastScanReadyCount, 2);
        expect(state.drafts[101]?.category, 'Food');
        expect(state.drafts[102]?.incomeSource, 'Salary');
      },
    );

    test('scanForNewTransactions handles duplicate-only scans', () async {
      final smsOne = _sms(
        id: 201,
        address: 'bKash',
        body: 'Payment complete',
        date: DateTime(2026, 4, 20, 9, 30),
      );
      final smsTwo = _sms(
        id: 202,
        address: 'Nagad',
        body: 'Send money complete',
        date: DateTime(2026, 4, 20, 10, 0),
      );
      final parsed = [
        _transaction(
          smsId: 201,
          type: TransactionType.expense,
          source: ParsedTransactionSource.bkash,
          counterparty: 'Restaurant',
          amount: 300,
          occurredAt: smsOne.date,
        ),
        _transaction(
          smsId: 202,
          type: TransactionType.expense,
          source: ParsedTransactionSource.nagad,
          counterparty: 'Friend',
          amount: 500,
          occurredAt: smsTwo.date,
        ),
      ];
      final orchestrator = _FakeSmsImportOrchestrator(
        result: SmsImportResult(
          since: DateTime(2026, 4, 1),
          scannedMessages: [smsOne, smsTwo],
          financialMessages: [smsOne, smsTwo],
          parsedTransactions: parsed,
          candidates: const [],
          duplicateCount: 2,
        ),
      );
      final container = _buildContainer(
        preferences: preferences,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        orchestrator: orchestrator,
      );
      addTearDown(container.dispose);

      await container
          .read(smsImportControllerProvider.notifier)
          .scanForNewTransactions();

      final state = container.read(smsImportControllerProvider);
      expect(state.scanAttempted, isTrue);
      expect(state.hasCandidates, isFalse);
      expect(state.lastScanReadyCount, 0);
      expect(state.latestScanResult?.duplicateCount, 2);
      expect(state.latestScanResult?.financialCount, 2);
    });

    test(
      'importSelected keeps failed rows and marks successful imports',
      () async {
        final expenseCandidate = _candidate(
          id: 301,
          type: TransactionType.expense,
          source: ParsedTransactionSource.bkash,
          counterparty: 'Foodpanda',
          amount: 550,
          suggestedWallet: _TestWalletNotifier.wallets[1],
          suggestedCategory: 'Food',
        );
        final incomeCandidate = _candidate(
          id: 302,
          type: TransactionType.income,
          source: ParsedTransactionSource.bank,
          counterparty: 'Monthly Salary',
          amount: 35000,
          suggestedWallet: _TestWalletNotifier.wallets[2],
          suggestedIncomeSource: 'Salary',
        );
        final duplicateDetector = _FakeSmsDuplicateDetector();
        final ledgerService = _FakeSmsLedgerService();
        final expenseController = _FakeExpenseMutationController();
        final incomeController = _FakeIncomeMutationController()
          ..nextError = 'আয় সংরক্ষণ ব্যর্থ হয়েছে';
        final container = _buildContainer(
          preferences: preferences,
          permissionHandler: _FakeSmsPermissionHandler(
            status: PermissionStatus.granted,
          ),
          duplicateDetector: duplicateDetector,
          orchestrator: _FakeSmsImportOrchestrator(
            result: _result(candidates: [expenseCandidate, incomeCandidate]),
          ),
          expenseController: expenseController,
          incomeController: incomeController,
          ledgerService: ledgerService,
        );
        addTearDown(container.dispose);

        final controller = container.read(smsImportControllerProvider.notifier);
        await controller.scanForNewTransactions();
        final outcome = await controller.importSelected();

        final state = container.read(smsImportControllerProvider);
        expect(outcome.importedCount, 1);
        expect(outcome.failedCount, 1);
        expect(outcome.skippedCount, 0);
        expect(duplicateDetector.markedSms.map((sms) => sms.id), [301]);
        expect(ledgerService.upsertedSmsIds, [301]);
        expect(expenseController.savedExpenses.single.category, 'Food');
        expect(incomeController.savedIncomes.single.source, 'Salary');
        expect(state.candidates.map((item) => item.sms.id), [302]);
        expect(state.rowErrors[302], 'আয় সংরক্ষণ ব্যর্থ হয়েছে');
        expect(state.importedCount, 1);
      },
    );
  });

  group('SmsAutoImportNotifier', () {
    test('enable starts listener when permission is granted', () async {
      final listener = _FakeSmsBackgroundListener();
      final container = _buildContainer(
        preferences: preferences,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        backgroundListener: listener,
      );
      addTearDown(container.dispose);

      final notifier = container.read(smsAutoImportProvider.notifier);
      await notifier.enable();

      final state = container.read(smsAutoImportProvider);
      expect(state.isEnabled, isTrue);
      expect(state.isListening, isTrue);
      expect(listener.startCalls, greaterThanOrEqualTo(1));
    });

    test(
      'rescan adds pending transactions and confirmAndSave removes them',
      () async {
        final entry = SmsImportEntry(
          signature: 'sig-1',
          sms: _sms(
            id: 901,
            address: 'bKash',
            body: 'Foodpanda 450',
            date: DateTime(2026, 4, 22, 13, 0),
          ),
          transaction: _transaction(
            smsId: 901,
            type: TransactionType.expense,
            source: ParsedTransactionSource.bkash,
            counterparty: 'Foodpanda',
            amount: 450,
            occurredAt: DateTime(2026, 4, 22, 13, 0),
          ),
          detectedAt: DateTime(2026, 4, 22, 13, 0),
          suggestedWallet: _TestWalletNotifier.wallets[1],
          suggestedCategory: 'Food',
        );
        final listener = _FakeSmsBackgroundListener()..pollEntries = [entry];
        final expenseController = _FakeExpenseMutationController();
        final container = _buildContainer(
          preferences: preferences,
          permissionHandler: _FakeSmsPermissionHandler(
            status: PermissionStatus.granted,
          ),
          backgroundListener: listener,
          expenseController: expenseController,
        );
        addTearDown(container.dispose);

        final notifier = container.read(smsAutoImportProvider.notifier);
        await notifier.enable();
        await notifier.rescan();

        var state = container.read(smsAutoImportProvider);
        expect(state.pendingTransactions, hasLength(1));
        expect(state.pendingTransactions.first.signature, 'sig-1');

        final error = await notifier.confirmAndSave(
          state.pendingTransactions.first,
        );
        expect(error, isNull);

        state = container.read(smsAutoImportProvider);
        expect(state.pendingTransactions, isEmpty);
        expect(expenseController.savedExpenses, hasLength(1));
        expect(preferences.getInt('sms_imported_count'), 1);
      },
    );
  });

  group('SMS Auto-Import UI', () {
    testWidgets('settings tile navigates to SMS history screen', (
      tester,
    ) async {
      final ledgerService = _FakeSmsLedgerService(
        lastSuccessfulSyncAt: DateTime(2026, 4, 20, 10),
      );
      await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.denied,
        ),
        ledgerService: ledgerService,
        home: const Scaffold(body: SmsImportSettingsTile()),
      );

      await tester.tap(find.byKey(const Key('sms-import-settings-tile')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('sms-history-permission-cta')),
        findsOneWidget,
      );
    });

    testWidgets('dashboard chip navigates to SMS import screen', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        home: const Scaffold(body: SmsImportQuickActionChip()),
      );

      await tester.tap(find.byKey(const Key('sms-import-dashboard-chip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sms-import-scan-cta')), findsOneWidget);
    });

    testWidgets('dashboard teaser appears when permission is missing', (
      tester,
    ) async {
      final ledgerService = _FakeSmsLedgerService();
      await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.denied,
        ),
        ledgerService: ledgerService,
        home: const Scaffold(body: SmsImportDashboardTeaserCard()),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('sms-import-dashboard-teaser')),
        findsOneWidget,
      );
      expect(find.text('SMS থেকে লেনদেন আনুন'), findsOneWidget);
    });

    testWidgets('permission CTA requests access and reveals scan button', (
      tester,
    ) async {
      final permissionHandler = _FakeSmsPermissionHandler(
        status: PermissionStatus.denied,
        requestedStatus: PermissionStatus.granted,
      );
      final ledgerService = _FakeSmsLedgerService();
      await _pumpApp(
        tester,
        permissionHandler: permissionHandler,
        ledgerService: ledgerService,
        home: const SmsImportScreen(),
      );

      await tester.tap(find.byKey(const Key('sms-import-permission-cta')));
      await tester.pumpAndSettle();

      expect(permissionHandler.requestCalls, 1);
      expect(find.byKey(const Key('sms-import-scan-cta')), findsOneWidget);
    });

    testWidgets('scan renders review UI with summary, tabs, and footer', (
      tester,
    ) async {
      final expenseCandidate = _candidate(
        id: 401,
        type: TransactionType.expense,
        source: ParsedTransactionSource.bkash,
        counterparty: 'Foodpanda',
        amount: 680,
        confidence: 0.92,
        suggestedWallet: _TestWalletNotifier.wallets[1],
        suggestedCategory: 'Food',
      );
      final incomeCandidate = _candidate(
        id: 402,
        type: TransactionType.income,
        source: ParsedTransactionSource.bank,
        counterparty: 'Acme Payroll',
        amount: 42000,
        suggestedWallet: _TestWalletNotifier.wallets[2],
        suggestedIncomeSource: 'Salary',
      );

      final container = await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        orchestrator: _FakeSmsImportOrchestrator(
          result: _result(candidates: [expenseCandidate, incomeCandidate]),
        ),
        ledgerService: _FakeSmsLedgerService(),
        home: const SmsImportScreen(),
      );

      await tester.tap(find.byKey(const Key('sms-import-scan-cta')));
      await tester.pumpAndSettle();

      final state = container.read(smsImportControllerProvider);
      expect(state.latestScanResult, isNotNull);
      expect(state.candidates.length, 2);
      expect(state.selectedCount, 2);
    });

    testWidgets('footer stacks vertically on narrow phones', (tester) async {
      final expenseCandidate = _candidate(
        id: 411,
        type: TransactionType.expense,
        source: ParsedTransactionSource.bkash,
        counterparty: 'Foodpanda',
        amount: 680,
        suggestedWallet: _TestWalletNotifier.wallets[1],
        suggestedCategory: 'Food',
      );

      await _pumpApp(
        tester,
        surfaceSize: const Size(430, 932),
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        orchestrator: _FakeSmsImportOrchestrator(
          result: _result(candidates: [expenseCandidate]),
        ),
        ledgerService: _FakeSmsLedgerService(),
        home: const SmsImportScreen(),
      );

      await tester.tap(find.byKey(const Key('sms-import-scan-cta')));
      await tester.pumpAndSettle();

      final summaryTopLeft = tester.getTopLeft(find.text('১টি নির্বাচিত'));
      final buttonTopLeft = tester.getTopLeft(
        find.byKey(const Key('sms-import-footer-button')),
      );

      expect(buttonTopLeft.dy, greaterThan(summaryTopLeft.dy));
    });

    testWidgets('edit sheet updates a draft and returns the result', (
      tester,
    ) async {
      final candidate = _candidate(
        id: 451,
        type: TransactionType.expense,
        source: ParsedTransactionSource.bkash,
        counterparty: 'Foodpanda',
        amount: 680,
        suggestedWallet: _TestWalletNotifier.wallets[1],
        suggestedCategory: 'Food',
      );
      SmsImportDraft? updatedDraft;

      await _pumpApp(
        tester,
        ledgerService: _FakeSmsLedgerService(),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    updatedDraft = await showSmsImportEditSheet(
                      context,
                      candidate: candidate,
                      draft: SmsImportDraft.fromCandidate(candidate),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('sms-import-edit-description')),
        'Team dinner',
      );
      await tester.ensureVisible(find.byKey(const Key('sms-import-edit-save')));
      await tester.pumpAndSettle();
      final saveButton = tester.widget<AppActionButton>(
        find.byKey(const Key('sms-import-edit-save')),
      );
      saveButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(updatedDraft?.description, 'Team dinner');
    });

    testWidgets('partial success import shows summary and leaves failed row', (
      tester,
    ) async {
      final expenseCandidate = _candidate(
        id: 501,
        type: TransactionType.expense,
        source: ParsedTransactionSource.bkash,
        counterparty: 'Lunch',
        amount: 320,
        suggestedWallet: _TestWalletNotifier.wallets[1],
        suggestedCategory: 'Food',
      );
      final incomeCandidate = _candidate(
        id: 502,
        type: TransactionType.income,
        source: ParsedTransactionSource.bank,
        counterparty: 'Monthly Salary',
        amount: 38000,
        suggestedWallet: _TestWalletNotifier.wallets[2],
        suggestedIncomeSource: 'Salary',
      );
      final duplicateDetector = _FakeSmsDuplicateDetector();
      final incomeController = _FakeIncomeMutationController()
        ..nextError = 'এই আয় সংরক্ষণ করা যায়নি';

      final container = await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        orchestrator: _FakeSmsImportOrchestrator(
          result: _result(candidates: [expenseCandidate, incomeCandidate]),
        ),
        duplicateDetector: duplicateDetector,
        incomeController: incomeController,
        ledgerService: _FakeSmsLedgerService(),
        home: const SmsImportScreen(),
      );

      await tester.tap(find.byKey(const Key('sms-import-scan-cta')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sms-import-footer-button')));
      await tester.pumpAndSettle();

      expect(find.text('আংশিক ইমপোর্ট সম্পন্ন'), findsOneWidget);
      expect(
        container.read(smsImportControllerProvider).rowErrors[502],
        'এই আয় সংরক্ষণ করা যায়নি',
      );
      expect(
        container
            .read(smsImportControllerProvider)
            .candidates
            .map((item) => item.sms.id),
        [502],
      );
      expect(duplicateDetector.markedSms.map((sms) => sms.id), [501]);
    });

    testWidgets('history screen renders summary and filters history rows', (
      tester,
    ) async {
      final entries = [
        _ledgerEntry(
          id: 701,
          smsId: 701,
          source: ParsedTransactionSource.bkash,
          kind: ParsedTransactionKind.payment,
          type: TransactionType.expense,
          counterparty: 'Foodpanda',
          amount: 680,
          occurredAt: DateTime(2026, 4, 18, 13, 45),
        ),
        _ledgerEntry(
          id: 702,
          smsId: 702,
          source: ParsedTransactionSource.bank,
          kind: ParsedTransactionKind.bankCredit,
          type: TransactionType.income,
          counterparty: 'Acme Payroll',
          amount: 42000,
          occurredAt: DateTime(2026, 4, 19, 9, 10),
        ),
        _ledgerEntry(
          id: 703,
          smsId: 703,
          source: ParsedTransactionSource.nagad,
          kind: ParsedTransactionKind.sendMoney,
          type: TransactionType.expense,
          counterparty: 'Hidden transfer',
          amount: 500,
          occurredAt: DateTime(2026, 4, 17, 8, 30),
          isIgnored: true,
        ),
      ];
      final ledgerService = _FakeSmsLedgerService(
        entries: entries,
        lastSuccessfulSyncAt: DateTime(2026, 4, 20, 10),
      );

      final container = await _pumpApp(
        tester,
        permissionHandler: _FakeSmsPermissionHandler(
          status: PermissionStatus.granted,
        ),
        ledgerService: ledgerService,
        home: const SmsHistoryScreen(),
      );

      await tester.pumpAndSettle();

      expect(find.text('মাসিক activity'), findsOneWidget);
      expect(find.text('Source breakdown'), findsOneWidget);
      expect(find.text('Kind breakdown'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sms-history-tab-history')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sms-history-row-701')), findsOneWidget);
      expect(find.byKey(const Key('sms-history-row-702')), findsOneWidget);
      expect(find.byKey(const Key('sms-history-row-703')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sms-history-source-bank')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sms-history-row-701')), findsNothing);
      expect(find.byKey(const Key('sms-history-row-702')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sms-history-source-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('sms-history-search')),
        'Foodpanda',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sms-history-row-701')), findsOneWidget);
      expect(find.byKey(const Key('sms-history-row-702')), findsNothing);

      await tester.enterText(find.byKey(const Key('sms-history-search')), '');
      await tester.pumpAndSettle();

      container
          .read(smsHistoryControllerProvider.notifier)
          .setStatusFilter(SmsHistoryStatusFilter.hidden);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sms-history-row-703')), findsOneWidget);
      expect(find.byKey(const Key('sms-history-row-701')), findsNothing);
    });
  });
}

ProviderContainer _buildContainer({
  _FakeSmsPermissionHandler? permissionHandler,
  _FakeSmsImportOrchestrator? orchestrator,
  _FakeSmsDuplicateDetector? duplicateDetector,
  _FakeExpenseMutationController? expenseController,
  _FakeIncomeMutationController? incomeController,
  _FakeSmsLedgerService? ledgerService,
  _FakeSmsBackgroundListener? backgroundListener,
  required SharedPreferences preferences,
}) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      walletProvider.overrideWith(_TestWalletNotifier.new),
      smsPermissionHandlerProvider.overrideWithValue(
        permissionHandler ??
            _FakeSmsPermissionHandler(status: PermissionStatus.granted),
      ),
      smsDuplicateDetectorProvider.overrideWithValue(
        duplicateDetector ?? _FakeSmsDuplicateDetector(),
      ),
      smsImportOrchestratorProvider.overrideWithValue(
        orchestrator ?? _FakeSmsImportOrchestrator(result: _result()),
      ),
      expenseMutationControllerProvider.overrideWithValue(
        expenseController ?? _FakeExpenseMutationController(),
      ),
      incomeMutationControllerProvider.overrideWithValue(
        incomeController ?? _FakeIncomeMutationController(),
      ),
      smsLedgerServiceProvider.overrideWithValue(
        ledgerService ?? _FakeSmsLedgerService(),
      ),
      if (backgroundListener != null)
        smsBackgroundListenerProvider.overrideWithValue(backgroundListener),
    ],
  );
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required Widget home,
  _FakeSmsPermissionHandler? permissionHandler,
  _FakeSmsImportOrchestrator? orchestrator,
  _FakeSmsDuplicateDetector? duplicateDetector,
  _FakeExpenseMutationController? expenseController,
  _FakeIncomeMutationController? incomeController,
  _FakeSmsLedgerService? ledgerService,
  _FakeSmsBackgroundListener? backgroundListener,
  SharedPreferences? preferences,
  Size surfaceSize = const Size(900, 2600),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = _buildContainer(
    preferences: preferences ?? await SharedPreferences.getInstance(),
    permissionHandler: permissionHandler,
    orchestrator: orchestrator,
    duplicateDetector: duplicateDetector,
    expenseController: expenseController,
    incomeController: incomeController,
    ledgerService: ledgerService,
    backgroundListener: backgroundListener,
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme(), home: home),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

SmsImportCandidate _candidate({
  required int id,
  required TransactionType type,
  required ParsedTransactionSource source,
  required String counterparty,
  required double amount,
  required WalletEntity suggestedWallet,
  String? suggestedCategory,
  String? suggestedIncomeSource,
  double confidence = 1,
  DateTime? date,
}) {
  final occurredAt = date ?? DateTime(2026, 4, 18, 13, 45);
  final sms = _sms(
    id: id,
    address: source.label,
    body: '$counterparty $amount',
    date: occurredAt,
  );
  return SmsImportCandidate(
    sms: sms,
    transaction: _transaction(
      smsId: id,
      type: type,
      source: source,
      counterparty: counterparty,
      amount: amount,
      confidence: confidence,
      occurredAt: occurredAt,
    ),
    suggestedWallet: suggestedWallet,
    suggestedCategory: suggestedCategory,
    suggestedIncomeSource: suggestedIncomeSource,
  );
}

SmsImportResult _result({
  List<SmsImportCandidate> candidates = const [],
  int duplicateCount = 0,
}) {
  final messages = [for (final candidate in candidates) candidate.sms];
  final transactions = [
    for (final candidate in candidates) candidate.transaction,
  ];
  return SmsImportResult(
    since: DateTime(2026, 4, 1),
    scannedMessages: messages,
    financialMessages: messages,
    parsedTransactions: transactions,
    candidates: candidates,
    duplicateCount: duplicateCount,
  );
}

ParsedTransaction _transaction({
  required int smsId,
  required TransactionType type,
  required ParsedTransactionSource source,
  required String counterparty,
  required double amount,
  required DateTime occurredAt,
  double confidence = 1,
}) {
  final direction = switch (type) {
    TransactionType.expense => ParsedTransactionDirection.debit,
    TransactionType.income => ParsedTransactionDirection.credit,
    TransactionType.transfer => ParsedTransactionDirection.credit,
    TransactionType.unknown => ParsedTransactionDirection.unknown,
  };
  final kind = switch (type) {
    TransactionType.expense => ParsedTransactionKind.payment,
    TransactionType.income => ParsedTransactionKind.bankCredit,
    TransactionType.transfer => ParsedTransactionKind.transfer,
    TransactionType.unknown => ParsedTransactionKind.unknown,
  };

  return ParsedTransaction(
    smsId: smsId,
    sender: source.label,
    source: source,
    direction: direction,
    kind: kind,
    amount: amount,
    rawMessage: '$counterparty $amount',
    receivedAt: occurredAt,
    occurredAt: occurredAt,
    counterparty: counterparty,
    confidence: confidence,
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
  required int sortOrder,
}) {
  final now = DateTime(2026, 4, 1);
  return WalletEntity(
    id: id,
    name: name,
    type: type,
    emoji: type.defaultEmoji,
    initialBalance: 0,
    currentBalance: 0,
    accountNumber: null,
    note: null,
    sortOrder: sortOrder,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

ExpenseEntity _savedExpense(ExpenseData data, {int? walletId}) {
  return ExpenseEntity(
    id: 7000 + data.amount.round(),
    amount: data.amount,
    category: data.category,
    description: data.description,
    date: data.parsedDate,
    walletId: walletId,
  );
}

class _TestWalletNotifier extends WalletNotifier {
  static List<WalletEntity> wallets = const [];

  @override
  Future<List<WalletEntity>> build() async {
    return wallets;
  }
}

class _FakeSmsPermissionHandler extends SmsPermissionHandler {
  _FakeSmsPermissionHandler({required this.status, this.requestedStatus});

  bool available = true;
  PermissionStatus status;
  PermissionStatus? requestedStatus;
  int requestCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<PermissionStatus> checkStatus() async => status;

  @override
  Future<bool> requestPermission() async {
    requestCalls++;
    status = requestedStatus ?? status;
    return status == PermissionStatus.granted;
  }
}

class _FakeSmsDuplicateDetector extends SmsDuplicateDetector {
  _FakeSmsDuplicateDetector({this.importedCount = 0, this.lastImportDate})
    : super(_StubIsar());

  int importedCount;
  DateTime? lastImportDate;
  final List<SmsMessage> markedSms = [];

  @override
  Future<int> getImportedCount() async => importedCount;

  @override
  Future<DateTime?> getLastImportDate() async => lastImportDate;

  @override
  String generateSignature(SmsMessage sms) => 'signature-${sms.id}';

  @override
  Future<void> markImported(
    SmsMessage sms, {
    int? expenseId,
    int? incomeId,
  }) async {
    markedSms.add(sms);
    importedCount++;
    if (lastImportDate == null || sms.date.isAfter(lastImportDate!)) {
      lastImportDate = sms.date;
    }
  }
}

class _FakeSmsImportOrchestrator extends SmsImportOrchestrator {
  _FakeSmsImportOrchestrator({required this.result})
    : super(
        reader: _FakeReader(const []),
        filter: _FakeFilter(const []),
        parser: _FakeParser(const []),
        categoryMapper: const SmsCategoryMapper(),
        walletMatcher: const SmsWalletMatcher(),
        duplicateDetector: _FakeSmsDuplicateDetector(),
      );

  SmsImportResult result;
  int scanCalls = 0;

  @override
  Future<SmsImportResult> scanForNewTransactions(
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) async {
    scanCalls++;
    return result;
  }
}

class _FakeExpenseMutationController extends ExpenseMutationController {
  _FakeExpenseMutationController() : super(_StubRef());

  final List<ExpenseData> savedExpenses = [];
  final List<int?> walletIds = [];
  String? nextError;

  @override
  Future<String?> saveDetectedExpense(
    ExpenseData expenseData, {
    int? walletId,
  }) async {
    savedExpenses.add(expenseData);
    walletIds.add(walletId);
    return nextError;
  }

  @override
  Future<DetectedExpenseSaveResult> saveDetectedExpenseDetailed(
    ExpenseData expenseData, {
    int? walletId,
  }) async {
    savedExpenses.add(expenseData);
    walletIds.add(walletId);
    if (nextError != null) {
      return DetectedExpenseSaveResult(error: nextError);
    }
    return DetectedExpenseSaveResult(
      expense: _savedExpense(expenseData, walletId: walletId),
    );
  }
}

class _FakeIncomeMutationController extends IncomeMutationController {
  _FakeIncomeMutationController() : super(_StubRef());

  final List<IncomeEntity> savedIncomes = [];
  final List<int?> walletIds = [];
  String? nextError;

  @override
  Future<String?> saveDetectedIncome(
    IncomeEntity income, {
    int? walletId,
  }) async {
    savedIncomes.add(income);
    walletIds.add(walletId);
    return nextError;
  }

  @override
  Future<DetectedIncomeSaveResult> saveDetectedIncomeDetailed(
    IncomeEntity income, {
    int? walletId,
  }) async {
    savedIncomes.add(income);
    walletIds.add(walletId);
    if (nextError != null) {
      return DetectedIncomeSaveResult(error: nextError);
    }
    return DetectedIncomeSaveResult(
      income: income.copyWith(
        id: 8000 + savedIncomes.length,
        walletId: walletId,
      ),
    );
  }
}

class _FakeReader extends SmsReaderService {
  _FakeReader(List<SmsMessage> messages)
    : _messages = messages,
      super(permissionHandler: const SmsPermissionHandler());

  final List<SmsMessage> _messages;

  @override
  Future<List<SmsMessage>> readSmsSince(DateTime since) async => _messages;
}

class _FakeSmsBackgroundListener extends SmsBackgroundListener {
  _FakeSmsBackgroundListener()
    : _controller = StreamController<SmsImportEntry>.broadcast(),
      super(
        filter: const SmsFilter(),
        parser: SmsParserEngine(),
        duplicateDetector: _FakeSmsDuplicateDetector(),
        categoryMapper: const SmsCategoryMapper(),
        walletMatcher: const SmsWalletMatcher(),
      );

  final StreamController<SmsImportEntry> _controller;
  List<SmsImportEntry> pollEntries = const [];
  int startCalls = 0;
  int stopCalls = 0;
  bool listening = false;

  @override
  Stream<SmsImportEntry> get onNewTransaction => _controller.stream;

  @override
  bool get isListening => listening;

  @override
  Future<void> startListening() async {
    startCalls++;
    listening = true;
  }

  @override
  Future<void> stopListening() async {
    stopCalls++;
    listening = false;
  }

  @override
  Future<List<SmsImportEntry>> pollNow() async {
    for (final entry in pollEntries) {
      _controller.add(entry);
    }
    return pollEntries;
  }

  @override
  void dispose() {
    _controller.close();
  }
}

class _FakeSmsLedgerService extends SmsLedgerService {
  _FakeSmsLedgerService({
    List<SmsLedgerEntryModel> entries = const [],
    this.lastSuccessfulSyncAt,
  }) : _entries = entries.map(_cloneEntry).toList(growable: true),
       super(
         isar: _StubIsar(),
         reader: _FakeReader(const []),
         filter: _FakeFilter(const []),
         parser: _FakeParser(const []),
         categoryMapper: const SmsCategoryMapper(),
         walletMatcher: const SmsWalletMatcher(),
       );

  final List<SmsLedgerEntryModel> _entries;
  final DateTime? lastSuccessfulSyncAt;
  final List<int> upsertedSmsIds = [];
  int syncCalls = 0;
  bool get initialBackfillComplete => true;

  @override
  Future<SmsLedgerStatusSnapshot> getStatusSnapshot() async {
    final importedCount = _entries.where((entry) => entry.isImported).length;
    final hiddenCount = _entries.where((entry) => entry.isIgnored).length;
    return SmsLedgerStatusSnapshot(
      ledgerCount: _entries.length,
      importedCount: importedCount,
      hiddenCount: hiddenCount,
      initialBackfillComplete: initialBackfillComplete,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
    );
  }

  @override
  Future<SmsLedgerSyncResult> syncLedger({
    int pageSize = 500,
    void Function(SmsLedgerSyncProgress progress)? onProgress,
  }) async {
    syncCalls++;
    onProgress?.call(
      SmsLedgerSyncProgress(
        isInitialBackfill: !initialBackfillComplete,
        batchIndex: 1,
        scannedMessages: _entries.length,
        financialMessages: _entries.length,
        parsedMessages: _entries.length,
        storedEntries: _entries.length,
      ),
    );
    return SmsLedgerSyncResult(
      isInitialBackfill: !initialBackfillComplete,
      scannedMessages: _entries.length,
      financialMessages: _entries.length,
      parsedMessages: _entries.length,
      unparsedFinancialMessages: 0,
      insertedEntries: _entries.length,
      updatedEntries: 0,
      batchCount: 1,
      startedAt: DateTime(2026, 4, 20, 10),
      completedAt: lastSuccessfulSyncAt ?? DateTime(2026, 4, 20, 10),
    );
  }

  @override
  Future<List<SmsLedgerEntryModel>> loadEntries() async {
    final entries = _entries.map(_cloneEntry).toList(growable: false);
    entries.sort(
      (first, second) => second.occurredAt.compareTo(first.occurredAt),
    );
    return entries;
  }

  @override
  Future<SmsLedgerOverview> buildOverview(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final visibleEntries = _entries.where((entry) => !entry.isIgnored).toList();
    final monthEntries = visibleEntries
        .where(
          (entry) =>
              entry.occurredAt.year == normalizedMonth.year &&
              entry.occurredAt.month == normalizedMonth.month,
        )
        .toList(growable: false);
    final kindTotals = _buildKindTotals(monthEntries);
    final sourceTotals = _buildSourceTotals(monthEntries);
    final monthlyOutflow = _sumKinds(monthEntries, const {
      ParsedTransactionKind.payment,
      ParsedTransactionKind.sendMoney,
      ParsedTransactionKind.cashOut,
      ParsedTransactionKind.bankDebit,
      ParsedTransactionKind.billPay,
      ParsedTransactionKind.atmWithdrawal,
      ParsedTransactionKind.cardPurchase,
    });
    final monthlyInflow = _sumKinds(monthEntries, const {
      ParsedTransactionKind.receivedMoney,
      ParsedTransactionKind.bankCredit,
    });
    final monthlyTransfer = _sumKinds(monthEntries, const {
      ParsedTransactionKind.cashIn,
      ParsedTransactionKind.addMoney,
      ParsedTransactionKind.transfer,
    });

    return SmsLedgerOverview(
      selectedMonth: normalizedMonth,
      totalEntries: _entries.length,
      visibleEntries: visibleEntries.length,
      importedEntries: visibleEntries.where((entry) => entry.isImported).length,
      hiddenEntries: _entries.where((entry) => entry.isIgnored).length,
      monthlyActivityTotal: monthlyOutflow + monthlyInflow + monthlyTransfer,
      monthlyOutflow: monthlyOutflow,
      monthlyInflow: monthlyInflow,
      monthlyTransfer: monthlyTransfer,
      allTimeActivityTotal: visibleEntries.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      ),
      kindTotals: kindTotals,
      sourceTotals: sourceTotals,
      trendPoints: [
        for (var offset = 5; offset >= 0; offset--)
          SmsLedgerMonthlyTrendPoint(
            month: DateTime(
              normalizedMonth.year,
              normalizedMonth.month - offset,
            ),
            activityTotal: offset == 0
                ? monthEntries.fold<double>(
                    0,
                    (sum, entry) => sum + entry.amount,
                  )
                : 0,
            outflow: offset == 0 ? monthlyOutflow : 0,
            inflow: offset == 0 ? monthlyInflow : 0,
            transfer: offset == 0 ? monthlyTransfer : 0,
            count: offset == 0 ? monthEntries.length : 0,
          ),
      ],
      lastSuccessfulSyncAt: lastSuccessfulSyncAt,
      initialBackfillComplete: initialBackfillComplete,
    );
  }

  @override
  Future<void> setIgnored(int entryId, bool ignored) async {
    final entry = _entries.firstWhere((item) => item.id == entryId);
    entry.isIgnored = ignored;
  }

  @override
  Future<void> upsertCandidate(
    SmsImportCandidate candidate, {
    bool isImported = false,
    DateTime? importedAt,
  }) async {
    upsertedSmsIds.add(candidate.sms.id);
    for (final entry in _entries) {
      if (entry.smsId == candidate.sms.id) {
        entry.isImported = isImported;
        entry.importedAt = importedAt;
      }
    }
  }

  @override
  SmsImportCandidate buildImportCandidate(
    SmsLedgerEntryModel entry,
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) {
    final wallet =
        defaultWallet ??
        wallets.firstWhere((item) => item.id == 2, orElse: () => wallets.first);
    return SmsImportCandidate(
      sms: entry.toSmsMessage(),
      transaction: entry.toParsedTransaction(),
      suggestedWallet: wallet,
      suggestedCategory: entry.isExpenseLike ? 'Food' : null,
      suggestedIncomeSource: entry.isIncomeLike ? 'Salary' : null,
    );
  }
}

class _FakeFilter extends SmsFilter {
  const _FakeFilter(this._messages);

  final List<SmsMessage> _messages;

  @override
  List<SmsMessage> filterFinancialSms(List<SmsMessage> input) => _messages;
}

class _FakeParser extends SmsParserEngine {
  _FakeParser(this._transactions);

  final List<ParsedTransaction> _transactions;

  @override
  List<ParsedTransaction> parseAll(List<SmsMessage> messages) => _transactions;
}

class _StubIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _StubRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

SmsLedgerEntryModel _ledgerEntry({
  required int id,
  required int smsId,
  ParsedTransactionSource source = ParsedTransactionSource.bkash,
  ParsedTransactionKind kind = ParsedTransactionKind.payment,
  TransactionType type = TransactionType.expense,
  String counterparty = 'Merchant',
  double amount = 120,
  DateTime? occurredAt,
  bool isIgnored = false,
  bool isImported = false,
}) {
  final timestamp = occurredAt ?? DateTime(2026, 4, 18, 13, 45);
  final entry = SmsLedgerEntryModel()
    ..id = id
    ..signature = 'sig-$id'
    ..smsId = smsId
    ..sender = source.label
    ..rawMessage = '$counterparty $amount'
    ..source = source
    ..direction = type == TransactionType.income
        ? ParsedTransactionDirection.credit
        : ParsedTransactionDirection.debit
    ..kind = kind
    ..type = type
    ..amount = amount
    ..counterparty = counterparty
    ..occurredAt = timestamp
    ..receivedAt = timestamp
    ..isIgnored = isIgnored
    ..isImported = isImported
    ..createdAt = timestamp
    ..updatedAt = timestamp;
  return entry;
}

SmsLedgerEntryModel _cloneEntry(SmsLedgerEntryModel entry) {
  final clone = SmsLedgerEntryModel()
    ..id = entry.id
    ..signature = entry.signature
    ..smsId = entry.smsId
    ..sender = entry.sender
    ..rawMessage = entry.rawMessage
    ..source = entry.source
    ..direction = entry.direction
    ..kind = entry.kind
    ..type = entry.type
    ..amount = entry.amount
    ..fee = entry.fee
    ..balanceAfter = entry.balanceAfter
    ..reference = entry.reference
    ..counterparty = entry.counterparty
    ..merchantName = entry.merchantName
    ..accountMask = entry.accountMask
    ..rawCategory = entry.rawCategory
    ..confidence = entry.confidence
    ..occurredAt = entry.occurredAt
    ..receivedAt = entry.receivedAt
    ..isImported = entry.isImported
    ..importedAt = entry.importedAt
    ..isIgnored = entry.isIgnored
    ..ignoredAt = entry.ignoredAt
    ..createdAt = entry.createdAt
    ..updatedAt = entry.updatedAt;
  return clone;
}

double _sumKinds(
  List<SmsLedgerEntryModel> entries,
  Set<ParsedTransactionKind> kinds,
) {
  return entries.fold<double>(
    0,
    (sum, entry) => sum + (kinds.contains(entry.kind) ? entry.amount : 0),
  );
}

List<SmsLedgerKindTotal> _buildKindTotals(List<SmsLedgerEntryModel> entries) {
  final buckets = <ParsedTransactionKind, SmsLedgerKindTotal>{};
  for (final entry in entries) {
    final current = buckets[entry.kind];
    buckets[entry.kind] = SmsLedgerKindTotal(
      kind: entry.kind,
      amount: (current?.amount ?? 0) + entry.amount,
      count: (current?.count ?? 0) + 1,
    );
  }
  return buckets.values.toList(growable: false);
}

List<SmsLedgerSourceTotal> _buildSourceTotals(
  List<SmsLedgerEntryModel> entries,
) {
  final buckets = <ParsedTransactionSource, SmsLedgerSourceTotal>{};
  for (final entry in entries) {
    final current = buckets[entry.source];
    buckets[entry.source] = SmsLedgerSourceTotal(
      source: entry.source,
      amount: (current?.amount ?? 0) + entry.amount,
      count: (current?.count ?? 0) + 1,
    );
  }
  return buckets.values.toList(growable: false);
}
