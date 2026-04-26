import 'parsed_transaction.dart';

class SmsLedgerStatusSnapshot {
  const SmsLedgerStatusSnapshot({
    required this.ledgerCount,
    required this.importedCount,
    required this.hiddenCount,
    required this.initialBackfillComplete,
    required this.lastSuccessfulSyncAt,
  });

  final int ledgerCount;
  final int importedCount;
  final int hiddenCount;
  final bool initialBackfillComplete;
  final DateTime? lastSuccessfulSyncAt;
}

class SmsLedgerSyncProgress {
  const SmsLedgerSyncProgress({
    required this.isInitialBackfill,
    required this.batchIndex,
    required this.scannedMessages,
    required this.financialMessages,
    required this.parsedMessages,
    required this.storedEntries,
  });

  final bool isInitialBackfill;
  final int batchIndex;
  final int scannedMessages;
  final int financialMessages;
  final int parsedMessages;
  final int storedEntries;
}

class SmsLedgerSyncResult {
  const SmsLedgerSyncResult({
    required this.isInitialBackfill,
    required this.scannedMessages,
    required this.financialMessages,
    required this.parsedMessages,
    required this.unparsedFinancialMessages,
    required this.insertedEntries,
    required this.updatedEntries,
    required this.batchCount,
    required this.startedAt,
    required this.completedAt,
  });

  final bool isInitialBackfill;
  final int scannedMessages;
  final int financialMessages;
  final int parsedMessages;
  final int unparsedFinancialMessages;
  final int insertedEntries;
  final int updatedEntries;
  final int batchCount;
  final DateTime startedAt;
  final DateTime completedAt;

  int get storedEntries => insertedEntries + updatedEntries;
}

class SmsLedgerKindTotal {
  const SmsLedgerKindTotal({
    required this.kind,
    required this.amount,
    required this.count,
  });

  final ParsedTransactionKind kind;
  final double amount;
  final int count;
}

class SmsLedgerSourceTotal {
  const SmsLedgerSourceTotal({
    required this.source,
    required this.amount,
    required this.count,
  });

  final ParsedTransactionSource source;
  final double amount;
  final int count;
}

class SmsLedgerMonthlyTrendPoint {
  const SmsLedgerMonthlyTrendPoint({
    required this.month,
    required this.activityTotal,
    required this.outflow,
    required this.inflow,
    required this.transfer,
    required this.count,
  });

  final DateTime month;
  final double activityTotal;
  final double outflow;
  final double inflow;
  final double transfer;
  final int count;
}

class SmsLedgerOverview {
  const SmsLedgerOverview({
    required this.selectedMonth,
    required this.totalEntries,
    required this.visibleEntries,
    required this.importedEntries,
    required this.hiddenEntries,
    required this.monthlyActivityTotal,
    required this.monthlyOutflow,
    required this.monthlyInflow,
    required this.monthlyTransfer,
    required this.allTimeActivityTotal,
    required this.kindTotals,
    required this.sourceTotals,
    required this.trendPoints,
    required this.lastSuccessfulSyncAt,
    required this.initialBackfillComplete,
  });

  final DateTime selectedMonth;
  final int totalEntries;
  final int visibleEntries;
  final int importedEntries;
  final int hiddenEntries;
  final double monthlyActivityTotal;
  final double monthlyOutflow;
  final double monthlyInflow;
  final double monthlyTransfer;
  final double allTimeActivityTotal;
  final List<SmsLedgerKindTotal> kindTotals;
  final List<SmsLedgerSourceTotal> sourceTotals;
  final List<SmsLedgerMonthlyTrendPoint> trendPoints;
  final DateTime? lastSuccessfulSyncAt;
  final bool initialBackfillComplete;
}
