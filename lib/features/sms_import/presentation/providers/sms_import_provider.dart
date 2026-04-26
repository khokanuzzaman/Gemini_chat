import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_background_listener.dart';
import '../../../../core/sms/sms_category_mapper.dart';
import '../../../../core/sms/sms_duplicate_detector.dart';
import '../../../../core/sms/sms_filter.dart';
import '../../../../core/sms/sms_import_entry.dart';
import '../../../../core/sms/sms_import_orchestrator.dart';
import '../../../../core/sms/sms_import_result.dart';
import '../../../../core/sms/sms_ledger_service.dart';
import '../../../../core/sms/sms_parser.dart';
import '../../../../core/sms/sms_permission_handler.dart';
import '../../../../core/sms/sms_reader_service.dart';
import '../../../../core/sms/sms_settings.dart';
import '../../../../core/sms/sms_wallet_matcher.dart';
import '../../../expense/presentation/providers/expense_providers.dart';
import '../../../income/presentation/providers/income_providers.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../models/sms_import_models.dart';

final smsPermissionHandlerProvider = Provider<SmsPermissionHandler>((ref) {
  return const SmsPermissionHandler();
});

final smsReaderServiceProvider = Provider<SmsReaderService>((ref) {
  return SmsReaderService(
    permissionHandler: ref.watch(smsPermissionHandlerProvider),
  );
});

final smsFilterProvider = Provider<SmsFilter>((ref) {
  return const SmsFilter();
});

final smsParserEngineProvider = Provider<SmsParserEngine>((ref) {
  return SmsParserEngine();
});

final smsCategoryMapperProvider = Provider<SmsCategoryMapper>((ref) {
  return const SmsCategoryMapper();
});

final smsWalletMatcherProvider = Provider<SmsWalletMatcher>((ref) {
  return const SmsWalletMatcher();
});

final smsDuplicateDetectorProvider = Provider<SmsDuplicateDetector>((ref) {
  return SmsDuplicateDetector(ref.watch(isarProvider));
});

final smsSettingsProvider = Provider<SmsSettings>((ref) {
  return SmsSettings(ref.watch(sharedPreferencesProvider));
});

final smsImportOrchestratorProvider = Provider<SmsImportOrchestrator>((ref) {
  return SmsImportOrchestrator(
    reader: ref.watch(smsReaderServiceProvider),
    filter: ref.watch(smsFilterProvider),
    parser: ref.watch(smsParserEngineProvider),
    categoryMapper: ref.watch(smsCategoryMapperProvider),
    walletMatcher: ref.watch(smsWalletMatcherProvider),
    duplicateDetector: ref.watch(smsDuplicateDetectorProvider),
  );
});

final smsLedgerServiceProvider = Provider<SmsLedgerService>((ref) {
  return SmsLedgerService(
    isar: ref.watch(isarProvider),
    reader: ref.watch(smsReaderServiceProvider),
    filter: ref.watch(smsFilterProvider),
    parser: ref.watch(smsParserEngineProvider),
    categoryMapper: ref.watch(smsCategoryMapperProvider),
    walletMatcher: ref.watch(smsWalletMatcherProvider),
  );
});

final smsBackgroundListenerProvider = Provider<SmsBackgroundListener>((ref) {
  final listener = SmsBackgroundListener(
    reader: ref.watch(smsReaderServiceProvider),
    permissionHandler: ref.watch(smsPermissionHandlerProvider),
    settings: ref.watch(smsSettingsProvider),
    filter: ref.watch(smsFilterProvider),
    parser: ref.watch(smsParserEngineProvider),
    duplicateDetector: ref.watch(smsDuplicateDetectorProvider),
    categoryMapper: ref.watch(smsCategoryMapperProvider),
    walletMatcher: ref.watch(smsWalletMatcherProvider),
    walletLoader: () => ref.read(walletProvider.future),
    defaultWalletReader: () => ref.read(activeWalletProvider),
  );
  ref.onDispose(listener.dispose);
  return listener;
});

final smsImportStatusRefreshTokenProvider = StateProvider<int>((ref) => 0);

final smsImportStatusProvider = FutureProvider<SmsImportStatus>((ref) async {
  ref.watch(smsImportStatusRefreshTokenProvider);
  final permissionHandler = ref.watch(smsPermissionHandlerProvider);
  final smsSettings = ref.watch(smsSettingsProvider);
  final ledgerSnapshot = await ref.watch(smsLedgerServiceProvider).getStatusSnapshot();
  return SmsImportStatus(
    permissionState: await _resolvePermissionState(permissionHandler),
    importedCount: smsSettings.getImportedCount(),
    lastImportDate: await ref.watch(smsDuplicateDetectorProvider).getLastImportDate(),
    ledgerCount: ledgerSnapshot.ledgerCount,
    lastLedgerSyncAt: ledgerSnapshot.lastSuccessfulSyncAt,
    initialLedgerSyncComplete: ledgerSnapshot.initialBackfillComplete,
  );
});

final smsImportPersistenceProvider = Provider<SmsImportPersistence>((ref) {
  return SmsImportPersistence(ref);
});

final smsImportControllerProvider =
    NotifierProvider<SmsImportController, SmsImportScreenState>(
      SmsImportController.new,
    );

final smsAutoImportProvider =
    NotifierProvider<SmsAutoImportNotifier, SmsAutoImportState>(
      SmsAutoImportNotifier.new,
    );

class SmsImportController extends Notifier<SmsImportScreenState> {
  @override
  SmsImportScreenState build() {
    Future<void>.microtask(() => refreshStatus(showLoading: true));
    return SmsImportScreenState.initial();
  }

  Future<void> refreshStatus({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isStatusLoading: true, errorMessage: null);
    }

    final permissionHandler = ref.read(smsPermissionHandlerProvider);
    final smsSettings = ref.read(smsSettingsProvider);
    final permissionState = await _resolvePermissionState(permissionHandler);
    final importedCount = smsSettings.getImportedCount();
    final lastImportDate = await ref
        .read(smsDuplicateDetectorProvider)
        .getLastImportDate();

    state = state.copyWith(
      permissionState: permissionState,
      importedCount: importedCount,
      lastImportDate: lastImportDate,
      isStatusLoading: false,
      errorMessage: null,
    );
  }

  Future<void> requestPermission() async {
    final permissionHandler = ref.read(smsPermissionHandlerProvider);
    state = state.copyWith(isStatusLoading: true, errorMessage: null);
    await permissionHandler.requestPermission();
    _bumpStatusRefresh();
    await refreshStatus();
  }

  Future<void> scanForNewTransactions() async {
    if (state.isScanning || state.isImporting) {
      return;
    }

    final currentPermission = await _resolvePermissionState(
      ref.read(smsPermissionHandlerProvider),
    );
    if (!currentPermission.isGranted) {
      state = state.copyWith(
        permissionState: currentPermission,
        isStatusLoading: false,
      );
      return;
    }

    state = state.copyWith(
      isScanning: true,
      scanAttempted: true,
      errorMessage: null,
      rowErrors: const {},
      activeTab: SmsImportTabFilter.all,
    );

    try {
      final wallets = await ref.read(walletProvider.future);
      final defaultWallet = ref.read(activeWalletProvider);
      final result = await ref
          .read(smsImportOrchestratorProvider)
          .scanForNewTransactions(wallets, defaultWallet: defaultWallet);

      final candidates = result.candidates
          .where((candidate) => candidate.isExpense || candidate.isIncome)
          .toList(growable: false);
      final drafts = {
        for (final candidate in candidates)
          candidate.sms.id: SmsImportDraft.fromCandidate(candidate),
      };
      final selectedIds = candidates
          .map((candidate) => candidate.sms.id)
          .toSet();

      state = state.copyWith(
        isScanning: false,
        latestScanResult: _withCandidates(result, candidates),
        candidates: candidates,
        drafts: drafts,
        selectedIds: selectedIds,
        lastScanReadyCount: candidates.length,
        rowErrors: const {},
        activeTab: SmsImportTabFilter.all,
      );
      _bumpStatusRefresh();
      await refreshStatus();
    } on PermissionDeniedException {
      await refreshStatus();
      state = state.copyWith(isScanning: false);
    } catch (error) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'SMS স্ক্যান করা যায়নি: $error',
      );
    }
  }

  void setTab(SmsImportTabFilter tab) {
    state = state.copyWith(activeTab: tab);
  }

  void toggleCandidate(int candidateId, bool selected) {
    final nextSelected = {...state.selectedIds};
    if (selected) {
      nextSelected.add(candidateId);
    } else {
      nextSelected.remove(candidateId);
    }
    state = state.copyWith(selectedIds: nextSelected);
  }

  void selectAllVisible() {
    final nextSelected = {...state.selectedIds};
    for (final candidate in state.filteredCandidates) {
      nextSelected.add(candidate.sms.id);
    }
    state = state.copyWith(selectedIds: nextSelected);
  }

  void clearVisibleSelection() {
    final filteredIds = state.filteredCandidates
        .map((candidate) => candidate.sms.id)
        .toSet();
    final nextSelected = {
      for (final id in state.selectedIds)
        if (!filteredIds.contains(id)) id,
    };
    state = state.copyWith(selectedIds: nextSelected);
  }

  void updateDraft(SmsImportDraft draft) {
    final nextDrafts = {...state.drafts, draft.candidateId: draft};
    final nextErrors = {...state.rowErrors}..remove(draft.candidateId);
    state = state.copyWith(drafts: nextDrafts, rowErrors: nextErrors);
  }

  Future<SmsImportBatchOutcome> importSelected() async {
    if (state.isImporting || state.selectedIds.isEmpty) {
      return const SmsImportBatchOutcome(
        importedCount: 0,
        failedCount: 0,
        skippedCount: 0,
      );
    }

    state = state.copyWith(isImporting: true, errorMessage: null);

    final candidatesById = {
      for (final candidate in state.candidates) candidate.sms.id: candidate,
    };
    final rowErrors = <int, String>{};
    final importedIds = <int>{};
    var importedCount = 0;
    var failedCount = 0;
    var skippedCount = 0;

    final selectedIds = state.selectedIds.toList(growable: false);
    for (final candidateId in selectedIds) {
      final candidate = candidatesById[candidateId];
      final draft = state.drafts[candidateId];
      if (candidate == null || draft == null) {
        skippedCount++;
        continue;
      }

      final saveError = await ref
          .read(smsImportPersistenceProvider)
          .importCandidate(candidate: candidate, draft: draft);
      if (saveError != null) {
        rowErrors[candidateId] = saveError;
        failedCount++;
        continue;
      }
      importedIds.add(candidateId);
      importedCount++;
    }

    final remainingCandidates = [
      for (final candidate in state.candidates)
        if (!importedIds.contains(candidate.sms.id)) candidate,
    ];
    final remainingDrafts = {
      for (final entry in state.drafts.entries)
        if (!importedIds.contains(entry.key)) entry.key: entry.value,
    };
    final remainingSelected = {
      for (final id in state.selectedIds)
        if (!importedIds.contains(id)) id,
    };

    state = state.copyWith(
      isImporting: false,
      candidates: remainingCandidates,
      drafts: remainingDrafts,
      selectedIds: remainingSelected,
      rowErrors: rowErrors,
      latestScanResult: _replaceLatestCandidates(remainingCandidates),
    );

    if (importedCount > 0) {
      _bumpStatusRefresh();
      await refreshStatus();
    }

    return SmsImportBatchOutcome(
      importedCount: importedCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
    );
  }

  SmsImportResult _replaceLatestCandidates(
    List<SmsImportCandidate> candidates,
  ) {
    final current = state.latestScanResult;
    if (current == null) {
      return SmsImportResult(
        since: DateTime.now(),
        scannedMessages: const [],
        financialMessages: const [],
        parsedTransactions: const [],
        candidates: candidates,
        duplicateCount: 0,
      );
    }

    return _withCandidates(current, candidates);
  }

  SmsImportResult _withCandidates(
    SmsImportResult result,
    List<SmsImportCandidate> candidates,
  ) {
    return SmsImportResult(
      since: result.since,
      scannedMessages: result.scannedMessages,
      financialMessages: result.financialMessages,
      parsedTransactions: result.parsedTransactions,
      candidates: candidates,
      duplicateCount: result.duplicateCount,
    );
  }

  void _bumpStatusRefresh() {
    ref.read(smsImportStatusRefreshTokenProvider.notifier).state++;
  }
}

class SmsAutoImportNotifier extends Notifier<SmsAutoImportState> {
  StreamSubscription<SmsImportEntry>? _listenerSubscription;

  @override
  SmsAutoImportState build() {
    final listener = ref.read(smsBackgroundListenerProvider);
    _listenerSubscription ??= listener.onNewTransaction.listen((entry) {
      unawaited(_handleNewTransaction(entry));
    });
    ref.onDispose(() async {
      await _listenerSubscription?.cancel();
      _listenerSubscription = null;
    });
    Future<void>.microtask(_initialize);
    return SmsAutoImportState.initial();
  }

  Future<void> _initialize() async {
    final permissionState = await _resolvePermissionState(
      ref.read(smsPermissionHandlerProvider),
    );
    final settings = ref.read(smsSettingsProvider);
    final enabled = settings.isAutoImportEnabled();
    final shouldListen = enabled && permissionState.isGranted;
    if (shouldListen) {
      await ref.read(smsBackgroundListenerProvider).startListening();
    }

    state = state.copyWith(
      permissionState: permissionState,
      isEnabled: enabled,
      isListening: ref.read(smsBackgroundListenerProvider).isListening,
      autoConfirm: settings.isAutoConfirmEnabled(),
      importedCount: settings.getImportedCount(),
      enabledSources: settings.getEnabledSources(),
      lastScanTime: settings.getLastScanTime(),
      isBusy: false,
      isRescanning: false,
      errorMessage: null,
    );
  }

  Future<void> enable() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    final permissionHandler = ref.read(smsPermissionHandlerProvider);
    var permissionState = await _resolvePermissionState(permissionHandler);
    if (!permissionState.isGranted &&
        permissionState != SmsPermissionState.unsupported) {
      await permissionHandler.requestPermission();
      permissionState = await _resolvePermissionState(permissionHandler);
    }

    if (!permissionState.isGranted) {
      state = state.copyWith(
        permissionState: permissionState,
        isEnabled: false,
        isListening: false,
        isBusy: false,
      );
      return;
    }

    final settings = ref.read(smsSettingsProvider);
    await settings.setAutoImportEnabled(true);
    await ref.read(smsBackgroundListenerProvider).startListening();
    state = state.copyWith(
      permissionState: permissionState,
      isEnabled: true,
      isListening: ref.read(smsBackgroundListenerProvider).isListening,
      lastScanTime: settings.getLastScanTime(),
      isBusy: false,
    );
  }

  Future<void> disable() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    await ref.read(smsSettingsProvider).setAutoImportEnabled(false);
    await ref.read(smsBackgroundListenerProvider).stopListening();
    state = state.copyWith(
      isEnabled: false,
      isListening: false,
      isBusy: false,
    );
  }

  Future<void> toggleAutoConfirm() async {
    final nextValue = !state.autoConfirm;
    await ref.read(smsSettingsProvider).setAutoConfirmEnabled(nextValue);
    state = state.copyWith(autoConfirm: nextValue);
  }

  Future<void> toggleSource(String source) async {
    final normalized = source.trim();
    final nextSources = [...state.enabledSources];
    if (nextSources.contains(normalized)) {
      nextSources.remove(normalized);
    } else {
      nextSources.add(normalized);
    }
    await ref.read(smsSettingsProvider).setEnabledSources(nextSources);
    state = state.copyWith(enabledSources: nextSources);
  }

  Future<String?> confirmAndSave(
    SmsImportEntry entry, {
    SmsImportDraft? draft,
  }) async {
    final resolvedDraft =
        draft ?? SmsImportDraft.fromCandidate(entry.toCandidate());
    final error = await ref.read(smsImportPersistenceProvider).importCandidate(
          candidate: entry.toCandidate(),
          draft: resolvedDraft,
        );
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return error;
    }

    state = state.copyWith(
      pendingTransactions: [
        for (final pending in state.pendingTransactions)
          if (pending.signature != entry.signature) pending,
      ],
      importedCount: ref.read(smsSettingsProvider).getImportedCount(),
      errorMessage: null,
    );
    _bumpStatusRefresh();
    return null;
  }

  Future<SmsImportBatchOutcome> confirmAndSaveAll() async {
    if (state.pendingTransactions.isEmpty) {
      return const SmsImportBatchOutcome(
        importedCount: 0,
        failedCount: 0,
        skippedCount: 0,
      );
    }

    state = state.copyWith(isBusy: true, errorMessage: null);
    var importedCount = 0;
    var failedCount = 0;
    for (final entry in List<SmsImportEntry>.from(state.pendingTransactions)) {
      final error = await confirmAndSave(entry);
      if (error == null) {
        importedCount++;
      } else {
        failedCount++;
      }
    }
    state = state.copyWith(isBusy: false);
    return SmsImportBatchOutcome(
      importedCount: importedCount,
      failedCount: failedCount,
      skippedCount: 0,
    );
  }

  Future<void> dismissEntry(SmsImportEntry entry) async {
    await _markPendingDismissed(entry);
    state = state.copyWith(
      pendingTransactions: [
        for (final pending in state.pendingTransactions)
          if (pending.signature != entry.signature) pending,
      ],
      errorMessage: null,
    );
    _bumpStatusRefresh();
  }

  Future<void> dismissAll() async {
    for (final entry in List<SmsImportEntry>.from(state.pendingTransactions)) {
      await _markPendingDismissed(entry);
    }
    state = state.copyWith(pendingTransactions: const [], errorMessage: null);
    _bumpStatusRefresh();
  }

  Future<void> rescan() async {
    if (state.isRescanning) {
      return;
    }
    state = state.copyWith(isRescanning: true, errorMessage: null);
    await ref.read(smsBackgroundListenerProvider).pollNow();
    state = state.copyWith(
      lastScanTime: ref.read(smsSettingsProvider).getLastScanTime(),
      isRescanning: false,
      isListening: ref.read(smsBackgroundListenerProvider).isListening,
    );
  }

  Future<void> handleAppBackgrounded() async {
    if (!state.isEnabled) {
      return;
    }
    await ref.read(smsBackgroundListenerProvider).stopListening();
    state = state.copyWith(isListening: false);
  }

  Future<void> handleAppResumed() async {
    final permissionState = await _resolvePermissionState(
      ref.read(smsPermissionHandlerProvider),
    );
    if (!state.isEnabled || !permissionState.isGranted) {
      state = state.copyWith(
        permissionState: permissionState,
        isListening: false,
      );
      return;
    }

    await ref.read(smsBackgroundListenerProvider).startListening();
    await ref.read(smsBackgroundListenerProvider).pollNow();
    state = state.copyWith(
      permissionState: permissionState,
      isListening: ref.read(smsBackgroundListenerProvider).isListening,
      lastScanTime: ref.read(smsSettingsProvider).getLastScanTime(),
    );
  }

  Future<void> _handleNewTransaction(SmsImportEntry entry) async {
    if (state.pendingTransactions.any(
      (pending) => pending.signature == entry.signature,
    )) {
      return;
    }

    state = state.copyWith(lastScanTime: ref.read(smsSettingsProvider).getLastScanTime());
    if (state.autoConfirm) {
      final error = await confirmAndSave(entry);
      if (error == null) {
        await NotificationService.showSmsAutoSaved(entry);
      }
      return;
    }

    final nextPending = [entry, ...state.pendingTransactions]
      ..sort(
        (first, second) =>
            second.transaction.occurredAt.compareTo(first.transaction.occurredAt),
      );
    state = state.copyWith(pendingTransactions: nextPending, errorMessage: null);
    await NotificationService.showSmsImportDetected(entry);
  }

  Future<void> _markPendingDismissed(SmsImportEntry entry) async {
    final importedAt = DateTime.now();
    await ref.read(smsDuplicateDetectorProvider).markImported(entry.sms);
    await ref.read(smsLedgerServiceProvider).upsertCandidate(
          entry.toCandidate(),
          isImported: true,
          importedAt: importedAt,
        );
  }

  void _bumpStatusRefresh() {
    ref.read(smsImportStatusRefreshTokenProvider.notifier).state++;
  }
}

class SmsImportPersistence {
  const SmsImportPersistence(this._ref);

  final Ref _ref;

  Future<String?> importCandidate({
    required SmsImportCandidate candidate,
    required SmsImportDraft draft,
  }) async {
    final saveResult = await _saveDraft(draft);
    if (saveResult.error != null) {
      return saveResult.error;
    }

    final importedAt = DateTime.now();
    try {
      await _ref.read(smsDuplicateDetectorProvider).markImported(
            candidate.sms,
            expenseId: saveResult.expenseId,
            incomeId: saveResult.incomeId,
          );
      await _ref.read(smsLedgerServiceProvider).upsertCandidate(
            candidate,
            isImported: true,
            importedAt: importedAt,
          );
      await _ref.read(smsSettingsProvider).incrementImportedCount();
      return null;
    } catch (_) {
      return 'লেনদেন সংরক্ষণ হয়েছে, কিন্তু SMS status update ব্যর্থ হয়েছে';
    }
  }

  Future<_SmsPersistResult> _saveDraft(SmsImportDraft draft) async {
    if (draft.amount <= 0) {
      return const _SmsPersistResult(error: 'সঠিক পরিমাণ লিখুন');
    }

    switch (draft.type) {
      case TransactionType.expense:
        final result = await _ref
            .read(expenseMutationControllerProvider)
            .saveDetectedExpenseDetailed(
              draft.toExpenseData(),
              walletId: draft.walletId,
            );
        return _SmsPersistResult(
          expenseId: result.expense?.id,
          error: result.error,
        );
      case TransactionType.income:
        final result = await _ref
            .read(incomeMutationControllerProvider)
            .saveDetectedIncomeDetailed(
              draft.toIncomeEntity(),
              walletId: draft.walletId,
            );
        return _SmsPersistResult(
          incomeId: result.income?.id,
          error: result.error,
        );
      default:
        return const _SmsPersistResult(error: 'এই SMS টি ইমপোর্ট করা যাচ্ছে না');
    }
  }
}

class _SmsPersistResult {
  const _SmsPersistResult({this.expenseId, this.incomeId, this.error});

  final int? expenseId;
  final int? incomeId;
  final String? error;
}

Future<SmsPermissionState> _resolvePermissionState(
  SmsPermissionHandler handler,
) async {
  final isAvailable = await handler.isAvailable();
  if (!isAvailable) {
    return SmsPermissionState.unsupported;
  }

  final status = await handler.checkStatus();
  if (status == PermissionStatus.granted) {
    return SmsPermissionState.granted;
  }
  if (status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted) {
    return SmsPermissionState.permanentlyDenied;
  }
  return SmsPermissionState.denied;
}
