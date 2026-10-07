import '../../features/wallet/domain/entities/wallet_entity.dart';
import 'parsed_transaction.dart';
import 'sms_message.dart';

class SmsImportCandidate {
  const SmsImportCandidate({
    required this.sms,
    required this.transaction,
    required this.suggestedWallet,
    this.suggestedCategory,
    this.suggestedIncomeSource,
    this.signature,
  });

  final SmsMessage sms;

  /// The ledger signature of this message when it is already known (a candidate
  /// rebuilt from a stored row, whose text was not kept). Null for one built from
  /// a live SMS, which is hashed from its text.
  final String? signature;
  final ParsedTransaction transaction;
  final WalletEntity? suggestedWallet;
  final String? suggestedCategory;
  final String? suggestedIncomeSource;

  bool get isExpense => transaction.type == TransactionType.expense;

  bool get isIncome => transaction.type == TransactionType.income;
}

class SmsImportResult {
  const SmsImportResult({
    required this.since,
    required this.scannedMessages,
    required this.financialMessages,
    required this.parsedTransactions,
    required this.candidates,
    required this.duplicateCount,
  });

  final DateTime since;
  final List<SmsMessage> scannedMessages;
  final List<SmsMessage> financialMessages;
  final List<ParsedTransaction> parsedTransactions;
  final List<SmsImportCandidate> candidates;
  final int duplicateCount;

  int get scannedCount => scannedMessages.length;

  int get financialCount => financialMessages.length;

  int get parsedCount => parsedTransactions.length;

  int get newCount => candidates.length;

  bool get hasNewTransactions => candidates.isNotEmpty;
}
