import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/database/models/sms_ledger_entry_model.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_import_result.dart';
import '../../../../core/sms/sms_ledger_models.dart';
import '../../../../core/sms/sms_permission_handler.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../domain/entities/sms_permission_state.dart';
import '../models/sms_history_models.dart';
import '../models/sms_import_models.dart';
import 'sms_import_provider.dart';

final smsHistoryControllerProvider =
    NotifierProvider<SmsHistoryController, SmsHistoryScreenState>(
      SmsHistoryController.new,
    );

class SmsHistoryController extends Notifier<SmsHistoryScreenState> {
  @override
  SmsHistoryScreenState build() {
    Future<void>.microtask(() => loadOnOpen());
    return SmsHistoryScreenState.initial();
  }

  Future<void> loadOnOpen() async {
    await refresh(showLoading: true, sync: true);
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await ref.read(smsPermissionHandlerProvider).requestPermission();
    _bumpSmsStatusRefresh();
    await refresh(showLoading: true, sync: true);
  }

  Future<void> refresh({
    bool showLoading = false,
    bool sync = false,
  }) async {
    if (showLoading) {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );
    }

    final permissionState = await _resolveSmsPermissionState(
      ref.read(smsPermissionHandlerProvider),
    );
    state = state.copyWith(permissionState: permissionState, errorMessage: null);

    if (!permissionState.isGranted) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        entries: const [],
        overview: null,
        syncProgress: null,
      );
      return;
    }

    if (sync) {
      await syncLedger(showLoading: showLoading);
      return;
    }

    await _loadData();
  }

  Future<void> syncLedger({bool showLoading = false}) async {
    if (state.isSyncing) {
      return;
    }

    final permissionState = await _resolveSmsPermissionState(
      ref.read(smsPermissionHandlerProvider),
    );
    if (!permissionState.isGranted) {
      state = state.copyWith(
        permissionState: permissionState,
        isLoading: false,
        isSyncing: false,
      );
      return;
    }

    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    state = state.copyWith(
      isSyncing: true,
      syncProgress: null,
      errorMessage: null,
    );

    try {
      final result = await ref.read(smsLedgerServiceProvider).syncLedger(
        onProgress: (progress) {
          state = state.copyWith(syncProgress: progress);
        },
      );
      _bumpSmsStatusRefresh();
      await _loadData(lastSyncResult: result);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isSyncing: false,
        syncProgress: null,
        errorMessage: 'SMS history sync করা যায়নি: $error',
      );
    }
  }

  Future<void> previousMonth() async {
    final nextMonth = DateTime(
      state.selectedMonth.year,
      state.selectedMonth.month - 1,
    );
    state = state.copyWith(selectedMonth: nextMonth, isLoading: true);
    await _loadData();
  }

  Future<void> nextMonth() async {
    final nextMonth = DateTime(
      state.selectedMonth.year,
      state.selectedMonth.month + 1,
    );
    state = state.copyWith(selectedMonth: nextMonth, isLoading: true);
    await _loadData();
  }

  void setTab(SmsHistoryTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setStatusFilter(SmsHistoryStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setSourceFilter(ParsedTransactionSource? filter) {
    state = state.copyWith(sourceFilter: filter);
  }

  void setKindFilter(ParsedTransactionKind? filter) {
    state = state.copyWith(kindFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> toggleIgnored(SmsLedgerEntryModel entry) async {
    await ref.read(smsLedgerServiceProvider).setIgnored(
          entry.id,
          !entry.isIgnored,
        );
    _bumpSmsStatusRefresh();
    await _loadData();
  }

  Future<SmsImportCandidate> buildImportCandidate(
    SmsLedgerEntryModel entry,
  ) async {
    final wallets = await ref.read(walletProvider.future);
    final defaultWallet = ref.read(activeWalletProvider);
    return ref.read(smsLedgerServiceProvider).buildImportCandidate(
          entry,
          wallets,
          defaultWallet: defaultWallet,
        );
  }

  Future<String?> importEntry({
    required SmsLedgerEntryModel entry,
    required SmsImportDraft draft,
  }) async {
    final candidate = await buildImportCandidate(entry);
    final error = await ref
        .read(smsImportPersistenceProvider)
        .importCandidate(candidate: candidate, draft: draft);
    if (error != null) {
      return error;
    }

    _bumpSmsStatusRefresh();
    await _loadData();
    return null;
  }

  Future<void> _loadData({SmsLedgerSyncResult? lastSyncResult}) async {
    final entries = await ref.read(smsLedgerServiceProvider).loadEntries();
    final overview = await ref
        .read(smsLedgerServiceProvider)
        .buildOverview(state.selectedMonth);
    state = state.copyWith(
      isLoading: false,
      isSyncing: false,
      entries: entries,
      overview: overview,
      syncProgress: null,
      lastSyncResult: lastSyncResult ?? state.lastSyncResult,
      errorMessage: null,
    );
  }

  void _bumpSmsStatusRefresh() {
    ref.read(smsImportStatusRefreshTokenProvider.notifier).state++;
  }
}

Future<SmsPermissionState> _resolveSmsPermissionState(
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
