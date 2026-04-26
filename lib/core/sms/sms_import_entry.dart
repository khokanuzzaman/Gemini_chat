import '../../features/wallet/domain/entities/wallet_entity.dart';
import 'parsed_transaction.dart';
import 'sms_import_result.dart';
import 'sms_message.dart';

class SmsImportEntry {
  const SmsImportEntry({
    required this.signature,
    required this.sms,
    required this.transaction,
    required this.detectedAt,
    this.suggestedWallet,
    this.suggestedCategory,
    this.suggestedIncomeSource,
  });

  final String signature;
  final SmsMessage sms;
  final ParsedTransaction transaction;
  final DateTime detectedAt;
  final WalletEntity? suggestedWallet;
  final String? suggestedCategory;
  final String? suggestedIncomeSource;

  bool get isExpense => transaction.type == TransactionType.expense;

  bool get isIncome => transaction.type == TransactionType.income;

  String get mappedLabel {
    if (isIncome) {
      return (suggestedIncomeSource == null || suggestedIncomeSource!.isEmpty)
          ? 'Other'
          : suggestedIncomeSource!;
    }
    return (suggestedCategory == null || suggestedCategory!.isEmpty)
        ? 'Other'
        : suggestedCategory!;
  }

  SmsImportCandidate toCandidate() {
    return SmsImportCandidate(
      sms: sms,
      transaction: transaction,
      suggestedWallet: suggestedWallet,
      suggestedCategory: suggestedCategory,
      suggestedIncomeSource: suggestedIncomeSource,
    );
  }
}
