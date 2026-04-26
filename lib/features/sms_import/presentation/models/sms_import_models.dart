import '../../../../core/ai/bangla_date_parser.dart';
import '../../../../core/ai/expense_result.dart';
import '../../../../core/sms/sms_import_entry.dart';
import '../../../../core/sms/parsed_transaction.dart';
import '../../../../core/sms/sms_import_result.dart';
import '../../../income/domain/entities/income_entity.dart';
import '../../domain/entities/sms_permission_state.dart';

class SmsImportStatus {
  const SmsImportStatus({
    required this.permissionState,
    required this.importedCount,
    required this.lastImportDate,
    required this.ledgerCount,
    required this.lastLedgerSyncAt,
    required this.initialLedgerSyncComplete,
  });

  final SmsPermissionState permissionState;
  final int importedCount;
  final DateTime? lastImportDate;
  final int ledgerCount;
  final DateTime? lastLedgerSyncAt;
  final bool initialLedgerSyncComplete;

  bool get isPermissionGranted => permissionState.isGranted;
}

class SmsAutoImportState {
  const SmsAutoImportState({
    required this.permissionState,
    required this.isEnabled,
    required this.isListening,
    required this.autoConfirm,
    required this.importedCount,
    required this.pendingTransactions,
    required this.enabledSources,
    required this.isBusy,
    required this.isRescanning,
    this.lastScanTime,
    this.errorMessage,
  });

  factory SmsAutoImportState.initial() {
    return const SmsAutoImportState(
      permissionState: SmsPermissionState.denied,
      isEnabled: false,
      isListening: false,
      autoConfirm: false,
      importedCount: 0,
      pendingTransactions: [],
      enabledSources: [],
      isBusy: false,
      isRescanning: false,
    );
  }

  final SmsPermissionState permissionState;
  final bool isEnabled;
  final bool isListening;
  final bool autoConfirm;
  final int importedCount;
  final DateTime? lastScanTime;
  final List<SmsImportEntry> pendingTransactions;
  final List<String> enabledSources;
  final bool isBusy;
  final bool isRescanning;
  final String? errorMessage;

  bool get hasPending => pendingTransactions.isNotEmpty;

  SmsAutoImportState copyWith({
    SmsPermissionState? permissionState,
    bool? isEnabled,
    bool? isListening,
    bool? autoConfirm,
    int? importedCount,
    Object? lastScanTime = _smsImportUnset,
    List<SmsImportEntry>? pendingTransactions,
    List<String>? enabledSources,
    bool? isBusy,
    bool? isRescanning,
    Object? errorMessage = _smsImportUnset,
  }) {
    return SmsAutoImportState(
      permissionState: permissionState ?? this.permissionState,
      isEnabled: isEnabled ?? this.isEnabled,
      isListening: isListening ?? this.isListening,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      importedCount: importedCount ?? this.importedCount,
      lastScanTime: lastScanTime == _smsImportUnset
          ? this.lastScanTime
          : lastScanTime as DateTime?,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      enabledSources: enabledSources ?? this.enabledSources,
      isBusy: isBusy ?? this.isBusy,
      isRescanning: isRescanning ?? this.isRescanning,
      errorMessage: errorMessage == _smsImportUnset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

enum SmsImportTabFilter { all, expense, income }

class SmsImportDraft {
  const SmsImportDraft({
    required this.candidateId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.walletId,
    this.category,
    this.incomeSource,
  });

  final int candidateId;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final int? walletId;
  final String? category;
  final String? incomeSource;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  factory SmsImportDraft.fromCandidate(SmsImportCandidate candidate) {
    final transaction = candidate.transaction;
    final description = _defaultDescription(candidate);
    return SmsImportDraft(
      candidateId: candidate.sms.id,
      type: transaction.type,
      amount: transaction.amount,
      description: description,
      date: transaction.occurredAt,
      walletId: candidate.suggestedWallet?.id,
      category: candidate.suggestedCategory,
      incomeSource: candidate.suggestedIncomeSource,
    );
  }

  SmsImportDraft copyWith({
    double? amount,
    String? description,
    DateTime? date,
    int? walletId,
    bool clearWallet = false,
    String? category,
    String? incomeSource,
  }) {
    return SmsImportDraft(
      candidateId: candidateId,
      type: type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      walletId: clearWallet ? null : walletId ?? this.walletId,
      category: category ?? this.category,
      incomeSource: incomeSource ?? this.incomeSource,
    );
  }

  ExpenseData toExpenseData() {
    return ExpenseData(
      amount: amount,
      category: (category == null || category!.trim().isEmpty)
          ? 'Other'
          : category!.trim(),
      description: description.trim().isEmpty ? 'SMS খরচ' : description.trim(),
      date: BanglaDateParser.formatIsoDate(date),
    );
  }

  IncomeEntity toIncomeEntity() {
    return IncomeEntity(
      amount: amount,
      source: (incomeSource == null || incomeSource!.trim().isEmpty)
          ? 'Other'
          : incomeSource!.trim(),
      description: description.trim().isEmpty ? 'SMS আয়' : description.trim(),
      date: date,
      walletId: walletId,
      createdAt: DateTime.now(),
    );
  }

  static String _defaultDescription(SmsImportCandidate candidate) {
    final transaction = candidate.transaction;
    final preferred = transaction.counterparty?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }

    final merchant = transaction.merchantName?.trim();
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }

    final fallback = transaction.rawCategory?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return transaction.type == TransactionType.income
        ? '${transaction.sourceLabel} জমা'
        : '${transaction.sourceLabel} খরচ';
  }
}

class SmsImportBatchOutcome {
  const SmsImportBatchOutcome({
    required this.importedCount,
    required this.failedCount,
    required this.skippedCount,
  });

  final int importedCount;
  final int failedCount;
  final int skippedCount;

  bool get hasSuccess => importedCount > 0;
  bool get hasFailures => failedCount > 0;
}

class SmsImportScreenState {
  const SmsImportScreenState({
    required this.permissionState,
    required this.importedCount,
    required this.lastImportDate,
    required this.isStatusLoading,
    required this.lastScanReadyCount,
    required this.scanAttempted,
    required this.isScanning,
    required this.isImporting,
    required this.latestScanResult,
    required this.candidates,
    required this.drafts,
    required this.selectedIds,
    required this.rowErrors,
    required this.activeTab,
    this.errorMessage,
  });

  factory SmsImportScreenState.initial() {
    return const SmsImportScreenState(
      permissionState: SmsPermissionState.denied,
      importedCount: 0,
      lastImportDate: null,
      isStatusLoading: true,
      lastScanReadyCount: 0,
      scanAttempted: false,
      isScanning: false,
      isImporting: false,
      latestScanResult: null,
      candidates: [],
      drafts: {},
      selectedIds: {},
      rowErrors: {},
      activeTab: SmsImportTabFilter.all,
    );
  }

  final SmsPermissionState permissionState;
  final int importedCount;
  final DateTime? lastImportDate;
  final bool isStatusLoading;
  final int lastScanReadyCount;
  final bool scanAttempted;
  final bool isScanning;
  final bool isImporting;
  final SmsImportResult? latestScanResult;
  final List<SmsImportCandidate> candidates;
  final Map<int, SmsImportDraft> drafts;
  final Set<int> selectedIds;
  final Map<int, String> rowErrors;
  final SmsImportTabFilter activeTab;
  final String? errorMessage;

  bool get hasCandidates => candidates.isNotEmpty;
  bool get hasPermission => permissionState.isGranted;
  int get selectedCount => selectedIds.length;

  List<SmsImportCandidate> get filteredCandidates {
    return switch (activeTab) {
      SmsImportTabFilter.all => candidates,
      SmsImportTabFilter.expense =>
        candidates
            .where((candidate) => candidate.isExpense)
            .toList(growable: false),
      SmsImportTabFilter.income =>
        candidates
            .where((candidate) => candidate.isIncome)
            .toList(growable: false),
    };
  }

  SmsImportScreenState copyWith({
    SmsPermissionState? permissionState,
    int? importedCount,
    Object? lastImportDate = _smsImportUnset,
    bool? isStatusLoading,
    int? lastScanReadyCount,
    bool? scanAttempted,
    bool? isScanning,
    bool? isImporting,
    Object? latestScanResult = _smsImportUnset,
    List<SmsImportCandidate>? candidates,
    Map<int, SmsImportDraft>? drafts,
    Set<int>? selectedIds,
    Map<int, String>? rowErrors,
    SmsImportTabFilter? activeTab,
    Object? errorMessage = _smsImportUnset,
  }) {
    return SmsImportScreenState(
      permissionState: permissionState ?? this.permissionState,
      importedCount: importedCount ?? this.importedCount,
      lastImportDate: lastImportDate == _smsImportUnset
          ? this.lastImportDate
          : lastImportDate as DateTime?,
      isStatusLoading: isStatusLoading ?? this.isStatusLoading,
      lastScanReadyCount: lastScanReadyCount ?? this.lastScanReadyCount,
      scanAttempted: scanAttempted ?? this.scanAttempted,
      isScanning: isScanning ?? this.isScanning,
      isImporting: isImporting ?? this.isImporting,
      latestScanResult: latestScanResult == _smsImportUnset
          ? this.latestScanResult
          : latestScanResult as SmsImportResult?,
      candidates: candidates ?? this.candidates,
      drafts: drafts ?? this.drafts,
      selectedIds: selectedIds ?? this.selectedIds,
      rowErrors: rowErrors ?? this.rowErrors,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage == _smsImportUnset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _smsImportUnset = Object();
