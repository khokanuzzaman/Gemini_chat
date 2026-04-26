import 'package:isar_community/isar.dart';

import '../database/models/imported_sms_model.dart';
import '../database/models/sms_ledger_entry_model.dart';
import '../database/models/sms_ledger_sync_state_model.dart';
import '../../features/wallet/domain/entities/wallet_entity.dart';
import 'parsed_transaction.dart';
import 'sms_category_mapper.dart';
import 'sms_filter.dart';
import 'sms_import_result.dart';
import 'sms_ledger_models.dart';
import 'sms_message.dart';
import 'sms_parser.dart';
import 'sms_reader_service.dart';
import 'sms_signature_codec.dart';
import 'sms_wallet_matcher.dart';

class SmsLedgerService {
  SmsLedgerService({
    required Isar isar,
    required SmsReaderService reader,
    required SmsFilter filter,
    required SmsParserEngine parser,
    required SmsCategoryMapper categoryMapper,
    required SmsWalletMatcher walletMatcher,
    SmsSignatureCodec? signatureCodec,
  }) : _isar = isar,
       _reader = reader,
       _filter = filter,
       _parser = parser,
       _categoryMapper = categoryMapper,
       _walletMatcher = walletMatcher,
       _signatureCodec = signatureCodec ?? const SmsSignatureCodec();

  final Isar _isar;
  final SmsReaderService _reader;
  final SmsFilter _filter;
  final SmsParserEngine _parser;
  final SmsCategoryMapper _categoryMapper;
  final SmsWalletMatcher _walletMatcher;
  final SmsSignatureCodec _signatureCodec;

  Future<SmsLedgerStatusSnapshot> getStatusSnapshot() async {
    final syncState = await _loadSyncState();
    final entries = await _isar.smsLedgerEntryModels.where().findAll();
    final importedCount = entries.where((entry) => entry.isImported).length;
    final hiddenCount = entries.where((entry) => entry.isIgnored).length;
    return SmsLedgerStatusSnapshot(
      ledgerCount: entries.length,
      importedCount: importedCount,
      hiddenCount: hiddenCount,
      initialBackfillComplete: syncState.initialBackfillComplete,
      lastSuccessfulSyncAt: syncState.lastSuccessfulSyncAt,
    );
  }

  Future<SmsLedgerSyncResult> syncLedger({
    int pageSize = 500,
    void Function(SmsLedgerSyncProgress progress)? onProgress,
  }) async {
    final safePageSize = pageSize.clamp(50, 500);
    final syncState = await _loadSyncState();
    final isInitialBackfill = !syncState.initialBackfillComplete;
    final startedAt = DateTime.now();

    final existingEntries = {
      for (final entry in await _isar.smsLedgerEntryModels.where().findAll())
        entry.signature: entry,
    };
    final importedBySignature = {
      for (final entry in await _isar.importedSmsModels.where().findAll())
        entry.signature: entry,
    };

    DateTime? since = isInitialBackfill ? null : syncState.lastSyncedSmsDate;
    DateTime? before;
    int? beforeMessageId;
    DateTime? newestSeenDate = syncState.lastSyncedSmsDate;
    int? newestSeenId = syncState.lastSyncedSmsId;

    var batchIndex = 0;
    var scannedMessages = 0;
    var financialMessages = 0;
    var parsedMessages = 0;
    var insertedEntries = 0;
    var updatedEntries = 0;

    while (true) {
      final page = await _reader.readSmsPage(
        maxCount: safePageSize,
        since: since,
        before: before,
        beforeMessageId: beforeMessageId,
      );
      if (page.isEmpty) {
        break;
      }

      batchIndex++;
      scannedMessages += page.length;
      final newestInPage = page.first;
      if (_isNewerCursor(newestInPage, newestSeenDate, newestSeenId)) {
        newestSeenDate = newestInPage.date;
        newestSeenId = newestInPage.id;
      }

      final financialPage = _filter.filterFinancialSms(page);
      financialMessages += financialPage.length;
      final parsedPage = _parser.parseAll(financialPage);
      parsedMessages += parsedPage.length;

      final pageModels = <SmsLedgerEntryModel>[];
      final messagesById = {
        for (final message in financialPage) message.id: message,
      };
      final now = DateTime.now();

      for (final transaction in parsedPage) {
        final sms = messagesById[transaction.smsId];
        if (sms == null) {
          continue;
        }

        final signature = _signatureCodec.generateSignature(sms);
        final existing = existingEntries[signature];
        final importedRecord = importedBySignature[signature];
        final entry = existing ?? SmsLedgerEntryModel();
        final wasExisting = existing != null;

        entry.signature = signature;
        entry.smsId = sms.id;
        entry.sender = sms.address;
        entry.rawMessage = sms.body;
        entry.source = transaction.source;
        entry.direction = transaction.direction;
        entry.kind = transaction.kind;
        entry.type = transaction.type;
        entry.amount = transaction.amount;
        entry.fee = transaction.fee;
        entry.balanceAfter = transaction.balanceAfter;
        entry.reference = transaction.reference;
        entry.counterparty = transaction.counterparty;
        entry.merchantName = transaction.merchantName;
        entry.accountMask = transaction.accountMask;
        entry.rawCategory = transaction.rawCategory;
        entry.confidence = transaction.confidence;
        entry.occurredAt = transaction.occurredAt;
        entry.receivedAt = sms.date;
        entry.isImported = existing?.isImported == true || importedRecord != null;
        entry.importedAt = existing?.importedAt ?? importedRecord?.importedAt;
        entry.isIgnored = existing?.isIgnored ?? false;
        entry.ignoredAt = existing?.ignoredAt;
        entry.createdAt = existing?.createdAt ?? now;
        entry.updatedAt = now;

        pageModels.add(entry);
        existingEntries[signature] = entry;
        if (wasExisting) {
          updatedEntries++;
        } else {
          insertedEntries++;
        }
      }

      if (pageModels.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.smsLedgerEntryModels.putAll(pageModels);
        });
      }

      onProgress?.call(
        SmsLedgerSyncProgress(
          isInitialBackfill: isInitialBackfill,
          batchIndex: batchIndex,
          scannedMessages: scannedMessages,
          financialMessages: financialMessages,
          parsedMessages: parsedMessages,
          storedEntries: insertedEntries + updatedEntries,
        ),
      );

      if (page.length < safePageSize) {
        break;
      }
      final oldestInPage = page.last;
      before = oldestInPage.date;
      beforeMessageId = oldestInPage.id;
    }

    final completedAt = DateTime.now();
    final updatedState = syncState
      ..initialBackfillComplete = true
      ..lastSuccessfulSyncAt = completedAt
      ..lastSyncedSmsDate = newestSeenDate ?? syncState.lastSyncedSmsDate
      ..lastSyncedSmsId = newestSeenId ?? syncState.lastSyncedSmsId
      ..createdAt = syncState.createdAt
      ..updatedAt = completedAt;

    await _isar.writeTxn(() async {
      await _isar.smsLedgerSyncStateModels.put(updatedState);
    });

    return SmsLedgerSyncResult(
      isInitialBackfill: isInitialBackfill,
      scannedMessages: scannedMessages,
      financialMessages: financialMessages,
      parsedMessages: parsedMessages,
      unparsedFinancialMessages: financialMessages - parsedMessages,
      insertedEntries: insertedEntries,
      updatedEntries: updatedEntries,
      batchCount: batchIndex,
      startedAt: startedAt,
      completedAt: completedAt,
    );
  }

  Future<List<SmsLedgerEntryModel>> loadEntries() async {
    final entries = await _isar.smsLedgerEntryModels.where().findAll();
    entries.sort((first, second) {
      final dateComparison = second.occurredAt.compareTo(first.occurredAt);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return second.smsId.compareTo(first.smsId);
    });
    return entries;
  }

  Future<SmsLedgerOverview> buildOverview(DateTime month) async {
    final normalizedMonth = DateTime(month.year, month.month);
    final allEntries = await loadEntries();
    final visibleEntries = [
      for (final entry in allEntries)
        if (!entry.isIgnored) entry,
    ];
    final monthEntries = [
      for (final entry in visibleEntries)
        if (_isSameMonth(entry.occurredAt, normalizedMonth)) entry,
    ];

    final monthlyOutflow = _sumForKinds(monthEntries, _outflowKinds);
    final monthlyInflow = _sumForKinds(monthEntries, _inflowKinds);
    final monthlyTransfer = _sumForKinds(monthEntries, _transferKinds);
    final monthlyActivityTotal =
        monthlyOutflow + monthlyInflow + monthlyTransfer;
    final allTimeActivityTotal = visibleEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    final kindTotals = _buildKindTotals(monthEntries);
    final sourceTotals = _buildSourceTotals(monthEntries);
    final trendPoints = _buildTrendPoints(
      visibleEntries,
      endingMonth: normalizedMonth,
      monthCount: 6,
    );
    final syncState = await _loadSyncState();

    return SmsLedgerOverview(
      selectedMonth: normalizedMonth,
      totalEntries: allEntries.length,
      visibleEntries: visibleEntries.length,
      importedEntries: visibleEntries.where((entry) => entry.isImported).length,
      hiddenEntries: allEntries.where((entry) => entry.isIgnored).length,
      monthlyActivityTotal: monthlyActivityTotal,
      monthlyOutflow: monthlyOutflow,
      monthlyInflow: monthlyInflow,
      monthlyTransfer: monthlyTransfer,
      allTimeActivityTotal: allTimeActivityTotal,
      kindTotals: kindTotals,
      sourceTotals: sourceTotals,
      trendPoints: trendPoints,
      lastSuccessfulSyncAt: syncState.lastSuccessfulSyncAt,
      initialBackfillComplete: syncState.initialBackfillComplete,
    );
  }

  Future<void> setIgnored(int entryId, bool ignored) async {
    final entry = await _isar.smsLedgerEntryModels.get(entryId);
    if (entry == null) {
      return;
    }
    entry.isIgnored = ignored;
    entry.ignoredAt = ignored ? DateTime.now() : null;
    entry.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.smsLedgerEntryModels.put(entry);
    });
  }

  Future<void> markImportedBySignature(
    String signature, {
    DateTime? importedAt,
  }) async {
    final entry = await _isar.smsLedgerEntryModels
        .filter()
        .signatureEqualTo(signature)
        .findFirst();
    if (entry == null) {
      return;
    }
    entry.isImported = true;
    entry.importedAt = importedAt ?? DateTime.now();
    entry.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.smsLedgerEntryModels.put(entry);
    });
  }

  Future<void> upsertCandidate(
    SmsImportCandidate candidate, {
    bool isImported = false,
    DateTime? importedAt,
  }) async {
    final signature = _signatureCodec.generateSignature(candidate.sms);
    final existing = await _isar.smsLedgerEntryModels
        .filter()
        .signatureEqualTo(signature)
        .findFirst();
    final now = DateTime.now();
    final entry = existing ?? SmsLedgerEntryModel();
    final transaction = candidate.transaction;

    entry.signature = signature;
    entry.smsId = candidate.sms.id;
    entry.sender = candidate.sms.address;
    entry.rawMessage = candidate.sms.body;
    entry.source = transaction.source;
    entry.direction = transaction.direction;
    entry.kind = transaction.kind;
    entry.type = transaction.type;
    entry.amount = transaction.amount;
    entry.fee = transaction.fee;
    entry.balanceAfter = transaction.balanceAfter;
    entry.reference = transaction.reference;
    entry.counterparty = transaction.counterparty;
    entry.merchantName = transaction.merchantName;
    entry.accountMask = transaction.accountMask;
    entry.rawCategory = transaction.rawCategory;
    entry.confidence = transaction.confidence;
    entry.occurredAt = transaction.occurredAt;
    entry.receivedAt = candidate.sms.date;
    entry.isImported = existing?.isImported == true || isImported;
    entry.importedAt = existing?.importedAt ?? (isImported ? importedAt ?? now : null);
    entry.isIgnored = existing?.isIgnored ?? false;
    entry.ignoredAt = existing?.ignoredAt;
    entry.createdAt = existing?.createdAt ?? now;
    entry.updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.smsLedgerEntryModels.put(entry);
    });
  }

  SmsImportCandidate buildImportCandidate(
    SmsLedgerEntryModel entry,
    List<WalletEntity> wallets, {
    WalletEntity? defaultWallet,
  }) {
    final transaction = entry.toParsedTransaction();
    return SmsImportCandidate(
      sms: entry.toSmsMessage(),
      transaction: transaction,
      suggestedWallet: _walletMatcher.matchWallet(
        transaction,
        wallets,
        defaultWallet: defaultWallet,
      ),
      suggestedCategory: entry.isExpenseLike
          ? _categoryMapper.mapToExpenseCategory(transaction)
          : null,
      suggestedIncomeSource: entry.isIncomeLike
          ? _categoryMapper.mapToIncomeSource(transaction)
          : null,
    );
  }

  Future<SmsLedgerSyncStateModel> _loadSyncState() async {
    final existing = await _isar.smsLedgerSyncStateModels.get(1);
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now();
    final state = SmsLedgerSyncStateModel()
      ..id = 1
      ..createdAt = now
      ..updatedAt = now;
    await _isar.writeTxn(() async {
      await _isar.smsLedgerSyncStateModels.put(state);
    });
    return state;
  }

  bool _isNewerCursor(
    SmsMessage candidate,
    DateTime? existingDate,
    int? existingId,
  ) {
    if (existingDate == null) {
      return true;
    }
    if (candidate.date.isAfter(existingDate)) {
      return true;
    }
    if (!candidate.date.isAtSameMomentAs(existingDate)) {
      return false;
    }
    return candidate.id > (existingId ?? -1);
  }

  bool _isSameMonth(DateTime date, DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  double _sumForKinds(
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
    final totals = buckets.values.toList(growable: false);
    totals.sort((first, second) => second.amount.compareTo(first.amount));
    return totals;
  }

  List<SmsLedgerSourceTotal> _buildSourceTotals(List<SmsLedgerEntryModel> entries) {
    final buckets = <ParsedTransactionSource, SmsLedgerSourceTotal>{};
    for (final entry in entries) {
      final current = buckets[entry.source];
      buckets[entry.source] = SmsLedgerSourceTotal(
        source: entry.source,
        amount: (current?.amount ?? 0) + entry.amount,
        count: (current?.count ?? 0) + 1,
      );
    }
    final totals = buckets.values.toList(growable: false);
    totals.sort((first, second) => second.amount.compareTo(first.amount));
    return totals;
  }

  List<SmsLedgerMonthlyTrendPoint> _buildTrendPoints(
    List<SmsLedgerEntryModel> entries, {
    required DateTime endingMonth,
    required int monthCount,
  }) {
    final months = <DateTime>[
      for (var offset = monthCount - 1; offset >= 0; offset--)
        DateTime(endingMonth.year, endingMonth.month - offset),
    ];

    return [
      for (final month in months)
        SmsLedgerMonthlyTrendPoint(
          month: month,
          activityTotal: _monthTotal(entries, month),
          outflow: _monthKindTotal(entries, month, _outflowKinds),
          inflow: _monthKindTotal(entries, month, _inflowKinds),
          transfer: _monthKindTotal(entries, month, _transferKinds),
          count: entries.where((entry) => _isSameMonth(entry.occurredAt, month)).length,
        ),
    ];
  }

  double _monthTotal(List<SmsLedgerEntryModel> entries, DateTime month) {
    return entries.fold<double>(
      0,
      (sum, entry) => sum + (_isSameMonth(entry.occurredAt, month) ? entry.amount : 0),
    );
  }

  double _monthKindTotal(
    List<SmsLedgerEntryModel> entries,
    DateTime month,
    Set<ParsedTransactionKind> kinds,
  ) {
    return entries.fold<double>(
      0,
      (sum, entry) => sum + (_isSameMonth(entry.occurredAt, month) && kinds.contains(entry.kind) ? entry.amount : 0),
    );
  }
}

const Set<ParsedTransactionKind> _outflowKinds = {
  ParsedTransactionKind.payment,
  ParsedTransactionKind.sendMoney,
  ParsedTransactionKind.cashOut,
  ParsedTransactionKind.bankDebit,
  ParsedTransactionKind.billPay,
  ParsedTransactionKind.atmWithdrawal,
  ParsedTransactionKind.cardPurchase,
};

const Set<ParsedTransactionKind> _inflowKinds = {
  ParsedTransactionKind.receivedMoney,
  ParsedTransactionKind.bankCredit,
};

const Set<ParsedTransactionKind> _transferKinds = {
  ParsedTransactionKind.cashIn,
  ParsedTransactionKind.addMoney,
  ParsedTransactionKind.transfer,
};
