import '../../../../core/database/models/sms_ledger_entry_model.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_ledger_models.dart';
import '../../domain/entities/sms_permission_state.dart';

enum SmsHistoryTab { summary, history }

enum SmsHistoryStatusFilter { all, imported, notImported, hidden }

class SmsHistoryScreenState {
  const SmsHistoryScreenState({
    required this.permissionState,
    required this.isLoading,
    required this.isSyncing,
    required this.activeTab,
    required this.selectedMonth,
    required this.statusFilter,
    required this.sourceFilter,
    required this.kindFilter,
    required this.searchQuery,
    required this.entries,
    required this.overview,
    required this.syncProgress,
    required this.lastSyncResult,
    this.errorMessage,
  });

  factory SmsHistoryScreenState.initial() {
    final now = DateTime.now();
    return SmsHistoryScreenState(
      permissionState: SmsPermissionState.denied,
      isLoading: true,
      isSyncing: false,
      activeTab: SmsHistoryTab.summary,
      selectedMonth: DateTime(now.year, now.month),
      statusFilter: SmsHistoryStatusFilter.all,
      sourceFilter: null,
      kindFilter: null,
      searchQuery: '',
      entries: const [],
      overview: null,
      syncProgress: null,
      lastSyncResult: null,
    );
  }

  final SmsPermissionState permissionState;
  final bool isLoading;
  final bool isSyncing;
  final SmsHistoryTab activeTab;
  final DateTime selectedMonth;
  final SmsHistoryStatusFilter statusFilter;
  final ParsedTransactionSource? sourceFilter;
  final ParsedTransactionKind? kindFilter;
  final String searchQuery;
  final List<SmsLedgerEntryModel> entries;
  final SmsLedgerOverview? overview;
  final SmsLedgerSyncProgress? syncProgress;
  final SmsLedgerSyncResult? lastSyncResult;
  final String? errorMessage;

  bool get hasPermission => permissionState.isGranted;

  bool get hasEntries => entries.isNotEmpty;

  List<SmsLedgerEntryModel> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    return entries.where((entry) {
      if (statusFilter == SmsHistoryStatusFilter.imported && !entry.isImported) {
        return false;
      }
      if (statusFilter == SmsHistoryStatusFilter.notImported &&
          (entry.isImported || entry.isIgnored)) {
        return false;
      }
      if (statusFilter == SmsHistoryStatusFilter.hidden && !entry.isIgnored) {
        return false;
      }
      if (sourceFilter != null && entry.source != sourceFilter) {
        return false;
      }
      if (kindFilter != null && entry.kind != kindFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final fields = [
        entry.displayTitle,
        entry.sender,
        entry.counterparty,
        entry.merchantName,
        entry.reference,
      ];
      for (final value in fields) {
        if ((value ?? '').toLowerCase().contains(query)) {
          return true;
        }
      }
      return false;
    }).toList(growable: false);
  }

  SmsHistoryScreenState copyWith({
    SmsPermissionState? permissionState,
    bool? isLoading,
    bool? isSyncing,
    SmsHistoryTab? activeTab,
    DateTime? selectedMonth,
    SmsHistoryStatusFilter? statusFilter,
    Object? sourceFilter = _smsHistoryUnset,
    Object? kindFilter = _smsHistoryUnset,
    String? searchQuery,
    List<SmsLedgerEntryModel>? entries,
    Object? overview = _smsHistoryUnset,
    Object? syncProgress = _smsHistoryUnset,
    Object? lastSyncResult = _smsHistoryUnset,
    Object? errorMessage = _smsHistoryUnset,
  }) {
    return SmsHistoryScreenState(
      permissionState: permissionState ?? this.permissionState,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      activeTab: activeTab ?? this.activeTab,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      statusFilter: statusFilter ?? this.statusFilter,
      sourceFilter: sourceFilter == _smsHistoryUnset
          ? this.sourceFilter
          : sourceFilter as ParsedTransactionSource?,
      kindFilter: kindFilter == _smsHistoryUnset
          ? this.kindFilter
          : kindFilter as ParsedTransactionKind?,
      searchQuery: searchQuery ?? this.searchQuery,
      entries: entries ?? this.entries,
      overview: overview == _smsHistoryUnset
          ? this.overview
          : overview as SmsLedgerOverview?,
      syncProgress: syncProgress == _smsHistoryUnset
          ? this.syncProgress
          : syncProgress as SmsLedgerSyncProgress?,
      lastSyncResult: lastSyncResult == _smsHistoryUnset
          ? this.lastSyncResult
          : lastSyncResult as SmsLedgerSyncResult?,
      errorMessage: errorMessage == _smsHistoryUnset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _smsHistoryUnset = Object();
